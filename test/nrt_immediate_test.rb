# tests the Near Real Time support in the :updates => true mode

require 'test_helper'

class NrtImmediate < Test::Unit::TestCase
  load_schema
  resque_available
  
  class User < ActiveRecord::Base
    elastic_index
  end
  
  def setup
    User.delete_all
    User.delete_index
    Escargot::LocalIndexing.create_index_for_model(User)
    
    @tim = User.create(:name => 'Tim the Wise')
    User.create(:name => 'Peter the Young')
    User.create(:name => 'Peter the Old')
    User.create(:name => 'Bob the Skinny')
    User.create(:name => 'Jamie the Flying Machine')    
  end
  
  def test_document_creation
    User.refresh_index
    assert_equal 5, User.search_count    
    results = User.search("wise")
    assert_equal results.total_entries, 1
    assert_equal results.first.name, 'Tim the Wise'
  end
  
  def test_document_updates
    # make a change in a document
    @tim.name = 'Tim the Reborn'
    @tim.save!
    User.refresh_index

    assert_equal User.search_count("wise"), 0
    assert_equal User.search_count("reborn"), 1
  end
  
  def test_document_deletes
    User.refresh_index
    assert_equal 5, User.search_count

    @tim.destroy
    User.refresh_index

    assert_equal 4, User.search_count
  end
end