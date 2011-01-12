# Escargot
require 'elasticsearch'
require 'escargot/activerecord_ex'
require 'escargot/elasticsearch_ex'
require 'escargot/local_indexing'
require 'escargot/distributed_indexing'
require 'escargot/queue_backend/base'
require 'escargot/queue_backend/resque'

module Escargot
  def self.register_model(model)
    return unless model.table_exists?
    @indexed_models ||= []
    @indexed_models.delete(model) if @indexed_models.include?(model)
    @indexed_models << model
  end

  def self.indexed_models
    @indexed_models || []
  end

  def self.queue_backend
    @queue ||= Escargot::QueueBackend::Rescue.new
  end
  
  def self.flush_all_indexed_models
    @indexed_models = []
  end

  # Functionality to perform searching in multiple models
  def self.search(query, options = {})
    if (options[:classes])
      models = Array(options[:classes])
    else
      register_all_models
      models = @indexed_models
    end
    $elastic_search_client.search(query, options.merge({:index => models.map(&:index_name).join(',')}))
  end


  private
    def self.register_all_models
      models = []
      # Search all Models in the application Rails
      Dir[File.join("#{RAILS_ROOT}/app/models".split(/\\/), "**", "*.rb")].each do |file|
        model = file.gsub(/#{RAILS_ROOT}\/app\/models\/(.*?)\.rb/,'\1').classify.constantize
        unless models.include?(model)
          require file
        end
        models << model
      end
    end

end
