# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'restfully/version'
 
Gem::Specification.new do |s|
  s.name                      = "restfully"
  s.version                   = Restfully::VERSION
  s.platform                  = Gem::Platform::RUBY
  s.required_ruby_version     = '>= 2.3'
  s.required_rubygems_version = ">= 1.3"
  s.authors                   = ["Cyril Rohr"]
  s.email                     = ["cyril.rohr@gmail.com"]
  s.executables               = ["restfully"]
  s.homepage                  = "http://github.com/crohr/restfully"
  s.summary                   = "Consume RESTful APIs effortlessly"
  s.description               = "Consume RESTful APIs effortlessly"
  
  s.add_dependency('json')
  s.add_dependency('rest-client')
  s.add_dependency('rest-client-components')
  s.add_dependency('rack-cache')
  s.add_dependency('rack')
  s.add_dependency('activesupport')
  s.add_dependency('addressable')
  s.add_dependency('mime-types') 
  s.add_dependency('public_suffix')
  s.add_dependency('ripl')
  s.add_dependency('ripl-multi_line')
  s.add_dependency('ripl-color_streams')
  s.add_dependency('ripl-short_errors')
  s.add_dependency('ripl-play')
  s.add_dependency('rb-readline')
  s.add_development_dependency('rake')
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
