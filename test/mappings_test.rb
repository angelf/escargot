require 'test_helper'
require File.dirname(__FILE__) + '/test_helper.rb'

class Mappings < Test::Unit::TestCase
  load_schema

  class User < ActiveRecord::Base
    elastic_index(
      :mapping => {
        :properties => {
          :name => {:type => "string", :index => "not_analyzed"}
        }
      }
    )
  end
  
  def test_not_analyzed_property
    puts 'indexing'
    
    User.delete_all
    User.delete_index
    Escargot::LocalIndexing.create_index_for_model(User)
    
    User.create(:name => 'Pedrín el Joven')
    User.create(:name => 'Pedro el Viejo')
    User.create(:name => 'Roberto el Delgado')
    User.create(:name => 'Jamie la Máquina Voladora')

    User.refresh_index

    assert_equal User.search_count('name=pedro'), 0
    assert_equal User.search_count('name="Pedro el Viejo"'), 1
  end
end