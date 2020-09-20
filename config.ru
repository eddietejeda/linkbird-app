require 'sass/plugin/rack'
Sass::Plugin.options[:style] = :compressed
use Sass::Plugin::Rack
          
require "./bootup"

if settings.production?
  run App
else
  run Rack::URLMap.new('/' => App, '/sidekiq' => Sidekiq::Web)  
end


