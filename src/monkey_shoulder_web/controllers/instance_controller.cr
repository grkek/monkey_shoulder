module MonkeyShoulderWeb
  module Controllers
    class InstanceController < Grip::Controllers::WebSocket
      alias Models = MonkeyShoulder::Models
      alias Registry = MonkeyShoulder::Registry

      property sockets : Array(Socket) = Array(Socket).new
      property handlers : Utilities::Synchronized(Array(String)) = Utilities::Synchronized(Array(String)).new

      def on_open(context : Context, socket : Socket) : Void
        @sockets.push(socket)

        Log.debug { "Client connected." }

        MonkeyShoulder::Registry.instance.registered_bindings.each do |binding|
          methods = [] of String

          methods.concat(binding.metadata.maintenance_methods.keys)
          methods.concat(binding.metadata.built_in_methods.keys)
          methods.concat(binding.metadata.external_methods.keys)

          methods.each do |method|
            handler = [binding.id, ".", binding.metadata.class_name.gsub("::", "."), ".", method].join

            if @handlers.includes?(handler)
              Log.debug { "Handler '#{handler}' is already registered." }
            else
              @handlers.push(handler)
              Log.debug { "Handler '#{handler}' has been registered." }

              spawn do
                redis = Redis.new

                redis.subscribe handler do |on|
                  on.message do |channel, message|
                    if message == "unsubscribeHandler"
                      @handlers.delete(handler)

                      Log.debug { "Handler '#{handler}' has been unregistered." }

                      # A bug with the library, when I want to quit the cycle it crashes with a TypeCastError,
                      # this is a little workaround.
                      begin
                        redis.quit
                      rescue TypeCastError
                        next
                      end
                    end

                    @sockets.each do |socket|
                      socket.send(message)
                    end
                  end
                end

                redis.close
              end
            end
          end
        end
      end

      def on_message(context : Context, socket : Socket, message : String) : Void
        begin
          message = JSON.parse(message).to_json
          request = Models::Request.from_json(message)

          begin
            case request.body.["instructionName"].to_s
            when "getBinding"
              bindings = Registry.instance.registered_bindings.reject do |binding|
                binding.id != request.body.["id"].to_s
              end

              raise Exception.new("Either the handler was not registered or the provided ID is incorrect") if bindings.size == 0

              binding = bindings.first

              @sockets.each do |socket|
                socket.json(request.entity_tag, {:ok, binding})
              end
            when "listBindings"
              @sockets.each do |socket|
                socket.json(request.entity_tag, {:ok, Registry.instance.registered_bindings})
              end
            when "executeMethod"
              redis = Redis.new

              bindings = Registry.instance.registered_bindings.reject do |binding|
                binding.id != request.body.["id"].to_s
              end

              raise Exception.new("Either the handler was not registered or the provided ID is incorrect") if bindings.size == 0

              binding = bindings.first

              message = Models::Message.from_json(request.body.["sourceCode"].to_json)
              message.entity_tag = request.entity_tag
              message.class_name = binding.metadata.class_name

              redis.publish(binding.id, message.to_json)

              redis.close
            end
          rescue exception
            @sockets.each do |socket|
              socket.json(request.entity_tag, {:error, exception.message.to_s.gsub("\"", "'")})
            end
          end
        rescue exception
          redis = Redis.new

          @handlers.each do |handler|
            redis.publish handler, "unsubscribeHandler"
          end

          redis.close
          @sockets.delete(socket)

          socket.close
        end
      end

      def on_ping(context : Context, socket : Socket, message : String) : Void
        # Executed when a client pings the server.
      end

      def on_pong(context : Context, socket : Socket, message : String) : Void
        # Executed when a server receives a pong.
      end

      def on_binary(context : Context, socket : Socket, binary : Bytes) : Void
        # Executed when a client sends a binary message.
      end

      def on_close(context : Context, socket : Socket, close_code : HTTP::WebSocket::CloseCode | Int?, message : String) : Void
        redis = Redis.new

        @handlers.each do |handler|
          redis.publish handler, "unsubscribeHandler"
        end

        redis.close
        @sockets.delete(socket)

        Log.debug { "Client disconnected." }
      end
    end
  end
end
