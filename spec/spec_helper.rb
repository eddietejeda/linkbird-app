# spec_helper.rb
require 'bundler/setup'
require 'sinatra'
Sinatra::Application.environment = :test
Bundler.require :default, Sinatra::Application.environment

require 'rspec'
require 'rack/test'
require_relative '../bootup.rb'
App.environment = :test
ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  
  def app() 
    App 
  end
end

module SpecTestHelper   
  def login(user)
    user = User.first
    request.session[:uid] = user.uid    
    # request.session[:uid] = user.uid
  end

  def current_user
    User.find(request.session[:uid])
  end
end


