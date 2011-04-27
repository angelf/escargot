# rails 2 generator
 class EscargotInstallGenerator < Rails::Generator::Base

  def manifest
    record do |m|
      m.template 'config/escargot.yml', 'config/escargot.yml'
    end
  end  
  
 end 

