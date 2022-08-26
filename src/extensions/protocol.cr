class HTTP::WebSocket
  class Protocol
    property id : String = UUID.random.to_s

    def json(execution_tag, response)
      status = response.first
      body = response.last

      case status
      when :ok
        response = MonkeyShoulder::Models::Response.from_json({"eTag" => execution_tag, "body" => {"success" => true, "errors" => [] of String, "returnValue" => body}}.to_json)
        self.send(response.to_json)
      when :error
        response = MonkeyShoulder::Models::Response.from_json({"eTag" => execution_tag, "body" => {"success" => false, "errors" => [body.to_s] of String, "returnValue" => nil}}.to_json)
        self.send(response.to_json)
      end
    end
  end
end
