module Escargot
 class InstallGenerator < Rails::Generators::NamedBase

  source_root File.expand_path('../templates', __FILE__)
  
  argument :name, :required => false, :type => :string, :default => "escargot.yml"  
  
  def copy_config_file
	template 'config/escargot.yml' 
  end  
  
 end
end 

