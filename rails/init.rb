require 'escargot'

ActiveRecord::Base.class_eval do
  include Escargot::ActiveRecordExtensions
end if defined?(ActiveRecord::Base)

ElasticSearch::Api::Hit.class_eval do
  include Escargot::HitExtensions
end

ElasticSearch::Client.class_eval do
  include Escargot::AdminIndexVersions
end

unless File.exists?(Rails.root + "/config/elasticsearch.yml")
  Rails.logger.warn "No config/elastic_search.yaml file found, connecting to localhost:9200"
  $elastic_search_client = ElasticSearch.new("localhost:9200")
else
  config = YAML.load_file(Rails.root + "/config/elasticsearch.yml")
  $elastic_search_client = ElasticSearch.new(config["host"] + ":" + config["port"].to_s, :timeout => 20)
end