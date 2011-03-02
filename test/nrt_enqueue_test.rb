# tests the Near Real Time support in the :updates => true mode
require 'test_helper'

class NrtEnqueue < Test::Unit::TestCase
  load_schema
  resque_available

  class User < ActiveRecord::Base
    elastic_index :updates => :enqueue
  end

  def setup
    User.delete_all
    Escargot::LocalIndexing.create_index_for_model(User)
    
    @tim = User.create(:name => 'Tim the Wise')
    User.create(:name => 'Peter the Young')
    User.create(:name => 'Peter the Old')
    User.create(:name => 'Bob the Skinny')
    User.create(:name => 'Jamie the Flying Machine')

    # the Resque tasks have not run yet, so there should be nothing in the index
    # but now run the Resque tasks and check that the index is good for each test
    Resque.run!
  end
  
  def teardown
    User.delete_all
    User.delete_index
  end
  
  def test_document_creation
    User.refresh_index

    assert_equal 5, User.search("*").total_entries
    results = User.search("wise")
    assert_equal results.total_entries, 1
    assert_equal results.first.name, 'Tim the Wise'
  end
  
  def test_document_updates
    User.refresh_index
    
    assert_equal 5, User.search("*").total_entries

    # make a change in a document
    @tim.name = 'Tim the Reborn'
    @tim.save!
    User.refresh_index

    # check that it's not in the index yet
    assert_equal User.search_count("wise"), 1
    assert_equal User.search_count("reborn"), 0
    
    # but when we run the Resque tasks, all is well
    Resque.run!
    User.refresh_index

    assert_equal User.search_count("wise"), 0
    assert_equal User.search_count("reborn"), 1
  end
  
  def test_document_deletes
    User.refresh_index

    assert_equal User.search("*").total_entries, 5

    # Destroy the element
    @tim.destroy
    User.refresh_index
    
    # but still there until run Resque
    assert_equal User.search("*").total_entries, 5

    # but when we run the Resque tasks, all is well
    Resque.run!
    User.refresh_index
    assert_equal User.search("*").total_entries, 4
  end

  def test_changes_are_updated_in_all_versions

  end
end