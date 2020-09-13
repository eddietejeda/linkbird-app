# Set up environment
require 'sinatra'
require "sinatra/base"
require "sinatra/cookies"
require "sinatra/activerecord"


require 'twitter'
require 'twitter-text'
require 'omniauth-twitter'
require 'link_thumbnailer'
require 'pagy'
require 'pagy/extras/bulma'

require "uri"
require 'curb'

require 'securerandom'

require 'logger'
require 'pg'

require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/web'

if settings.development?
  require 'sidekiq/testing' 
  # Sidekiq::Testing.fake! # fake is the default mode
  Sidekiq::Testing.inline!
end

require 'stripe'
Stripe.api_key = ENV['STRIPE_SECRET_KEY']


Dir["./models/*.rb", "./lib/**/*.rb"].each do |file| 
  require file
end

logger = Logger.new(STDOUT)

if settings.development?
  require 'sinatra/reloader' 
  require "byebug" 
  require "awesome_print" 
  logger.level = Logger::INFO
end


logger.level = Logger::INFO