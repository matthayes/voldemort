require 'rubygems'
require 'sinatra'
require 'haml'

include Java

# load all the jar files
libs = []
libs << "lib/*.jar"
libs << "../../lib/*.jar"
libs << "../../dist/voldemort-0.81.jar"
libs << "../../dist/voldemort-contrib-0.81.jar"

libs.each do |lib|
  Dir[lib].each do |jar| 
    puts "requiring #{jar}"
    require jar 
  end
end

include_class Java::voldemort.client.protocol.admin.proxy.AdminProxy
include_class Java::voldemort.client.protocol.admin.proxy.StoreInfo
include_class Java::voldemort.client.protocol.admin.proxy.SerializerInfo

@@bootstrapUrl = "tcp://localhost:6666"

def getProxy
  AdminProxy.new(@@bootstrapUrl)
end

get '/' do
  redirect url_for '/stores'
end

get '/stores' do
  proxy = getProxy
  @stores = proxy.getStores
  haml :index
end

get '/store/:name' do |name|
  @name = name
  proxy = getProxy  
  @store = proxy.getStore(name)
  halt 404 unless @store
  @entries = proxy.getEntries(name, 25)
  haml :store
end

get '/stores/new' do
  haml :store_new
end

post '/stores/new' do
  proxy = getProxy
   
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

