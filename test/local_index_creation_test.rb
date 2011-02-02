require 'test_helper'

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
    sleep(1)
  end
  
  def test_indexing_rotation
    # create a first version of the index
    User.delete_all
    User.create(:name => 'John the Long')
    User.create(:name => 'Peter the Fat')
    User.create(:name => 'Bob the Skinny')
    User.create(:name => 'Jamie the Flying Machine')
  
    Escargot::LocalIndexing.create_index_for_model(User)
    
    # create a second version of the index
    
    User.find(:first).destroy
    User.find(:first).destroy
    
    Escargot::LocalIndexing.create_index_for_model(User)
    
    # check that there are no trace of the older index
    
    results = User.search("*")
    assert_equal results.total_entries, 2
  end
  
  def teardown
    User.delete_all
    User.delete_index
  end
  
end
