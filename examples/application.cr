require "../src/application"

module Linus
  class ZB18A < MonkeyShoulder::Binding
    @[Annotations::ExternalMethod]
    def increase_brightness
      brightness_level = setting?("brightnessLevel")

      if brightness_level
        current_level = brightness_level.as_i

        if current_level >= 100
          raise Exception.new("Can not set brightness level to more than 100")
        end

        actual_level = current_level + 1

        setting("brightnessLevel", JSON::Any.new(actual_level))
      else
        setting("brightnessLevel", JSON::Any.new(1))

        1
      end
    end
  end
end

module Samsung
  class TV1B1RD5 < MonkeyShoulder::Binding
    @[Annotations::ExternalMethod]
    def async_task
      sleep(60)
      puts "Async task has finished"
    end

    @[Annotations::ExternalMethod]
    def off
      setting("isOn", JSON::Any.new(false))
      setting("isOff", JSON::Any.new(true))
    end

    @[Annotations::ExternalMethod]
    def print(text : String)
      puts text
    end
  end
end

Log.setup(:debug)

app = MonkeyShoulder::Application.new(host: "0.0.0.0", port: 4000)
app.run
