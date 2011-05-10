require 'test_helper'
#require File.dirname(__FILE__) + '/test_helper.rb'

# tests the behaviour of the index creation tasks that run locally (in the "simple" mode)
# without real time support

class BasicSearchTest < Test::Unit::TestCase
  load_schema
  
  class ::User < ActiveRecord::Base
    elastic_index :updates => false, :mapping => {
        :properties => {
          :country_code => {:type => "string", :index => "not_analyzed"}
        }
    }
    
  end

  def setup
    User.delete_all
    User.delete_index
    
    User.create(:name => 'John the Long', :country_code => 'ca')
    User.create(:name => 'Peter the Young', :created_at => Date.today, :country_code => 'uk')
    User.create(:name => 'Peter the Old', :created_at => Date.today - 1, :country_code => 'us')
    User.create(:name => 'Bob the Skinny', :country_code => 'ca')
    User.create(:name => 'John the Skinny Too', :country_code => 'it')
    User.create(:name => 'Jamie the Amazing Flying Machine', :country_code => 'es')
    
    Escargot::LocalIndexing.create_index_for_model(User)
  end

  def teardown
    User.delete_all
    User.delete_index
  end

  def test_search_count
    results = User.search("peter")
    assert_equal results.total_entries, 2
    assert_equal User.search_count("peter"), 2
  end

  def test_search_count_with_query
    results = User.search(:term => {:name => "john"})
    assert_equal results.total_entries, 2
    assert_equal User.search_count(:term => {:name => "john"}), 2
  end
  
  def test_search_without_query_dsl
    # By default in Escargot any query Hash is a Query DSL, so anything you put in the first param is wrapper with
    # this "query = {:query => {query}}", but sometimes if you need puts some params OUT Query DSL you can do this
    # putting in the query Hash the option ":query_dsl => false", of course remember to put the term ":query => {your query}"
    # to work correctly

    results = User.search({:sort =>[{ :country_code => {:reverse => true }}] , :query => {:term => {:name => "john"}}, :track_scores =>true}, :query_dsl => false)
    assert_equal results.first.name, 'John the Skinny Too'
  end
  

  def test_facets
    assert_equal User.facets(:country_code)[:country_code]["ca"], 2
    facets = User.facets([:name, :country_code], :query => "LONG or SKINNY", :size => 100)
    assert_equal facets[:name]["john"], 2
    assert_equal facets[:country_code]["it"], 1
  end

  def test_facets_size
    assert_equal User.facets(:name)[:name].keys.size, 10
    assert_equal User.facets(:name, :size => 1000)[:name].keys.size, 12
  end

  def test_search
    results = User.search("peter")
    assert_equal [results.first.name, results.second.name].sort, ['Peter the Old', 'Peter the Young']
  end
  
  def test_wildcard
    results = User.search("*")
    assert_equal results.total_entries, 6
  end
  
  def test_paging
    results = User.search("*", :per_page => 3, :page => 2)
    assert_equal 6, results.total_entries
    assert_equal 2, results.current_page
    assert_equal 3, results.per_page
  end
  
  def test_sort
    assert_equal User.search("peter", :sort => 'created_at').first.name, "Peter the Old"
    assert_equal User.search("peter", :sort => 'created_at:desc').first.name, "Peter the Young"
  end
  
end