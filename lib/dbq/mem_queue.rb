module DBQ
  class MemQueue
    NAMESPACE = 'DBQ'

    def initialize(queue_name)
      raise DBQ::Error, 'Must specify a queue name' if queue_name.nil? || queue_name.empty?
      @queue_name = queue_name
    end

    def push(data)
      redis.lpush(queue_key, data.to_json)
    end

    def pop
      JSON.parse(redis.brpop(queue_key).last)
    end

    def length
      redis.llen(queue_key)
    end
    alias :count :length

    private

    def queue_key
      @queue_key ||= "#{NAMESPACE}:#{@queue_name}"
    end

    def redis
      $redis ||= Redis.new
    end
  end
end
