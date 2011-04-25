module Escargot
 class InstallGenerator < Rails::Generators::NamedBase

  source_root File.expand_path('../templates', __FILE__)
  
  argument :name, :required => false, :type => :string, :default => "elasticsearch.yml"  
  
  def copy_config_file
	template 'config/elasticsearch.yml' 
    #copy_file 'config/elasticsearch.yml', "config/elasticsearch.yml"  
  end  
  
 end
end 

