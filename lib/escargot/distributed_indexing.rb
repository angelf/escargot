require 'resque'

module Escargot

  module DistributedIndexing
    def DistributedIndexing.create_index_for_model(model)
      index_version = model.create_index_version

      model.find_in_batches(:select => "id") do |batch|
        batch.each
        Escargot.queue_backend.enqueue(IndexDocuments, model.to_s, batch.map(&:id), index_version)
      end

      Escargot.queue_backend.enqueue(DeployNewVersion, model.index_name, index_version)
    end

    class IndexDocuments
      @queue = :indexing
        
      def self.perform(model, ids, index_version)
        model.constantize.find(:all, :conditions => {:id => ids}).each do |record|
          record.local_index_in_elastic_search(:index => index_version)
        end
      end
    end

    class DeployNewVersion
      @queue = :indexing
      def self.perform(index, index_version)
        $elastic_search_client.deploy_index_version(index, index_version)
      end
    end
  end
  
end