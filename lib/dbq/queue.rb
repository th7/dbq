module DBQ
  class Queue
    class << self
      attr_accessor :table_name

      def inherited(subclass)
        table_name = subclass.to_s.underscore.pluralize

        subclass.instance_variable_set(:@model, Class.new(ActiveRecord::Base))
        subclass.instance_variable_get(:@model).table_name = table_name

        subclass.instance_variable_set(:@mem_queue, DBQ::MemQueue.new(table_name))
      end

      def push(data)
        durable_item = @model.create!(wrapped_data: {'data' => data})
        wrapped_data = { 'id' => durable_item.id, 'data' => data }

        # move this to an after_commit hook?
        @mem_queue.push(wrapped_data)
      end

      def pop
        raise LocalJumpError, 'no block given' unless block_given?

        begin
          wrapped_data = @mem_queue.pop
          yield wrapped_data['data']
        rescue Exception => e
          @mem_queue.push(wrapped_data)
          raise e
        end

        @model.find(wrapped_data['id']).destroy
      end
    end

    def initialize
      raise DBQ::Error, "Do not initialize. Subclass and use SubClass.push/pop."
    end
  end
end
