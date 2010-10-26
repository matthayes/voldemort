package voldemort.client.protocol.admin.proxy;

import voldemort.serialization.SerializerDefinition;

public class SerializerInfo
{
  private String name;
  private String schemaInfo;
  
  public String getName()
  {
    return name;
  }
  
  public void setName(String name)
  {
    this.name = name;
  }

  public String getSchemaInfo()
  {
    return schemaInfo;
  }

  public void setSchemaInfo(String schemaInfo)
  {
    this.schemaInfo = schemaInfo;
  }
  
  public static SerializerInfo fromSerializerDefinition(SerializerDefinition definition)
  {
    SerializerInfo info = new SerializerInfo();
    
    info.setName(definition.getName());
    
    // schema info may not be defined
    if (definition.hasSchemaInfo())
    {
      info.setSchemaInfo(definition.getCurrentSchemaInfo());
    }
    
    return info;
  }
}
