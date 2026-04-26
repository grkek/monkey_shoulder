module MonkeyShoulderWeb
  module Controllers
    class Instance
      include Grip::Controllers::WebSocket

      alias Models = MonkeyShoulder::Models
      alias Registry = MonkeyShoulder::Registry

      def initialize
        @buffer = Bytes.new(4096)
        @current_message = IO::Memory.new

        @pool = Utilities::RedisPool.new
        @sockets = Utilities::Synchronized(Array(Socket)).new
        @subscription_manager = Utilities::SubscriptionManager.new(@pool, @sockets)
      end

      def on_open(context : Context, socket : Socket) : Void
        @sockets.push(socket)
        Log.debug { "Client connected." }

        @subscription_manager.start

        Registry.instance.registered_bindings.each do |binding|
          all_methods = binding.metadata.maintenance_methods.keys +
                        binding.metadata.built_in_methods.keys +
                        binding.metadata.external_methods.keys

          all_methods.each do |method|
            @subscription_manager.subscribe(build_handler(binding, method))
          end
        end
      end

      def on_message(context : Context, socket : Socket, message : String) : Void
        request = parse_request(message)

        unless request
          disconnect(socket)
          return
        end

        handle_instruction(socket, request)
      end

      def on_close(context : Context, socket : Socket, close_code : HTTP::WebSocket::CloseCode | Int?, message : String) : Void
        cleanup(socket)
        Log.debug { "Client disconnected." }
      end

      def on_ping(context : Context, socket : Socket, message : String) : Void
        socket.pong(message)
      end

      def on_pong(context : Context, socket : Socket, message : String) : Void
        socket.ping(message)
      end

      def on_binary(context : Context, socket : Socket, binary : Bytes) : Void
      end

      private def build_handler(binding, method : String) : String
        [binding.id, ".", binding.metadata.class_name.gsub("::", "."), ".", method].join
      end

      private def parse_request(raw : String) : Models::Request?
        Models::Request.from_json(raw)
      rescue
        nil
      end

      private def handle_instruction(socket : Socket, request : Models::Request) : Void
        case request.body["instructionName"].to_s
        when "getBinding"
          socket.json(request.entity_tag, true, find_binding(request.body["id"].to_s))
        when "listBindings"
          socket.json(request.entity_tag, true, Registry.instance.registered_bindings)
        when "executeMethod"
          execute_method(socket, request)
        end
      rescue exception
        socket.json(request.entity_tag, false, exception.message.to_s.gsub('"', '\''))
      end

      private def find_binding(id : String)
        binding = Registry.instance.registered_bindings.find { |b| b.id == id }
        raise Exception.new("Either the handler was not registered or the provided ID is incorrect") unless binding
        binding
      end

      private def execute_method(socket : Socket, request : Models::Request) : Void
        binding = find_binding(request.body["id"].to_s)

        response_channel = "response.#{Process.pid}.#{request.entity_tag}"

        message = Models::Message.from_json(request.body["sourceCode"].to_json)
        message.entity_tag = request.entity_tag
        message.class_name = binding.metadata.class_name
        message.response_channel = response_channel

        spawn do
          redis = Redis.new

          redis.subscribe response_channel do |on|
            on.message do |_channel, message|
              socket.send(message)

              begin
                redis.quit
              rescue TypeCastError
                next
              end
            end
          end

          redis.close
        end

        @pool.use do |redis|
          redis.publish(binding.id, message.to_json)
        end
      end

      private def disconnect(socket : Socket) : Void
        cleanup(socket)
        socket.close
      end

      private def cleanup(socket : Socket) : Void
        @subscription_manager.unsubscribe_all
        @sockets.delete(socket)
      end
    end
  end
end
