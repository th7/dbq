module DBQ
  class MemQueue
    NAMESPACE = 'DBQ'

    def initialize(queue_name)
      $redis ||= Redis.new
      @queue_name = queue_name
    end

    def push(data)
      redis.lpush(queue_key, data)
    end

    def pop
      redis.brpop(queue_key)
    end

    private

    def queue_key
      @queue_key ||= "#{NAMESPACE}:#{@queue_name}"
    end

    def redis
      $redis ||= Redis.new
    end
  end
end
