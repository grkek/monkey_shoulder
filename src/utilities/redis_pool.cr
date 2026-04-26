module Utilities
  class RedisPool
    DEFAULT_SIZE = 4

    def initialize(size : Int32 = DEFAULT_SIZE)
      @pool = Channel(Redis).new(size)
      size.times { @pool.send(Redis.new) }
    end

    def use(& : Redis -> T) : T forall T
      redis = @pool.receive
      begin
        yield redis
      ensure
        @pool.send(redis)
      end
    end
  end
end
