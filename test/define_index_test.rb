require 'test_helper'

require File.dirname(__FILE__) + '/test_helper.rb'

class ElasticIndexTest < Test::Unit::TestCase
  
  class User < ActiveRecord::Base
    elastic_index
  end

  def test_index_name
    assert_equal User.index_name, 'users'
  end
  
  def test_search_method_present
    assert User.respond_to?(:search)
  end
  
  def test_registered_as_indexed_model
    Escargot.indexed_models.include?(User)
  end
  
end