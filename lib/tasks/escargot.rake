# desc "Explaining what the task does"
# task :elastic_rails do
#   # Task goes here
# end

namespace :escargot do
  desc "indexes the models"
  task :index, :models, :needs => [:environment, :load_all_models] do |t, args|
    each_indexed_model(args) do |model|
      puts "Indexing #{model}"
      Escargot::LocalIndexing.create_index_for_model(model)
    end
  end

  desc "indexes the models"
  task :distributed_index, :models, :needs => [:environment, :load_all_models] do |t, args|
    each_indexed_model(args) do |model|
      puts "Indexing #{model}"
      Escargot::DistributedIndexing.create_index_for_model(model)
    end
  end
  
  desc "indexes the models LIVE LIKE BOSS"
  task :pre_alias_distributed_index, :models, :needs => [:environment, :load_all_models] do |t, args|
    each_indexed_model(args) do |model|
      puts "Indexing #{model}"
      index_version = model.create_index_version
      $elastic_search_client.deploy_index_version(index, index_version)
      Escargot::PreAliasDistributedIndexing.create_index_for_model(model)
    end
  end
  
  
  
  desc "prunes old index versions for this models"
  task :prune_versions, :models, :needs => [:environment, :load_all_models] do |t, args|
    each_indexed_model(args) do |model|
      $elastic_search_client.prune_index_versions(model.index_name)
    end
  end
  
  task :load_all_models do
    models = ActiveRecord::Base.send(:subclasses)
    Dir["#{Rails.root}/app/models/*.rb", "#{Rails.root}/app/models/*/*.rb"].each do |file|
      model = File.basename(file, ".*").classify
      unless models.include?(model)
        require file
      end
      models << model 
    end
  end
  
  private
    def each_indexed_model(args)
      if args[:models]
        models = args[:models].split(",").map{|m| m.classify.constantize}
      else
        models = Escargot.indexed_models
      end
      models.each{|m| yield m}
    end
end
