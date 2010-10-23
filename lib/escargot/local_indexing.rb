module Escargot
  
  module LocalIndexing
    def LocalIndexing.create_index_for_model(model)
      model = model.constantize if model.kind_of?(String)

      index_version = model.create_index_version

      model.find_in_batches do |batch|
        batch.each do |record|
          record.local_index_in_elastic_search(:index => index_version)
        end
      end

      $elastic_search_client.deploy_index_version(model.index_name, index_version)
    end
  end  
end
