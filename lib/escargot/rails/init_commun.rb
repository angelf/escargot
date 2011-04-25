def init_elastic_Search_client
	path_to_elasticsearch_config_file = Rails.root.to_s + "/config/elasticsearch.yml"

	unless File.exists?(path_to_elasticsearch_config_file)
	  Rails.logger.warn "No config/elastic_search.yaml file found, connecting to localhost:9200"
	  $elastic_search_client = ElasticSearch.new("localhost:9200")
	else 
	  config = YAML.load_file(path_to_elasticsearch_config_file)
	  $elastic_search_client = ElasticSearch.new(config["host"] + ":" + config["port"].to_s, :timeout => 20)
	end
end 
