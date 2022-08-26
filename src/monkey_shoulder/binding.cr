module MonkeyShoulder
  class Binding
    Log = ::Log.for(self)
    alias Annotations = MonkeyShoulder::Annotations

    property id : String

    def initialize(id : String)
      @id = Digest::SHA1.hexdigest([id, UUID.random.to_s].join("-"))
    end

    macro inherited
      macro finished
        @@instance = new({{@type.name.stringify}})

        def self.instance
          @@instance
        end

        {% if !@type.abstract? %}
          __build_helpers__
        {% end %}
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

          {{method.name.stringify}} => ->(json : JSON::Any) do
            {% if args.size > 0 %}

              # Support argument lists
              if json.raw.is_a?(Array)
                arg_names = { {{*args.map(&.name.stringify)}} }
                args = json.as_a

                raise "wrong number of arguments for '#{{{method.name.stringify}}}' (given #{args.size}, expected #{arg_names.size})" if args.size > arg_names.size

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

            return_value || nil
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

          {{method.name.stringify}} => ->(json : JSON::Any) do
            {% if args.size > 0 %}

              # Support argument lists
              if json.raw.is_a?(Array)
                arg_names = { {{*args.map(&.name.stringify)}} }
                args = json.as_a

                raise "wrong number of arguments for '#{{{method.name.stringify}}}' (given #{args.size}, expected #{arg_names.size})" if args.size > arg_names.size

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

            return_value || nil
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

          {{method.name.stringify}} => ->(json : JSON::Any) do
            {% if args.size > 0 %}

              # Support argument lists
              if json.raw.is_a?(Array)
                arg_names = { {{*args.map(&.name.stringify)}} }
                args = json.as_a

                raise "wrong number of arguments for '#{{{method.name.stringify}}}' (given #{args.size}, expected #{arg_names.size})" if args.size > arg_names.size

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

            return_value || nil
          end,
        {% end %}
      } {% if external_methods.empty? %} of String => Nil {% end %}

      def event_loop
        redis = Redis.new

        redis.subscribe id do |on|
          on.message do |channel, message|
            message = MonkeyShoulder::Models::Message.from_json(message)

            begin
              case message.type
              when "MAINTENANCE"
                id = [@id, ".", message.class_name, ".", message.method_name].join
                proxy = MAINTENANCE_EXECUTORS[message.method_name]
                return_value = proxy.try(&.call(JSON.parse(message.arguments.to_json)))

                connection do |redis|
                  redis.publish(id, {"eTag" => message.execution_tag, "body" => {"success" => true, "errors" => [] of String, "returnValue" => return_value}}.to_json)
                end
              when "BUILTIN"
                id = [@id, ".", message.class_name, ".", message.method_name].join
                proxy = BUILTIN_EXECUTORS[message.method_name]
                return_value = proxy.try(&.call(JSON.parse(message.arguments.to_json)))

                connection do |redis|
                  redis.publish(id, {"eTag" => message.execution_tag, "body" => {"success" => true, "errors" => [] of String, "returnValue" => return_value}}.to_json)
                end
              when "EXTERNAL"
                id = [@id, ".", message.class_name, ".", message.method_name].join
                proxy = EXTERNAL_EXECUTORS[message.method_name]
                return_value = proxy.try(&.call(JSON.parse(message.arguments.to_json)))

                connection do |redis|
                  redis.publish(id, {"eTag" => message.execution_tag, "body" => {"success" => true, "errors" => [] of String, "returnValue" => return_value}}.to_json)
                end
              end
            rescue exception
              connection do |redis|
                redis.publish(id, {"eTag" => message.execution_tag, "body" => {"success" => false, "errors" => [exception.message.to_s.gsub("\"", "'")] of String, "returnValue" => nil}})
              end

              Log.error(exception: exception) {}
            end
          end
        end

        redis.close()
      end

      private def connection
        redis = Redis.new
        yield redis
        redis.close()
      end
    end
  end
end
