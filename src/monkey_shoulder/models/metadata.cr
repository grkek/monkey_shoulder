module MonkeyShoulder
  module Models
    class MetaData
      include JSON::Serializable

      @[JSON::Field(key: "className")]
      property class_name : String

      @[JSON::Field(key: "settings")]
      property settings : Hash(String, JSON::Any)

      @[JSON::Field(key: "maintenanceMethods")]
      property maintenance_methods : Hash(String, Array(Hash(String, String)))

      @[JSON::Field(key: "builtInMethods")]
      property built_in_methods : Hash(String, Array(Hash(String, String)))

      @[JSON::Field(key: "externalMethods")]
      property external_methods : Hash(String, Array(Hash(String, String)))
    end
  end
end
