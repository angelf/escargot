require 'test_helper'
require File.dirname(__FILE__) + '/test_helper.rb'

class CustomIndexOptions < Test::Unit::TestCase
  load_schema

  class User < ActiveRecord::Base
    elastic_index(
      :updates => false, 
      :index_options => {
        "analysis.analyzer.default.tokenizer" => 'standard',
        "analysis.analyzer.default.filter" => ["standard", "lowercase", "stop", "asciifolding"]
      }
    )
  end
  
  def test_asciifolding_option  
    puts 'indexing'
    
    User.delete_all
    User.delete_index
    
    User.new(:name => 'Pedrín el Joven').save!
    User.new(:name => 'Pedro el Viejo').save!
    User.new(:name => 'Roberto el Delgado').save!
    User.new(:name => 'Jamie la Máquina Voladora').save!

    Escargot::LocalIndexing.create_index_for_model(User)
    User.refresh_index
    
    results = User.search("pedrin")
    assert_equal results.total_entries, 1
  end
end