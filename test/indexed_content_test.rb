# tests the Near Real Time support 

require 'test_helper'

# tests the behaviour of the index creation tasks that run locally (in the "simple" mode)

class IndexedContentTest < Test::Unit::TestCase
  load_schema
  
  class User < ActiveRecord::Base
    elastic_index
    
    def indexed_json_document
      to_json(:only => :name, :methods => :foo)
    end
    
    def foo
      "FOO!"
    end
  end

  def test_indexed_content
    User.delete_index
    User.delete_all
    
    User.create(:name => 'Tim the Wise')
    User.create(:name => 'Peter the Young')
    User.create(:name => 'Peter the Old')    
    User.refresh_index
    
    assert_equal User.search_count("Peter AND foo:FOO"), 2
  end
  
end