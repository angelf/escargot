require 'will_paginate/collection'

module Escargot
  module ActiveRecordExtensions

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      attr_accessor :index_name
      attr_accessor :update_index_policy

      # defines an elastic search index. Valid options:
      #
      # :index_name (will default class name using method "underscore")
      #
      # :updates, how to to update the contents of the index when a document is changed, valid options are:
      #
      #   - false: do not update the index
      #
      #   - :immediate: update the index but do not refresh it automatically.
      #     With the default settings, this means that the change may take up to 1 second
      #     to be seen by other users.
      #
      #     See: http://www.elasticsearch.com/docs/elasticsearch/index_modules/engine/robin/
      #
      #     This is the default option.
      #
      #   - :immediate_with_refresh: update the index AND ask elasticsearch to refresh it after each
      #     change. This garantuees that the changes will be seen by other users, but may affect
      #     performance.
      #
      #   - :enqueu: enqueue the document id so that a remote worker will update the index
      #     This is the recommended options if you have set up a job queue (such as Resque)
      #

      def elastic_index(options = {})
        Escargot.register_model(self)

        options.symbolize_keys!
        send :include, InstanceMethods
        @index_name = options[:index_name] || self.name.underscore.gsub(/\//,'-')
        @update_index_policy = options.include?(:updates) ? options[:updates] : :immediate
        
        if @update_index_policy
          after_save :update_index
          after_destroy :delete_from_index
        end
        @index_options = options[:index_options] || {}
        @mapping = options[:mapping] || false
      end

      # search_hits returns a raw ElasticSearch::Api::Hits object for the search results
      # see #search for the valid options
      def search_hits(query, options = {})
        if query.kind_of?(Hash)
          query = {:query => query}
        end
        $elastic_search_client.search(query, options.merge({:index => self.index_name, :type => elastic_search_type}))
      end

      # search returns a will_paginate collection of ActiveRecord objects for the search results
      #
      # see ElasticSearch::Api::Index#search for the full list of valid options
      #
      # note that the collection may include nils if ElasticSearch returns a result hit for a
      # record that has been deleted on the database
      def search(query, options = {})
        hits = search_hits(query, options)
        hits_ar = hits.map{|hit| hit.to_activerecord}
        results = WillPaginate::Collection.new(hits.current_page, hits.per_page, hits.total_entries)
        results.replace(hits_ar)
        results
      end

      # counts the number of results for this query.
      def search_count(query = "*", options = {})
        if query.kind_of?(Hash)
          query = {:query => query}
        end
        $elastic_search_client.count(query, options.merge({:index => self.index_name, :type => elastic_search_type}))
      end

      def facets(fields_list, options = {})
        size = options.delete(:size) || 10
        fields_list = [fields_list] unless fields_list.kind_of?(Array)
        
        if !options[:query]
          options[:query] = {:match_all => true}
        elsif options[:query].kind_of?(String)
          options[:query] = {:query_string => {:query => options[:query]}}
        end

        options[:facets] = {}
        fields_list.each do |field|
          options[:facets][field] = {:terms => {:field => field, :size => size}}
        end

        hits = $elastic_search_client.search(options)
        out = {}
        
        fields_list.each do |field|
          out[field.to_sym] = {}
          hits.facets[field.to_s]["terms"].each do |term|
            out[field.to_sym][term["term"]] = term["count"]
          end
        end

        out
      end

      # explicitly refresh the index, making all operations performed since the last refresh
      # available for search
      #
      # http://www.elasticsearch.com/docs/elasticsearch/rest_api/admin/indices/refresh/
      def refresh_index(index_version = nil)
        $elastic_search_client.refresh(index_version || index_name)
      end
      
      # creates a new index version for this model and sets the mapping options for the type
      def create_index_version
        index_version = $elastic_search_client.create_index_version(@index_name, @index_options)
        if @mapping
          $elastic_search_client.update_mapping(@mapping, :index => index_version, :type => elastic_search_type)
        end
        index_version
      end
      
      # deletes all index versions for this model
      def delete_index
        # deletes any index version
        $elastic_search_client.index_versions(index_name).each{|index_version|
          $elastic_search_client.delete_index(index_version)
        }
        
        # and delete the index itself if it exists
        begin
          $elastic_search_client.delete_index(index_name)
        rescue ElasticSearch::RequestError
          # it's ok, this means that the index doesn't exist
        end
      end
      
      def delete_id_from_index(id, options = {})
        options[:index] ||= self.index_name
        options[:type]  ||= elastic_search_type
        $elastic_search_client.delete(id.to_s, options)
      end
      
      def optimize_index
        $elastic_search_client.optimize(index_name)
      end
      
      private
        def elastic_search_type
          self.name.underscore.singularize.gsub(/\//,'-')
        end

    end

    module InstanceMethods

      # updates the index using the appropiate policy
      def update_index
        if self.class.update_index_policy == :immediate_with_refresh
          local_index_in_elastic_search(:refresh => true)
        elsif self.class.update_index_policy == :enqueue
          Resque.enqueue(DistributedIndexing::ReIndexDocuments, self.class.to_s, [self.id])
        else
          local_index_in_elastic_search
        end
      end

      # deletes the document from the index using the appropiate policy ("simple" or "distributed")
      def delete_from_index
        if self.class.update_index_policy == :immediate_with_refresh
          self.class.delete_id_from_index(self.id, :refresh => true)
          # As of Oct 25 2010, :refresh => true is not working
          self.class.refresh_index()
        elsif self.class.update_index_policy == :enqueue
          Resque.enqueue(DistributedIndexing::ReIndexDocuments, self.class.to_s, [self.id])
        else
          self.class.delete_id_from_index(self.id)
        end
      end

      def local_index_in_elastic_search(options = {})
        options[:index] ||= self.class.index_name
        options[:type]  ||= self.class.name.underscore.singularize
        options[:id]    ||= self.id.to_s
        
        $elastic_search_client.index(
          self.respond_to?(:indexed_json_document) ? self.indexed_json_document : self.to_json,
          options
        )
        
        ## !!!!! passing :refresh => true should make ES auto-refresh only the affected
        ## shards but as of Oct 25 2010 with ES 0.12 && rubberband 0.0.2 that's not the case
        if options[:refresh]
          self.class.refresh_index(options[:index])
        end
          
      end

    end
  end
end