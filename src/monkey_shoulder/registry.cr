module MonkeyShoulder
  class Registry
    property registered_bindings : Utilities::Synchronized(Array(MonkeyShoulder::Models::Binding)) = Utilities::Synchronized(Array(MonkeyShoulder::Models::Binding)).new

    @@instance = new

    def self.instance
      @@instance
    end

    def register_binding(sub_class : Class, metadata)
      binding = MonkeyShoulder::Models::Binding.from_json({"id" => sub_class.instance.id, "metaData" => metadata}.to_json)
      @registered_bindings.push(binding)

      spawn { sub_class.instance.event_loop }
    end
  end
end
