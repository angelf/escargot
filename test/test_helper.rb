require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_support/test_case'

ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'

require 'test/unit'
require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config/environment.rb'))

# we define globally the model here so that User.find() will find the class existing
class User < ActiveRecord::Base
end

class LegacyUser < ActiveRecord::Base
  set_primary_key :legacy_id
end

def load_schema
  config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
  ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")

  db_adapter = ENV['DB']

  # no db passed, try one of these fine config-free DBs before bombing.
  db_adapter ||=
    begin
      require 'rubygems'
      require 'sqlite'
      'sqlite'
    rescue MissingSourceFile
      begin
        require 'sqlite3'
        'sqlite3'
      rescue MissingSourceFile
      end
    end

  if db_adapter.nil?
    raise "No DB Adapter selected. Pass the DB= option to pick one, or install Sqlite or Sqlite3."
  end

  ActiveRecord::Base.establish_connection(config[db_adapter])
  load(File.dirname(__FILE__) + "/schema.rb")
  require File.dirname(__FILE__) + '/../rails/init.rb'
end

def resque_available
  begin
    require 'resque'
    require 'resque_unit'
    Resque.reset!
    return true
  rescue NameError, MissingSourceFile
    puts "Please install the 'resque' and 'resque_unit' gems to test the distributed mode."
    exit
  end
end
