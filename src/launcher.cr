require "./monkey_shoulder"
require "./monkey_shoulder_web"

module MonkeyShoulder
  class Launcher
    getter application : MonkeyShoulder::Application = MonkeyShoulder::Application.new

    def run
      MonkeyShoulder.build_bindings

      application.run
    end
  end
end
