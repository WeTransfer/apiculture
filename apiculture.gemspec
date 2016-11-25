# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: apiculture 0.0.18 ruby lib

Gem::Specification.new do |s|
  s.name = "apiculture"
  s.version = "0.0.18"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Julik Tarkhanov", "WeTransfer"]
  s.date = "2016-11-25"
  s.description = "A toolkit for building REST APIs on top of Sinatra"
  s.email = "me@julik.nl"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".travis.yml",
    "Gemfile",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "apiculture.gemspec",
    "lib/apiculture.rb",
    "lib/apiculture/action.rb",
    "lib/apiculture/action_definition.rb",
    "lib/apiculture/app_documentation.rb",
    "lib/apiculture/app_documentation_tpl.mustache",
    "lib/apiculture/markdown_segment.rb",
    "lib/apiculture/method_documentation.rb",
    "lib/apiculture/sinatra_instance_methods.rb",
    "lib/apiculture/timestamp_promise.rb",
    "lib/apiculture/version.rb",
    "spec/apiculture/action_spec.rb",
    "spec/apiculture/app_documentation_spec.rb",
    "spec/apiculture/method_documentation_spec.rb",
    "spec/apiculture_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "https://github.com/WeTransfer/apiculture"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.5.1"
  s.summary = "Sweet API sauce on top of Sintra"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sinatra>, ["~> 1.4"])
      s.add_runtime_dependency(%q<builder>, ["~> 3"])
      s.add_runtime_dependency(%q<rdiscount>, ["~> 2.1"])
      s.add_runtime_dependency(%q<github-markup>, ["~> 1"])
      s.add_runtime_dependency(%q<mustache>, ["~> 1"])
      s.add_development_dependency(%q<rack-test>, ["~> 0.6"])
      s.add_development_dependency(%q<rspec>, ["< 3.2", "~> 3.1"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 2"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
    else
      s.add_dependency(%q<sinatra>, ["~> 1.4"])
      s.add_dependency(%q<builder>, ["~> 3"])
      s.add_dependency(%q<rdiscount>, ["~> 2.1"])
      s.add_dependency(%q<github-markup>, ["~> 1"])
      s.add_dependency(%q<mustache>, ["~> 1"])
      s.add_dependency(%q<rack-test>, ["~> 0.6"])
      s.add_dependency(%q<rspec>, ["< 3.2", "~> 3.1"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<jeweler>, ["~> 2"])
      s.add_dependency(%q<simplecov>, [">= 0"])
    end
  else
    s.add_dependency(%q<sinatra>, ["~> 1.4"])
    s.add_dependency(%q<builder>, ["~> 3"])
    s.add_dependency(%q<rdiscount>, ["~> 2.1"])
    s.add_dependency(%q<github-markup>, ["~> 1"])
    s.add_dependency(%q<mustache>, ["~> 1"])
    s.add_dependency(%q<rack-test>, ["~> 0.6"])
    s.add_dependency(%q<rspec>, ["< 3.2", "~> 3.1"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<jeweler>, ["~> 2"])
    s.add_dependency(%q<simplecov>, [">= 0"])
  end
end

