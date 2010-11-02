package voldemort.client.protocol.admin.proxy;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;

import net.sf.json.JSONObject;
import net.sf.json.JSONArray;
import net.sf.json.JSON;
import voldemort.VoldemortException;
import voldemort.client.RoutingTier;
import voldemort.client.protocol.admin.AdminClient;
import voldemort.client.protocol.admin.AdminClientConfig;
import voldemort.client.protocol.admin.filter.DefaultVoldemortFilter;
import voldemort.cluster.Cluster;
import voldemort.serialization.DefaultSerializerFactory;
import voldemort.serialization.Serializer;
import voldemort.serialization.SerializerDefinition;
import voldemort.store.StoreDefinition;
import voldemort.utils.ByteArray;
import voldemort.utils.Pair;
import voldemort.versioning.Versioned;

public class AdminProxy
{
  
  private final AdminClientConfig config;
  private final AdminClient client;
  private final Cluster cluster;
  
  public AdminProxy(String bootstrapUrl)
  {
    config = new AdminClientConfig();
    
    client = new AdminClient(bootstrapUrl, config);
    cluster = client.getAdminClientCluster();
  }
  
  public void createStore(StoreInfo storeInfo)
  {
    SerializerInfo keySerializer = storeInfo.getKeySerializer();
    SerializerInfo valueSerializer = storeInfo.getValueSerializer();
    SerializerDefinition keyDef = new SerializerDefinition(keySerializer.getName(), keySerializer.getSchemaInfo());
    SerializerDefinition valueDef = new SerializerDefinition(valueSerializer.getName(), valueSerializer.getSchemaInfo());
    
    StoreDefinition def = new StoreDefinition(
                                              storeInfo.getName(), 
                                              "bdb" /*type*/, 
                                              keyDef,
                                              valueDef,
                                              RoutingTier.CLIENT,
                                              "consistent-routing" /*routingStrategyType*/,
                                              1 /* replicationFactor */,
                                              1 /* preferredReads */, 
                                              1 /*requiredReads*/, 
                                              1 /*preferredWrites*/,
                                              1 /*requiredWrites*/, 
                                              null /*viewOfStore*/, 
                                              null /*valTrans*/, 
                                              null /*zoneReplicationFactor*/, 
                                              null/*zoneCountReads*/, 
                                              null /*zoneCountWrites*/, 
                                              null /*retentionDays*/, 
                                              null /*retentionThrottleRate*/
                                              );
    client.addStore(def);
  }
  
  public List<StoreInfo> getStores()
  {
    List<StoreDefinition> defs = client.getRemoteStoreDefList(0).getValue();
    List<StoreInfo> storeInfos = new ArrayList<StoreInfo>();
    for (StoreDefinition def : defs) 
    {
      storeInfos.add(StoreInfo.fromStoreDefinition(def));
    }
    Collections.sort(storeInfos);
    return storeInfos;
  }
  
  public StoreInfo getStore(String storeName)
  {
    List<StoreDefinition> defs = client.getRemoteStoreDefList(0).getValue();
    StoreDefinition foundDef = getStoreDefinitionByName(storeName, defs);
    
    if (foundDef != null)
    {
      return StoreInfo.fromStoreDefinition(foundDef);
    }
    else
    {
      return null;
    }
  }
  
  public List<Pair<String,String>> getEntries(String storeName, int limit)
  {
    List<StoreDefinition> defs = client.getRemoteStoreDefList(0).getValue();
    List<Integer> partitions = cluster.getNodeById(0).getPartitionIds();
    StoreDefinition def = getStoreDefinitionByName(storeName, defs);
    
    if (def != null)
    {
      SerializerDefinition keySerializer = null;
      SerializerDefinition valueSerializer = null;
      keySerializer = def.getKeySerializer();      
      valueSerializer = def.getValueSerializer();  
            
      // Only JSON serialization is supported since others require external libraries.
      // TODO: How to indicate to Sinatra that this type isn't supported?
      String keySerializerName = keySerializer.getName();
      String valueSerializerName = valueSerializer.getName();
      if ((!keySerializerName.equals("json") && !keySerializerName.equals("string"))
          || (!valueSerializerName.equals("json") && !valueSerializerName.equals("identity")))
      {
        // entries cannot be deserialized unless both are JSON
        return null;
      }
      
      Iterator<Pair<ByteArray, Versioned<byte[]>>> entries = client.fetchEntries(0, storeName, partitions, new DefaultVoldemortFilter(), false);
      List<Pair<String,String>> result = new ArrayList<Pair<String,String>>();
      
      boolean hasAny = false;
            
      try
      {
        hasAny = entries.hasNext();
      }
      catch (VoldemortException e)
      { 
        System.out.printf("Error fetching entries: %s\n", e.toString());
        e.printStackTrace(System.out);
        
        // ignore any exceptions and treat this as no entries
      }
      
      if (hasAny)
      {
        for (int i=0; i<limit; i++)
        {
          if (!entries.hasNext()) { break; }
          Pair<ByteArray, Versioned<byte[]>> pair = entries.next();
          byte[] first = pair.getFirst().get();
          byte[] second = pair.getSecond().getValue();
          DefaultSerializerFactory factory = new DefaultSerializerFactory();
          
          Serializer<?> keyS = factory.getSerializer(keySerializer);
          Serializer<?> valueS = factory.getSerializer(valueSerializer);
          
          Object key = keyS.toObject(first);
          Object valueObj = valueS.toObject(second);
          
          JSON value = null;
                    
          if (valueObj instanceof java.util.ArrayList)
          {
            value = JSONArray.fromObject(valueObj);            
          }
          else if (valueObj instanceof java.util.HashMap)
          {
            value = JSONObject.fromObject(valueObj); 
          }
          
          result.add(new Pair<String,String>(key.toString(), value != null ? value.toString(1) : ""));
        }
      }
      
      return result;
    }
    else
    {
      return null;
    }
  }
    
  private static StoreDefinition getStoreDefinitionByName(String storeName, List<StoreDefinition> defs)
  {
    StoreDefinition foundDef = null;
    for (StoreDefinition def : defs)
    {
      if (def.getName().equals(storeName))
      {
        foundDef = def;
        break;
      }
    }
    return foundDef;
  }
  
}
