module MonkeyShoulder
  class Application
    include Grip::Application

    property handlers : Array(HTTP::Handler) = [
      Grip::Handlers::Exception.new,
      Grip::Handlers::WebSocket.new,
    ] of HTTP::Handler

    def initialize
      routes
    end

    def routes
      scope do
        ws "/socket", MonkeyShoulderWeb::Controllers::Instance
      end
    end
  end
end
