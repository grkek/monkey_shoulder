require "json"
require "redis"
require "./extensions/**"
require "./monkey_shoulder/**"

module MonkeyShoulder
  macro build_bindings
    {% for subclass in MonkeyShoulder::Binding.all_subclasses %}
      {% maintenance_methods = subclass.methods.select { |m| m.annotation(MonkeyShoulder::Annotations::MaintenanceMethod) } %}
      {% built_in_methods = subclass.methods.select { |m| m.annotation(MonkeyShoulder::Annotations::BuiltInMethod) } %}
      {% external_methods = subclass.methods.select { |m| m.annotation(MonkeyShoulder::Annotations::ExternalMethod) } %}

      __maintenance_methods__ = {} of String => Hash(String, Hash(String, String)) | Hash(String, String) | Array(Hash(String, String))
      __built_in_methods__ = {} of String => Hash(String, Hash(String, String)) | Hash(String, String) | Array(Hash(String, String))
      __external_methods__ = {} of String => Hash(String, Hash(String, String)) | Hash(String, String) | Array(Hash(String, String))

      {% for method in maintenance_methods %}
        method_name = {{method.name.stringify}}
        args = {{method.args.map(&.stringify)}} of String

        args = args.map do |arg|
          {"name" => arg.to_s.split(":").first.strip, "type" => arg.to_s.split(":").last.strip}
        end

        __maintenance_methods__[method_name] = args.as(Array(Hash(String, String)))
      {% end %}

      {% for method in built_in_methods %}
        method_name = {{method.name.stringify}}
        args = {{method.args.map(&.stringify)}} of String

        args = args.map do |arg|
          {"name" => arg.to_s.split(":").first.strip, "type" => arg.to_s.split(":").last.strip}
        end

        __built_in_methods__[method_name] = args.as(Array(Hash(String, String)))
      {% end %}

      {% for method in external_methods %}
        method_name = {{method.name.stringify}}
        args = {{method.args.map(&.stringify)}} of String

        args = args.map do |arg|
          {"name" => arg.to_s.split(":").first.strip, "type" => arg.to_s.split(":").last.strip}
        end

        __external_methods__[method_name] = args.as(Array(Hash(String, String)))
      {% end %}

      MonkeyShoulder::Registry.instance.register_binding({{subclass}}, {"maintenanceMethods" => __maintenance_methods__, "builtInMethods" => __built_in_methods__, "externalMethods" => __external_methods__, "className" => {{subclass.name.stringify}}, "settings" => {} of String => JSON::Any})
    {% end %}
  end
end