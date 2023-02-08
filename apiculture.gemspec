# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'apiculture/version'

Gem::Specification.new do |s|
  s.name = 'apiculture'
  s.version = Apiculture::VERSION

  s.require_paths = ['lib']
  s.authors = ['Julik Tarkhanov', 'WeTransfer']
  s.description = 'A toolkit for building REST APIs on top of Rack'
  s.email = 'me@julik.nl'

  # Prevent pushing this gem to RubyGems.org.
  # To allow pushes either set the 'allowed_push_host'
  # To allow pushing to a single host or delete this section to allow pushing to any host.
  if s.respond_to?(:metadata)
    s.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  s.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^spec/}) }
  s.extra_rdoc_files = [
    'LICENSE.txt',
    'README.md'
  ]
  s.homepage = 'https://github.com/WeTransfer/apiculture'
  s.licenses = ['MIT']
  s.rubygems_version = '2.4.5.1'
  s.summary = 'Sweet API sauce on top of Rack'

  s.add_runtime_dependency 'builder', '~> 3'
  s.add_runtime_dependency 'github-markup', '~> 3'
  s.add_runtime_dependency 'mustache', '~> 1'
  s.add_runtime_dependency 'mustermann', '~> 3'
  s.add_runtime_dependency 'rdiscount', '~> 2'

  s.add_development_dependency 'bundler', '~> 2.0'
  s.add_development_dependency 'cgi'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc', '~> 6.0'
  s.add_development_dependency 'rspec', '~> 3'
end
