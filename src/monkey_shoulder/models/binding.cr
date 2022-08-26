module MonkeyShoulder
  module Models
    class Binding
      include JSON::Serializable

      @[JSON::Field(key: "id")]
      property id : String

      @[JSON::Field(key: "metaData")]
      property metadata : MetaData
    end
  end
end
