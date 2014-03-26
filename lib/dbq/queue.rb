module DBQ
  class Queue
    class << self
      def inherited(subclass)
        table_name = subclass.to_s.underscore.pluralize

        subclass.instance_variable_set(:@model, Class.new(ActiveRecord::Base))
        subclass.instance_variable_get(:@model).table_name = table_name

        subclass.instance_variable_set(:@mem_queue, DBQ::MemQueue.new(table_name))
      end
    end

    def initialize(queue_name)
      @queue_name = queue_name
      @mem_queue = DBQ::MemQueue.new(queue_name)
      @model = Class.new(ActiveRecord::Base)
      @model.table_name = queue_name
    end

    def push(data)
        durable_item = @model.create!(queue_name: @queue_name, wrapped_data: {'data' => data})
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
end
