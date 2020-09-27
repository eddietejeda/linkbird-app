# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem "sinatra", "~> 2.1"
gem "sinatra-contrib", "~> 2.1"
gem "sinatra-activerecord", "~> 2.0"


gem "twitter", "~> 7.0"
gem "twitter-text", "~> 3.1"
gem "omniauth-twitter", "~> 1.4"

gem "rake", "~> 13.0"
gem "sass", "~> 3.7"
gem "puma", "~> 4.3"
gem "curb", "~> 0.9.10"
gem "link_thumbnailer", github: 'gottfrois/link_thumbnailer', ref: '2ec9026aaaccf638207e6fa480f750bfdc5c9a80'
gem "stripe", "~> 5.25"
gem "pagy", "~> 3.8"

gem 'pg'
gem "sidekiq", "~> 6.1"
gem 'newrelic_rpm'
gem "aws-sdk", "~> 3.0"
gem "aws-sdk-s3", "~> 1.81"
gem "redis-sinatra", "~> 1.4"
gem "user_agent_parser"

group :development, :test do
  gem "byebug", "~> 11.1"
  gem "amazing_print", "~> 1.2"
  gem "rspec"
  gem "capybara", "~> 3.33"  
  gem "selenium-webdriver", "~> 3.142"
  gem "apparition", "~> 0.6.0"
end