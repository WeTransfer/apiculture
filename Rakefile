# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require_relative 'lib/apiculture/version'
require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "apiculture"
  gem.version = Apiculture::VERSION
  gem.homepage = "https://github.com/WeTransfer/apiculture"
  gem.license = "MIT"
  gem.description = %Q{A toolkit for building REST APIs on top of Sinatra}
  gem.summary = %Q{Sweet API sauce on top of Sintra}
  gem.email = "me@julik.nl"
  gem.authors = ["Julik Tarkhanov", "WeTransfer"]
  # dependencies defined in Gemfile
end
# Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "apiculture #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
