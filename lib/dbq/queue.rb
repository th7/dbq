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
    end

    def initialize
      raise DBQ::Error, "#{self.class} must be subclassed" if self.class == Queue
    end
  end
end
