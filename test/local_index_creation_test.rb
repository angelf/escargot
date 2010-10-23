require 'test_helper'
require File.dirname(__FILE__) + '/test_helper.rb'

# tests the behaviour of the index creation tasks that run locally (in the "simple" mode)
# without real time support

class LocalIndexCreation < Test::Unit::TestCase
  load_schema
  
  class User < ActiveRecord::Base
    elastic_index :updates => false
  end

  def test_fast_index_creation
    User.delete_all
    User.delete_index
    
    10.times do
      Escargot::LocalIndexing.create_index_for_model(User)
    end
  end
  
  def test_facets
     User.delete_all
     User.delete_index

     puts "creating data"
     User.new(:name => 'John the Long').save!
     User.new(:name => 'John the Skinny').save!
     
     Escargot::LocalIndexing.create_index_for_model(User)
     User.refresh_index
     
     facets = User.facets([:name], :query => "LONG or SKINNY")
     assert_equal facets[:name]["john"], 2
   end

  def test_local_indexing
    puts 'INDEXING'
    
    User.delete_all
    User.delete_index
    
    puts "creating data"
    User.new(:name => 'John the Long').save!
    User.new(:name => 'Peter the Young').save!
    User.new(:name => 'Peter the Old').save!
    User.new(:name => 'Bob the Skinny').save!
    User.new(:name => 'John the Skinny Too').save!    
    User.new(:name => 'Jamie the Flying Machine').save!
    
    assert_raise ElasticSearch::Transport::HTTP::RequestError do 
      User.search_count
    end
    
    Escargot::LocalIndexing.create_index_for_model(User)
    User.refresh_index
    
    User.new(:name => 'Peter the Hidden Man').save!
    User.refresh_index
      
    results = User.search("peter")
    assert_equal results.total_entries, 2
    
    assert_equal [results.first.name, results.second.name].sort, ['Peter the Old', 'Peter the Young']
    
    results = User.search("LONG or SKINNY")
    assert_equal results.total_entries, 3
    assert_equal User.search_count("LONG or SKINNY"), 3
    
    results = User.search("*")
    assert_equal results.total_entries, 6
    
    User.optimize_index
    facets = User.facets([:name], :query => "LONG or SKINNY")
    assert_equal facets[:name]["john"], 2
  end
  
  def test_local_indexing_rotation
    puts 'indexing'
    # create a first version of the index
    User.delete_all
    User.new(:name => 'John the Long').save!
    User.new(:name => 'Peter the Fat').save!
    User.new(:name => 'Bob the Skinny').save!
    User.new(:name => 'Jamie the Flying Machine').save!
  
    Escargot::LocalIndexing.create_index_for_model(User)
    
    # create a second version of the index
    
    User.find(:first).destroy
    User.find(:first).destroy
    
    Escargot::LocalIndexing.create_index_for_model(User)
    User.refresh_index
    
    # check that there are no trace of the older index
    
    results = User.search("*")
    assert_equal results.total_entries, 2
  end  
end