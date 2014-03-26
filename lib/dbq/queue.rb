module DBQ
  class Queue
    def initialize
      raise DBQ::Error, "#{self.class} must be subclassed" if self.class == Queue
      @model = Class.new(ActiveRecord::Base)
      @model.table_name = self.class.to_s.underscore
    end
  end
end
