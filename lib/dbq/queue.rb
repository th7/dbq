module DBQ
  class Queue
    PUSH = 'PUSH'

    class << self
      attr_accessor :table_name

      def inherited(subclass)
        table_name = subclass.to_s.underscore.pluralize

        subclass.instance_variable_set(:@model, Class.new(ActiveRecord::Base))
        subclass.instance_variable_get(:@model).table_name = table_name

        subclass.instance_variable_set(:@mem_queue, DBQ::MemQueue.new(table_name))
      end

      def push(data)
        next_val = query_next_val
        wrapped_data = { 'id' => next_val, 'data' => data }
        durable_item = @model.create!(item_id: next_val, action: PUSH, data: wrapped_data)
        @mem_queue.push(wrapped_data)
      end

      private

      def query_next_val
        @model.connection.execute("select nextval('#{@model.table_name}_item_id_sequence')").first['nextval']
      end
    end

    def initialize
      raise DBQ::Error, "#{self.class} must be subclassed" if self.class == Queue
    end
  end
end
