require 'rubygems'
require 'sinatra'
require 'haml'

include Java

# Load all the jar files...

# In production Warbler places all JAR files under lib. 
configure :production do
  puts "Loading production JARs"
  Dir["lib/*.jar"].each do |jar| 
    puts "requiring #{jar}"
    require jar 
  end
end

# In development mode we need to pick up JARs from various locations.
configure :development do
  puts "Loading development JARs"
  
  libs = []
  
  # Voldemort dependencies...
  libs << "../../lib/*.jar"
  
  # Voldemort itself...
  libs << "../../dist/voldemort-0.81.jar"
  
  # The contrib JAR which has the AdminProxy class...
  libs << "../../dist/voldemort-contrib-0.81.jar"
  
  # Pick up additional dependencies required by AdminProxy class.
  libs << "lib/*.jar"

  libs.each do |lib|
    Dir[lib].each do |jar| 
      puts "requiring #{jar}"
      require jar 
    end
  end
end

include_class Java::voldemort.client.protocol.admin.proxy.AdminProxy
include_class Java::voldemort.client.protocol.admin.proxy.StoreInfo
include_class Java::voldemort.client.protocol.admin.proxy.SerializerInfo

helpers do
  def getProxy(url)
    AdminProxy.new("tcp://" + url)
  end
end

before do
  @bootstrap_host = "localhost"
  @bootstrap_port = "6666"
  @bootstrap_url = @bootstrap_host + ":" + @bootstrap_port
end

get '/' do
  redirect url_for '/stores'
end

get '/stores' do
  proxy = getProxy(@bootstrap_url)
  @stores = proxy.getStores
  haml :index
end

get '/store/:name' do |name|
  @name = name
  proxy = getProxy(@bootstrap_url)
  @store = proxy.getStore(name)
  halt 404 unless @store
  @entries = proxy.getEntries(name, 25)
  haml :store
end

get '/stores/new' do
  haml :store_new
end

post '/stores/new' do
  proxy = getProxy(@bootstrap_url)
   
  store = StoreInfo.new
  
  store.name = params[:store_name]
  
  key_info = SerializerInfo.new
  value_info = SerializerInfo.new
  
  key_info.name = params[:store_key_name]
  key_info.schema_info = params[:store_key_schema]
  
  value_info.name = params[:store_value_name]
  value_info.schema_info = params[:store_value_schema]  
  
  store.key_serializer = key_info
  store.value_serializer = value_info
  
  proxy.create_store(store)
  
  redirect url_for '/stores'
end

