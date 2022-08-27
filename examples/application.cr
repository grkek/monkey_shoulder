require "../src/application"

module Linus
  class ZB18A < MonkeyShoulder::Binding
    @brightness_level : Int32 = 0

    @[Annotations::ExternalMethod]
    def brightness_level
      @brightness_level
    end

    @[Annotations::ExternalMethod]
    def increase_brightness
      @brightness_level += 1
    end

    @[Annotations::ExternalMethod]
    def decrease_brightness
      @brightness_level -= 1
    end
  end
end

Log.setup(:debug)

app = MonkeyShoulder::Application.new(host: "0.0.0.0", port: 4000)
app.run
