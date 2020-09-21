require File.dirname(__FILE__) + '/spec_helper'

require 'capybara'
require 'capybara/rspec'
require 'capybara/apparition'

Capybara.default_driver = :apparition
Capybara.javascript_driver = :apparition
Capybara.app = App


RSpec.configure do |config|
  config.include Capybara::DSL
  config.include Capybara::RSpecMatchers
end