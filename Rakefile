require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "restfully"
    gem.summary = %Q{Experimental code for auto-generation of wrappers on top of RESTful APIs that follow some specific conventions.}
    gem.description = %Q{Experimental code for auto-generation of wrappers on top of RESTful APIs that follow HATEOAS principles and provide OPTIONS methods and/or Allow headers.}
    gem.email = "cyril.rohr@gmail.com"
    gem.homepage = "http://github.com/cryx/restfully"
    gem.authors = ["Cyril Rohr"]
    gem.add_dependency "rest-client"
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

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end
