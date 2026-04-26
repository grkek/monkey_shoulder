module Utilities
  class SubscriptionManager
    def initialize(@pool : RedisPool, @sockets : Utilities::Synchronized(Array(HTTP::WebSocket::Protocol)))
      @handlers = Utilities::Synchronized(Array(String)).new
      @active = false
    end

    def start : Void
      @active = true
    end

    def subscribe(handler : String) : Bool
      return false if @handlers.includes?(handler)

      @handlers.push(handler)
      Log.debug { "Handler '#{handler}' has been registered." }

      spawn do
        redis = Redis.new

        redis.subscribe handler do |on|
          on.message do |channel, message|
            if message == "unsubscribeHandler"
              @handlers.delete(channel)
              Log.debug { "Handler '#{channel}' has been removed." }

              begin
                redis.quit
              rescue TypeCastError
                next
              end

              next
            end

            @sockets.each(&.send(message))
          end
        end

        redis.close
      end

      true
    end

    def unsubscribe_all : Void
      @pool.use do |redis|
        @handlers.each { |handler| redis.publish(handler, "unsubscribeHandler") }
      end
    end

    def includes?(handler : String) : Bool
      @handlers.includes?(handler)
    end
  end
end
