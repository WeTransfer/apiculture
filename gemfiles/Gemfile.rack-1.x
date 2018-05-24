source "http://rubygems.org"
gem 'rack', "~> 1"

group :development do
  gem 'rack-test'
  gem "rspec", "~> 3.1", '< 3.2'
  gem "rdoc", "~> 6.0"
  gem "rake", "~> 10"
  gem "bundler", "~> 1.0"
  gem "simplecov", ">= 0"
end
