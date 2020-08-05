#  ActiveRecord looks for this object
module Rails
  extend self

  def root
    File.dirname(File.expand_path('..', __FILE__))
  end

  def logger
    @logger ||= Logger.new $stdout
  end
  
  def env
    ENV.fetch("ENV") || "development"
  end
  
end


# Set up environment
require 'sinatra'
require "sinatra/base"
require "sinatra/cookies"
require "sinatra/activerecord"


require 'twitter'
require 'twitter-text'
require 'omniauth-twitter'
require 'link_thumbnailer'

require "uri"
require 'curb'

require 'securerandom'

require 'logger'
require 'pg'

require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/web'

Dir["./models/*.rb", "./lib/**/*.rb"].each do |file| 
  require file
end


if settings.development?
  require 'sinatra/reloader' 
  require "byebug" 
  require "awesome_print" 
end