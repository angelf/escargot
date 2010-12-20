require 'test_helper'

class AdminIndexTest < Test::Unit::TestCase
  load_schema

  class ::User < ActiveRecord::Base
    elastic_index
  end

  def test_prune_index
    @local_index = ''
    index = User.index_name
    3.times.each do
      Escargot::LocalIndexing.create_index_for_model(User)
      @local_index = $elastic_search_client.current_index_version(index)
    end
    assert $elastic_search_client.index_versions(index).size > 1
    assert $elastic_search_client.index_versions(index).include? $elastic_search_client.current_index_version(index)
    $elastic_search_client.prune_index_versions(index)
    assert $elastic_search_client.index_versions(index).size == 1
  end
end
