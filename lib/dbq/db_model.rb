module DBQ
  class DbModel < ActiveRecord::Base
    class << self
      def push(data)
        create!(wrapped_data: {'data' => data})
      end

      def pop
        wrapped_data = mem_queue.pop
        find(wrapped_data['id']).destroy
        wrapped_data['data']
      end

      def mem_queue
        @mem_queue ||= DBQ::MemQueue.new(table_name)
      end
    end

    after_commit :mem_push, on: :create
    after_rollback :mem_push, on: :destroy

    def mem_push
      mem_queue.push('id' => id, 'data' => wrapped_data['data'])
    end

    private

    def mem_queue
      self.class.mem_queue
    end
  end
end
