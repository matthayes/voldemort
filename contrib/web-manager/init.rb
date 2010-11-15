# Require the necessary libraries.
require 'rubygems'
require 'sinatra'

gem 'emk-sinatra-url-for'
require 'sinatra/url_for'

# add controllers and views
configure do
  set :views, File.expand_path("../app/views", __FILE__)
end

# Load the controllers.
Dir[File.expand_path("../app/controllers/*.rb", __FILE__)].each { |file| load file }