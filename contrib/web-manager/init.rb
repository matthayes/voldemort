# Require the necessary libraries.
require 'rubygems'
require 'sinatra'
require 'yaml'

# In production Warbler places all JAR files under lib. 
configure :production do
  puts "Loading production JARs"
  Dir["lib/*.jar"].each do |jar| 
    puts "requiring #{jar}"
    require jar 
  end
end

# In development mode we need to pick up JARs from various locations.
configure :development do |c|
  
  # reload when in development so we don't have to stop and start Sinatra
  require 'sinatra/reloader'
  
  puts "Loading development JARs"
  
  libs = []
  
  # Voldemort dependencies...
  libs << "../../lib/*.jar"
  
  # Voldemort JARs...
  libs << "../../dist/*.jar"

  libs.each do |lib|
    Dir[lib].each do |jar| 
      puts "requiring #{jar}"
      require jar 
      
      c.also_reload(jar)
    end
  end
end

@@clusters = if File.exists? 'clusters.yml'
  YAML::load(File.read('clusters.yml'))
end

# add controllers and views
configure do
  set :views, File.expand_path("app/views", File.dirname(__FILE__))
  enable :sessions
end

# Load the controllers.
Dir[File.expand_path("app/controllers/*.rb", File.dirname(__FILE__))].each { |file| load file }

before do
  if session["bootstrap_host"].nil? || session["bootstrap_port"].nil?
    if @@clusters && @@clusters.size > 0
      session["bootstrap_host"] = @@clusters[0]['host'].to_s
      session["bootstrap_port"] = @@clusters[0]['port'].to_s
    else
      session["bootstrap_host"] ||= request.host
      session["bootstrap_port"] ||= "6666"
    end
  end
  @bootstrap_host = session["bootstrap_host"]
  @bootstrap_port = session["bootstrap_port"]
  @bootstrap_url = @bootstrap_host + ":" + @bootstrap_port
end