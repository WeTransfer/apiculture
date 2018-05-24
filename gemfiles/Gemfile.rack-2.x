source "http://rubygems.org"
gem 'rack', "~> 2"

gem 'mustermann', '~> 1'
gem 'builder', '~> 3'
gem 'rdiscount', '~> 2'
gem 'github-markup', '~> 1'
gem 'mustache', '~> 1'

group :development do
  gem 'rack-test'
  gem "rspec", "~> 3.1", '< 3.2'
  gem "rdoc", "~> 6.0"
  gem "rake", "~> 10"
  gem "bundler", "~> 1.0"
  gem "simplecov", ">= 0"
end
