package voldemort.client.protocol.admin.proxy;

import voldemort.serialization.SerializerDefinition;
import voldemort.store.StoreDefinition;

public class StoreInfo implements Comparable<StoreInfo>
{
  private String name;
  private SerializerInfo keySerializer;
  private SerializerInfo valueSerializer;
  
  public static StoreInfo fromStoreDefinition(StoreDefinition def)
  {
    StoreInfo info = new StoreInfo();
    info.setName(def.getName());
    SerializerDefinition keyDef = def.getKeySerializer();
    SerializerDefinition valueDef = def.getValueSerializer();
    info.setKeySerializer(SerializerInfo.fromSerializerDefinition(keyDef));
    info.setValueSerializer(SerializerInfo.fromSerializerDefinition(valueDef));
    return info;
  }
  
  public String getName()
  {
    return name;
  }
  
  public void setName(String name)
  {
    this.name = name;
  }

  public SerializerInfo getKeySerializer()
  {
    return keySerializer;
  }

  public void setKeySerializer(SerializerInfo keySerializer)
  {
    this.keySerializer = keySerializer;
  }

  public SerializerInfo getValueSerializer()
  {
    return valueSerializer;
  }

  public void setValueSerializer(SerializerInfo valueSerializer)
  {
    this.valueSerializer = valueSerializer;
  }

  @Override
  public int compareTo(StoreInfo o)
  {
    return String.CASE_INSENSITIVE_ORDER.compare(this.getName(), o.getName());
  }
}
