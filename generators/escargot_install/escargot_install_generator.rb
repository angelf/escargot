# rails 2 generator
 class EscargotInstallGenerator < Rails::Generator::Base

  def manifest
    record do |m|
      m.template 'config/elasticsearch.yml', 'config/elasticsearch.yml'
    end
  end  
  
 end 

