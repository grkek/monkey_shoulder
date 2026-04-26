class HTTP::WebSocket
  class Protocol
    private record SuccessResponse(T),
      entity_tag : String,
      success : Bool,
      return_value : T? do
      include JSON::Serializable

      @[JSON::Field(key: "entityTag")]
      getter entity_tag : String

      @[JSON::Field(key: "returnValue")]
      getter return_value : T?

      getter success : Bool
    end

    private record ErrorResponse,
      entity_tag : String,
      success : Bool,
      errors : Array(String) do
      include JSON::Serializable

      @[JSON::Field(key: "entityTag")]
      getter entity_tag : String

      getter success : Bool
      getter errors : Array(String)
    end

    def json(entity_tag : String, success : Bool, body : T) : Nil forall T
      payload = if success
                  SuccessResponse.new(
                    entity_tag: entity_tag,
                    success: true,
                    return_value: body
                  )
                else
                  ErrorResponse.new(
                    entity_tag: entity_tag,
                    success: false,
                    errors: [body.to_s]
                  )
                end

      send(payload.to_json)
    end
  end
end
