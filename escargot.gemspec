# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "escargot/version"

Gem::Specification.new do |s|
  s.name        = "escargot"
  s.version     = Escargot::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Angel Faus"]
  s.email       = ["angel@vlex.com"]
  s.homepage    = "http://github.com/angelf/escargot"
  s.summary     = "ElasticSearch connector for Rails"
  s.description = "Connects any Rails model with ElasticSearch, supports near real time updates, distributed indexing and models that integrate data from many databases."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "escargot"

  s.add_development_dependency "bundler", ">= 1.0.0"
  
  s.add_dependency "rubberband", ">= 0.0.5"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
