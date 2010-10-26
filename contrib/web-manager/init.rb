# Require the necessary libraries.
require 'rubygems'
require 'sinatra'

gem 'emk-sinatra-url-for'
require 'sinatra/url_for'

# add controllers and views
configure do
  root = File.expand_path(File.dirname(__FILE__))
  set :views, File.join(root, 'app', 'views')
end

# Load the controllers.
Dir["app/controllers/*.rb"].each { |file| load file }