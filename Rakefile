require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "restfully"
    gem.summary = %Q{Experimental code for auto-generation of wrappers on top of RESTful APIs that follow some specific conventions.}
    gem.description = %Q{Experimental code for auto-generation of wrappers on top of RESTful APIs that follow HATEOAS principles and provide OPTIONS methods and/or Allow headers.}
    gem.email = "cyril.rohr@gmail.com"
    gem.homepage = "http://github.com/crohr/restfully"
    gem.authors = ["Cyril Rohr"]
    gem.add_dependency "rest-client", '>= 1.4'
    gem.add_dependency "json", '>= 1.2.0'
    gem.add_dependency "backports"
    gem.add_development_dependency "webmock"
    gem.add_development_dependency "rspec"
    gem.add_development_dependency "json"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end

rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'restfully'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end