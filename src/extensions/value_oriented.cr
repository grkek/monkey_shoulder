class Redis
  module CommandExecution
    module ValueOriented
      # Executes a Redis command that has no relevant response.
      # This is an internal method.
      def void_command(request : Request) : Nil
        command(request)
        nil
      end
    end
  end
end
