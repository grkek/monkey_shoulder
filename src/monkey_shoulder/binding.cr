module MonkeyShoulder
  abstract class Binding
    alias Annotations = MonkeyShoulder::Annotations
    alias Registry = MonkeyShoulder::Registry

    property id : String

    def initialize(id : String)
      @id = Digest::SHA1.hexdigest(id)

      spawn do
        loop do
          settings = yield_redis do |redis|
            next redis.get(@id)
          end

          bindings = Registry.instance.registered_bindings.reject do |binding|
            binding.id != @id
          end

          if bindings.size != 0
            binding = bindings.first

            if settings
              binding.metadata.settings = JSON.parse(settings).as_h

              update
            else
              yield_redis do |redis|
                redis.set(@id, binding.metadata.settings.to_json)
              end
            end

            break
          else
            sleep(0.5)
          end
        end

        start
      end
    end

    macro inherited
      macro finished
        @@instance = new({{@type.name.stringify}})

        def self.instance
          @@instance
        end

        {% if !@type.abstract? %}
          __bind_built_in_methods__
          __build_helpers__
        {% end %}
      end
    end

    macro __bind_built_in_methods__
      @[Annotations::BuiltInMethod]
      def setting(key : String, value : JSON::Any)
        bindings = Registry.instance.registered_bindings.reject do |binding|
          binding.id != @id
        end

        binding = bindings.first

        binding.metadata.settings[key] = value

        yield_redis do |redis|
          redis.set(@id, binding.metadata.settings.to_json)
        end

        update

        binding.metadata.settings
      end

      @[Annotations::BuiltInMethod]
      def setting?(key : String, default_value : JSON::Any = JSON::Any.new(nil))
        bindings = Registry.instance.registered_bindings.reject do |binding|
          binding.id != @id
        end

        binding = bindings.first

        settings = yield_redis do |redis|
          next redis.get(@id)
        end

        if binding.metadata.settings.to_json != settings
          raise Exception.new("Out of sync settings")
        else
          if value = binding.metadata.settings[key]?
            value
          else
            default_value
          end
        end
      end
    end

    macro __build_helpers__
      {% maintenance_methods = @type.methods.select { |m| m.annotation(MonkeyShoulder::Annotations::MaintenanceMethod) } %}
      {% built_in_methods = @type.methods.select { |m| m.annotation(MonkeyShoulder::Annotations::BuiltInMethod) } %}
      {% external_methods = @type.methods.select { |m| m.annotation(MonkeyShoulder::Annotations::ExternalMethod) } %}

      MAINTENANCE_EXECUTORS = {
        {% for method in maintenance_methods %}
          {% index = 0 %}
          {% args = [] of Crystal::Macros::Arg %}
          {% for arg in method.args %}
            {% if !method.splat_index || index < method.splat_index %}
              {% args << arg %}
            {% end %}
            {% index = index + 1 %}
          {% end %}

          {{method.name.stringify}}.camelcase(lower: true) => ->(json : JSON::Any) do
            {% if args.size > 0 %}

              # Support argument lists
              if json.raw.is_a?(Array)
                arg_names = { {{args.map(&.name.stringify).splat}} }
                args = json.as_a

                raise "Wrong number of arguments for '#{{{method.name.stringify}}}' (given #{args.size}, expected #{arg_names.size})" if args.size > arg_names.size

                hash = {} of String => JSON::Any
                json.as_a.each_with_index do |value, index|
                  hash[arg_names[index]] = value
                end

                json = hash
              end

              # Support named arguments
              tuple = {
                {% for arg in args %}
                  {% arg_name = arg.name.stringify %}

                  {% raise "#{@type}##{method.name} argument `#{arg.name}` is missing a type" if arg.restriction.is_a?(Nop) %}

                  {% if !arg.restriction.is_a?(Union) && arg.restriction.resolve < ::Enum %}
                    {% if arg.default_value.is_a?(Nop) %}
                      {{arg.name}}: ({{arg.restriction}}).parse(json[{{arg_name}}].as_s),
                    {% else %}
                      {{arg.name}}: json[{{arg_name}}]? != nil ? ({{arg.restriction}}).parse(json[{{arg_name}}].as_s) : {{arg.default_value}},
                    {% end %}
                  {% else %}
                    {% if arg.default_value.is_a?(Nop) %}
                      {{arg.name}}: ({{arg.restriction}}).from_json(json[{{arg_name}}].to_json),
                    {% else %}
                      {{arg.name}}: json[{{arg_name}}]? ? ({{arg.restriction}}).from_json(json[{{arg_name}}].to_json) : {{arg.default_value}},
                    {% end %}
                  {% end %}
                {% end %}
              }
              return_value = {{@type.id}}.instance.{{method.name}}(**tuple)
            {% else %}
              return_value = {{@type.id}}.instance.{{method.name}}
            {% end %}

            return_value
          end,
        {% end %}
      } {% if maintenance_methods.empty? %} of String => Nil {% end %}

      BUILTIN_EXECUTORS = {
        {% for method in built_in_methods %}
          {% index = 0 %}
          {% args = [] of Crystal::Macros::Arg %}
          {% for arg in method.args %}
            {% if !method.splat_index || index < method.splat_index %}
              {% args << arg %}
            {% end %}
            {% index = index + 1 %}
          {% end %}

          {{method.name.stringify}}.camelcase(lower: true) => ->(json : JSON::Any) do
            {% if args.size > 0 %}

              # Support argument lists
              if json.raw.is_a?(Array)
                arg_names = { {{args.map(&.name.stringify).splat}} }

                args = json.as_a

                raise "Wrong number of arguments for '#{{{method.name.stringify}}}' (given #{args.size}, expected #{arg_names.size})" if args.size > arg_names.size

                hash = {} of String => JSON::Any
                json.as_a.each_with_index do |value, index|
                  hash[arg_names[index]] = value
                end

                json = hash
              end

              # Support named arguments
              tuple = {
                {% for arg in args %}
                  {% arg_name = arg.name.stringify %}

                  {% raise "#{@type}##{method.name} argument `#{arg.name}` is missing a type" if arg.restriction.is_a?(Nop) %}

                  {% if !arg.restriction.is_a?(Union) && arg.restriction.resolve < ::Enum %}
                    {% if arg.default_value.is_a?(Nop) %}
                      {{arg.name}}: ({{arg.restriction}}).parse(json[{{arg_name}}].as_s),
                    {% else %}
                      {{arg.name}}: json[{{arg_name}}]? != nil ? ({{arg.restriction}}).parse(json[{{arg_name}}].as_s) : {{arg.default_value}},
                    {% end %}
                  {% else %}
                    {% if arg.default_value.is_a?(Nop) %}
                      {{arg.name}}: ({{arg.restriction}}).from_json(json[{{arg_name}}].to_json),
                    {% else %}
                      {{arg.name}}: json[{{arg_name}}]? ? ({{arg.restriction}}).from_json(json[{{arg_name}}].to_json) : {{arg.default_value}},
                    {% end %}
                  {% end %}
                {% end %}
              }
              return_value = {{@type.id}}.instance.{{method.name}}(**tuple)
            {% else %}
              return_value = {{@type.id}}.instance.{{method.name}}
            {% end %}

            return_value
          end,
        {% end %}
      } {% if built_in_methods.empty? %} of String => Nil {% end %}

      EXTERNAL_EXECUTORS = {
        {% for method in external_methods %}
          {% index = 0 %}
          {% args = [] of Crystal::Macros::Arg %}
          {% for arg in method.args %}
            {% if !method.splat_index || index < method.splat_index %}
              {% args << arg %}
            {% end %}
            {% index = index + 1 %}
          {% end %}

          {{method.name.stringify}}.camelcase(lower: true) => ->(json : JSON::Any) do
            {% if args.size > 0 %}

              # Support argument lists
              if json.raw.is_a?(Array)
                arg_names = { {{args.map(&.name.stringify).splat}} }
                args = json.as_a

                raise "Wrong number of arguments for '#{{{method.name.stringify}}}' (given #{args.size}, expected #{arg_names.size})" if args.size > arg_names.size

                hash = {} of String => JSON::Any
                json.as_a.each_with_index do |value, index|
                  hash[arg_names[index]] = value
                end

                json = hash
              end

              # Support named arguments
              tuple = {
                {% for arg in args %}
                  {% arg_name = arg.name.stringify %}

                  {% raise "#{@type}##{method.name} argument `#{arg.name}` is missing a type" if arg.restriction.is_a?(Nop) %}

                  {% if !arg.restriction.is_a?(Union) && arg.restriction.resolve < ::Enum %}
                    {% if arg.default_value.is_a?(Nop) %}
                      {{arg.name}}: ({{arg.restriction}}).parse(json[{{arg_name}}].as_s),
                    {% else %}
                      {{arg.name}}: json[{{arg_name}}]? != nil ? ({{arg.restriction}}).parse(json[{{arg_name}}].as_s) : {{arg.default_value}},
                    {% end %}
                  {% else %}
                    {% if arg.default_value.is_a?(Nop) %}
                      {{arg.name}}: ({{arg.restriction}}).from_json(json[{{arg_name}}].to_json),
                    {% else %}
                      {{arg.name}}: json[{{arg_name}}]? ? ({{arg.restriction}}).from_json(json[{{arg_name}}].to_json) : {{arg.default_value}},
                    {% end %}
                  {% end %}
                {% end %}
              }
              return_value = {{@type.id}}.instance.{{method.name}}(**tuple)
            {% else %}
              return_value = {{@type.id}}.instance.{{method.name}}
            {% end %}

            return_value
          end,
        {% end %}
      } {% if external_methods.empty? %} of String => Nil {% end %}

      def event_loop
        redis = Redis.new

        redis.subscribe id do |on|
          on.message do |channel, message|
            message = MonkeyShoulder::Models::Message.from_json(message)
            class_name = message.class_name.to_s.gsub("::", ".")

            spawn do
              id = [@id, ".", class_name, ".", message.method_name].join

              begin
                case message.type
                when "MAINTENANCE"
                  proxy = MAINTENANCE_EXECUTORS[message.method_name]
                  return_value = proxy.try(&.call(JSON.parse(message.arguments.to_json)))

                  yield_redis do |redis|
                    redis.publish(id, {"eTag" => message.entity_tag, "body" => {"success" => true, "errors" => [] of String, "returnValue" => return_value}}.to_json)
                  end
                when "BUILTIN"
                  proxy = BUILTIN_EXECUTORS[message.method_name]
                  return_value = proxy.try(&.call(JSON.parse(message.arguments.to_json)))

                  yield_redis do |redis|
                    redis.publish(id, {"eTag" => message.entity_tag, "body" => {"success" => true, "errors" => [] of String, "returnValue" => return_value}}.to_json)
                  end
                when "EXTERNAL"
                  proxy = EXTERNAL_EXECUTORS[message.method_name]
                  return_value = proxy.try(&.call(JSON.parse(message.arguments.to_json)))

                  yield_redis do |redis|
                    redis.publish(id, {"eTag" => message.entity_tag, "body" => {"success" => true, "errors" => [] of String, "returnValue" => return_value}}.to_json)
                  end
                end
              rescue exception
                yield_redis do |redis|
                  redis.publish(id, {"eTag" => message.entity_tag, "body" => {"success" => false, "errors" => [exception.message.to_s.gsub("\"", "'")] of String, "returnValue" => nil}})
                end

                Log.error(exception: exception) { "An error occured while executing #{id}" }
              end
            end
          end
        end

        redis.close()
      end

      def default_settings(settings : Hash(String, JSON::Any))
        settings.each do |key, value|
          setting(key, value)
        end
      end

      private def yield_redis
        redis = Redis.new
        value = yield redis
        redis.close()

        value
      end

    end

    abstract def start
    abstract def update
  end
end
