# rails 2 generator
module Escargot 
 class InstallGenerator < Rails::Generators::NamedBase

  def manifest
    record do |m|
      m.template 'config/elasticsearch.yml', 'config/elasticsearch.yml'
    end
  end  
  
 end 
end

