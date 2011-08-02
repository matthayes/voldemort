require 'rubygems'
require 'sinatra'
require 'haml'

include Java

helpers do
  def pretty_print(val)
    if val.class == String
      val.inspect
    elsif val.respond_to? :each_key
      '{' + val.map { |k,v| pretty_print(k) + ' => ' + pretty_print(v) }.to_a.join(', ') + '}'
    elsif val.respond_to? :each
      '[' + val.map { |v| pretty_print(v) }.to_a.join(', ') + ']'
    else
      val.inspect
    end
  end
end

get '/' do
  redirect to '/stores'
end

get '/clusters/:name' do |cluster|
  clusters = @@clusters.find_all { |c| c['name'] == cluster }
  if clusters && clusters.size > 0
    cluster = clusters[0]
    session["bootstrap_host"] = cluster['host'].to_s
    session["bootstrap_port"] = cluster['port'].to_s    
  end
  redirect to '/stores'
end

get '/stores' do
  begin
    proxy = VoldemortAdmin::AdminProxy.new(@bootstrap_host, @bootstrap_port)
    @stores = proxy.stores
  rescue
  ensure
    proxy.close unless proxy.nil?
  end
  unless @stores.nil?    
    @stores.sort!
    haml :index
  else
    haml :bad_url
  end
end

get '/store/:name' do |name|
  begin
  @name = name
    proxy = VoldemortAdmin::AdminProxy.new(@bootstrap_host, @bootstrap_port)
    @store = proxy.store(name)
    halt 404 unless @store
    @limit = 25
    fetch_count = @limit + 1
    @entries = proxy.entries(name, fetch_count)
    @has_more = @entries.size >= fetch_count
    @entries = @entries.take(@limit)
  ensure
    proxy.close unless proxy.nil?
  end
  
  haml :store
end

include_class Java::voldemort.client.SocketStoreClientFactory
include_class Java::voldemort.client.ClientConfig

get '/store/:name/:key' do |name, key|
  config = ClientConfig.new
  config.setBootstrapUrls("tcp://" + @bootstrap_url)
  
  begin  
    factory = SocketStoreClientFactory.new(config)
    client = factory.getStoreClient(name)
  
    proxy = VoldemortAdmin::AdminProxy.new(@bootstrap_host, @bootstrap_port)
    @store = proxy.store(name)
    key_schema = @store.key_info.schema
  
    # TODO: This only supports keys which are int32 or strings.  Figure out how a string
    # can be passed from the browser and converted to the appropriate type before calling
    # client.getValue.
    if (key_schema =~ /int32/)
      pretty_print client.getValue(java.lang.Integer.new(key.to_i))
    else
      pretty_print client.getValue(key)
    end
  ensure
    factory.close unless factory.nil?
    proxy.close unless proxy.nil?
  end    
end

get '/stores/new' do
  haml :store_new
end

require 'app/helpers/VoldemortAdmin'

post '/stores/new' do
  key_info = VoldemortAdmin::SerializerInfo.new
  key_info.name = params[:store_key_name]
  key_info.schema = params[:store_key_schema]
  
  value_info = VoldemortAdmin::SerializerInfo.new
  value_info.name = params[:store_value_name]
  value_info.schema = params[:store_value_schema]
  
  store_info = VoldemortAdmin::StoreInfo.new
  store_info.name = params[:store_name]
  store_info.key_info = key_info
  store_info.value_info = value_info
  
  begin
    proxy = VoldemortAdmin::AdminProxy.new(@bootstrap_host, @bootstrap_port)
    proxy.create_store(store_info)
  ensure
    proxy.close unless proxy.nil?
  end
  
  redirect to '/stores'
end

get '/config' do
  haml :config
end

post '/config' do
  session["bootstrap_host"] = params["bootstrap_host"]
  session["bootstrap_port"] = params["bootstrap_port"]
  redirect to '/stores'
end