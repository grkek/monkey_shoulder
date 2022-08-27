require "json"
require "redis"
require "uuid"
require "digest"
require "./extensions/**"
require "./utilities/**"
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
        names = {{method.args.map(&.name.stringify)}} of String
        restrictions = {{method.args.map(&.restriction.stringify)}} of String

        pairs = Hash.zip(names, restrictions)

        args = pairs.map do |pair|
          {"name" => pair.first, "type" => pair.last}
        end

        __maintenance_methods__[method_name] = args.as(Array(Hash(String, String)))
      {% end %}

      {% for method in built_in_methods %}
        method_name = {{method.name.stringify}}
        names = {{method.args.map(&.name.stringify)}} of String
        restrictions = {{method.args.map(&.restriction.stringify)}} of String

        pairs = Hash.zip(names, restrictions)

        args = pairs.map do |pair|
          {"name" => pair.first, "type" => pair.last}
        end

        __built_in_methods__[method_name] = args.as(Array(Hash(String, String)))
      {% end %}

      {% for method in external_methods %}
        method_name = {{method.name.stringify}}
        names = {{method.args.map(&.name.stringify)}} of String
        restrictions = {{method.args.map(&.restriction.stringify)}} of String

        pairs = Hash.zip(names, restrictions)

        args = pairs.map do |pair|
          {"name" => pair.first, "type" => pair.last}
        end

        __external_methods__[method_name] = args.as(Array(Hash(String, String)))
      {% end %}

      MonkeyShoulder::Registry.instance.register_binding({{subclass}}, {"maintenanceMethods" => __maintenance_methods__, "builtInMethods" => __built_in_methods__, "externalMethods" => __external_methods__, "className" => {{subclass.name.stringify}}, "settings" => {} of String => JSON::Any})
    {% end %}
  end
end
