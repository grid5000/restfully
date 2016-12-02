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
  if RUBY_VERSION < "2.0.0"
    s.add_dependency('rest-client', '< 2.0')
  else
    s.add_dependency('rest-client')
  end
  s.add_dependency('rest-client-components')
  if RUBY_VERSION < "1.9.3"
    s.add_dependency('rack-cache', '~> 1.2.0')
  else
    s.add_dependency('rack-cache')
  end
  s.add_dependency('rack', '~> 1.6') if RUBY_VERSION < "2.2.2"
  s.add_dependency('backports')
  s.add_dependency('addressable')
  if RUBY_VERSION < "1.9.3"
    s.add_dependency('mime-types', '~> 2.6.0') 
    s.add_dependency('public_suffix', '~> 1.3.0') 
  elsif RUBY_VERSION < "2.0"
    s.add_dependency('mime-types') 
    s.add_dependency('public_suffix', '~> 1.4.0') 
  end
  s.add_dependency('ripl', '0.6.1')
  s.add_dependency('ripl-multi_line')
  s.add_dependency('ripl-color_streams')
  s.add_dependency('ripl-short_errors')
  s.add_dependency('ripl-play', '~> 0.2.1')
  s.add_dependency('rb-readline')
  
  s.add_development_dependency('rake', '~> 0.8')
  s.add_development_dependency('rspec', '~> 2')
  if RUBY_VERSION < "1.9.3"
    s.add_development_dependency('webmock', '~> 1.20.4')
  else
    s.add_development_dependency('webmock')
  end
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
