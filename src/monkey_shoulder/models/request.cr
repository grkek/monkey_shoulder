module MonkeyShoulder
  module Models
    class Request
      include JSON::Serializable

      @[JSON::Field(key: "eTag")]
      property execution_tag : String

      @[JSON::Field(key: "body")]
      property body : JSON::Any
    end
  end
end
