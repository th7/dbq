module DBQ
  class Queue
    def self.inherited(subclass)
      subclass.instance_variable_set(:@model, Class.new(ActiveRecord::Base))
      table_name = subclass.to_s.underscore.pluralize
      subclass.instance_variable_get(:@model).table_name = table_name
    end

    def initialize
      raise DBQ::Error, "#{self.class} must be subclassed" if self.class == Queue
    end
  end
end
