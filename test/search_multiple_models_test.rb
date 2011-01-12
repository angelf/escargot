require 'test_helper'
# tests the behaviour of Searching multiple models

class SearchMultipleModels < Test::Unit::TestCase

  load_schema
  flush_indexes_models
  
  class User < ActiveRecord::Base
    elastic_index
  end
  
  class LegacyUser < ActiveRecord::Base
    set_primary_key :legacy_id
    elastic_index
  end

  class RenewUser < ActiveRecord::Base
    set_primary_key :renew_id
    elastic_index
  end

  def setup
    User.delete_all
    User.delete_index
    LegacyUser.delete_all
    LegacyUser.delete_index
    RenewUser.delete_all
    RenewUser.delete_index

    User.new(:name => 'Cote').save!
    User.new(:name => 'Grillo').save!
    User.new(:name => 'Mencho').save!

    LegacyUser.new(:name => 'Cote').save!
    LegacyUser.new(:name => 'Cote').save!
    LegacyUser.new(:name => 'Grillo').save!

    RenewUser.new(:name => 'Cote').save!
    RenewUser.new(:name => 'Cote').save!
    RenewUser.new(:name => 'Mencho').save!
    
    User.refresh_index
    LegacyUser.refresh_index
    RenewUser.refresh_index

  end


  def teardown
    User.delete_all
    User.delete_index
    LegacyUser.delete_all
    LegacyUser.delete_index
    RenewUser.delete_all
    RenewUser.delete_index
    Escargot.flush_all_indexed_models
  end
  
  
  def test_search_multiple_models
    # Search "Cote" in all Models
    assert_equal Escargot.search("Cote").total_entries, 5

    # Search "Cote" in model User
    assert_equal Escargot.search("Cote", :classes =>[User]).total_entries, 1

    # Search "Cote" in model User, if it's only one model you don't need pass like array
    assert_equal Escargot.search("Cote", :classes => User).total_entries, 1

    # Search "Cote" in model LegacyUser
    assert_equal Escargot.search("Cote", :classes =>[LegacyUser]).total_entries, 2

    # Search "Cote" in model User, LegacyUser
    assert_equal Escargot.search("Cote", :classes =>[User,LegacyUser]).total_entries, 3
  end
end
