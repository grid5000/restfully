# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'restfully/version'
 
Gem::Specification.new do |s|
  s.name                      = "restfully"
  s.version                   = Restfully::VERSION
  s.platform                  = Gem::Platform::RUBY
  s.required_ruby_version     = '>= 1.8'
  s.required_rubygems_version = ">= 1.3"
  s.authors                   = ["Cyril Rohr"]
  s.email                     = ["cyril.rohr@gmail.com"]
  s.executables               = ["restfully"]
  s.homepage                  = "http://github.com/crohr/restfully"
  s.summary                   = "Consume RESTful APIs effortlessly"
  s.description               = "Consume RESTful APIs effortlessly"
  
  s.add_dependency('json', '~> 1.5')
  s.add_dependency('rest-client', '~> 1.6')
  s.add_dependency('rest-client-components')
  s.add_dependency('rack-cache')
  s.add_dependency('backports')
  s.add_dependency('addressable')
  
  s.add_development_dependency('rake', '~> 0.8')
  s.add_development_dependency('rspec', '~> 2')
  s.add_development_dependency('webmock')
  s.add_development_dependency('autotest')
  s.add_development_dependency('autotest-growl')
  
 
  s.files = Dir.glob("{bin,lib,spec,example}/**/*") + %w(Rakefile LICENSE README.md)
  
  s.test_files = Dir.glob("spec/**/*")
  
  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  
  s.require_path = 'lib'
end
