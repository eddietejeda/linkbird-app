require 'sass/plugin/rack'
Sass::Plugin.options[:style] = :compressed
use Sass::Plugin::Rack
          
require "./bootup"

if ENV['NEW_RELIC_LICENSE_KEY']
  require 'newrelic_rpm'
end

if settings.development?
  run Rack::URLMap.new('/' => App, '/sidekiq' => Sidekiq::Web)  
else
  run App
end


