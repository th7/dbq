module DBQ
  class MemQueue
    NAMESPACE = 'DBQ'

    def initialize(queue_name)
      $redis ||= Redis.new
      @queue_name = queue_name
    end

    def push(data)
      redis.lpush(queue_key, data.to_json)
    end

    def pop
      JSON.parse(redis.brpop(queue_key).last)
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
