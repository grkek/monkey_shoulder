module MonkeyShoulder
  module Models
    class Response
      include JSON::Serializable

      @[JSON::Field(key: "eTag")]
      property entity_tag : String

      @[JSON::Field(key: "body")]
      property body : JSON::Any
    end
  end
end
