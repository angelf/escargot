
# tests the Near Real Time support 

require 'test_helper'
require File.dirname(__FILE__) + '/test_helper.rb'

# tests the behaviour of the index creation tasks that run locally (in the "simple" mode)

class NearRealTimeTest < Test::Unit::TestCase
  load_schema
  
  class User < ActiveRecord::Base
    elastic_index
  end

  def test_realtime_indexing
    puts 'indexing'
    
    User.delete_index
    User.delete_all
    
    tim = User.new(:name => 'Tim the Wise')
    tim.save!
    
    User.new(:name => 'Peter the Young').save!
    User.new(:name => 'Peter the Old').save!
    User.new(:name => 'Bob the Skinny').save!
    User.new(:name => 'Jamie the Flying Machine').save!
    
    User.refresh_index
    
    results = User.search("tim")
    assert_equal results.total_entries, 1
    assert_equal results.first.name, 'Tim the Wise'

    tim.name = 'Tim the Reborn'
    tim.save!
    User.refresh_index

    results = User.search("tim")
    assert_equal results.total_entries, 1
    assert_equal results.first.name, 'Tim the Reborn'
    
    tim.destroy
    User.refresh_index
    
    results = User.search("tim")
    assert_equal results.total_entries, 0
    
  end
  
end