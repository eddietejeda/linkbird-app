# https://www.imaginarycloud.com/blog/from-capybara-webkit-to-headless-chrome-and-chromedriver/
require File.dirname(__FILE__) + '/spec_helper'

require 'capybara'
require 'capybara/rspec'
require 'selenium/webdriver'
require 'database_cleaner/active_record'


RSpec.configure do |config|
  config.include Capybara::DSL
  config.include Capybara::RSpecMatchers
  config.include FactoryBot::Syntax::Methods
  config.include RSpecMixin

  # Use color in STDOUT
  config.color = true

  # Use the specified formatter
  config.formatter = :documentation


  config.before(:suite) do
    FactoryBot.find_definitions
  end
  
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  
  
  
  # Chrome headless driver
  Capybara.register_driver :headless_chrome do |app|
    caps = Selenium::WebDriver::Remote::Capabilities.chrome(loggingPrefs: { browser: 'ALL' })
    opts = Selenium::WebDriver::Chrome::Options.new

    chrome_args = %w[--headless --no-sandbox --disable-gpu --window-size=1920,1080 --remote-debugging-port=9222]
    chrome_args.each { |arg| opts.add_argument(arg) }
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: opts, desired_capabilities: caps)
  end


  Capybara.default_driver = :headless_chrome
  Capybara.javascript_driver = :headless_chrome

  Capybara.app = App
end