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
  
  def test_asciifolding_option  
    puts 'indexing'
    
    User.delete_all
    User.delete_index
    Escargot::LocalIndexing.create_index_for_model(User)
    
    User.new(:name => 'Pedrín el Joven').save!
    User.new(:name => 'Pedro el Viejo').save!
    User.new(:name => 'Roberto el Delgado').save!
    User.new(:name => 'Jamie la Máquina Voladora').save!

    User.refresh_index
    
    assert_equal User.search_count('name:pedro'), 0
    assert_equal User.search_count('name:"Pedro el Viejo"'), 1
  end
end