require "../src/application"

require "uuid"
require "socket"
require "http/client"

module Linus
  PORT = 5995

  class Client
    def initialize(@api_key : String)
    end

    def status
      response = HTTP::Client.get(url: "http://0.0.0.0:4004/status", headers: HTTP::Headers{"Authorization" => "Bearer #{@api_key}"})
      raise Exception.new("unexpected response #{response.status_code}\n#{response.body}") unless response.success?

      JSON.parse(response.body)
    end

    def increase_brightness
      response = HTTP::Client.post(url: "http://0.0.0.0:4004/increaseBrightness", headers: HTTP::Headers{"Authorization" => "Bearer #{@api_key}"})
      raise Exception.new("unexpected response #{response.status_code}\n#{response.body}") unless response.success?

      JSON.parse(response.body)
    end
  end

  class ZB18A < MonkeyShoulder::Binding
    @brightness_level : Int32 = 0

    getter! client : Client

    def start
    end

    def update
      api_key = setting?("apiKey", JSON::Any.new("e30=")).as_s

      @client = Client.new(api_key)
    end

    @[Annotations::ExternalMethod]
    def display_client
      pp @client

      "Hello, World!"
    end
  end
end

Log.setup(:debug)

app = MonkeyShoulder::Application.new(host: "0.0.0.0", port: 4000)
app.run
