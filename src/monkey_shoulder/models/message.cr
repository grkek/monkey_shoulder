module MonkeyShoulder
  module Models
    class Message
      include JSON::Serializable

      @[JSON::Field(key: "eTag")]
      property entity_tag : String?

      @[JSON::Field(key: "className")]
      property class_name : String?

      @[JSON::Field(key: "methodName")]
      property method_name : String

      @[JSON::Field(key: "type")]
      property type : String

      @[JSON::Field(key: "arguments")]
      property arguments : Hash(String, JSON::Any)
    end
  end
end
