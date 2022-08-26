require "./monkey_shoulder"
require "./monkey_shoulder_web"

module MonkeyShoulder
  class Application
    def initialize(@host : String, @port : Int32)
    end

    def run
      MonkeyShoulder.build_bindings

      server = MonkeyShoulderWeb::Server.new
      server.host = @host
      server.port = @port

      server.run
    end
  end
end
