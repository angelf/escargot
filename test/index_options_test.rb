# coding: utf-8
require 'test_helper'

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
    User.delete_all
    User.delete_index
    
    User.create(:name => "Pedrín el Joven")
    User.create(:name => 'Pedro el Viejo')
    User.create(:name => 'Roberto el Delgado')
    User.create(:name => 'Jamie la Máquina Voladora')

    Escargot::LocalIndexing.create_index_for_model(User)
    
    results = User.search("pedrin")
    assert_equal results.total_entries, 1
  end
end