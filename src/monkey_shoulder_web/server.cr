module MonkeyShoulderWeb
  class Server < Grip::Application
    property host : String = "0.0.0.0"
    property port : Int32 = 4000

    def initialize
      super(environment: "production")

      scope "/ws" do
        ws "/socket", Controllers::InstanceController
      end
    end
  end
end
