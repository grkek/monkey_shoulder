module MonkeyShoulder
  module Models
    class Response
      include JSON::Serializable

      @[JSON::Field(key: "eTag")]
      property execution_tag : String

      @[JSON::Field(key: "body")]
      property body : JSON::Any

      def flush(socket : HTTP::WebSocket::Protocol)
        socket.send(self.to_json)
      end
    end
  end
end
