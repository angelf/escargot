require 'escargot'

ActiveRecord::Base.class_eval do
  include Escargot::ActiveRecordExtensions
end

ElasticSearch::Api::Hit.class_eval do
  include Escargot::HitExtensions
end

ElasticSearch::Client.class_eval do
  include Escargot::AdminIndexVersions
end

init_elastic_Search_client