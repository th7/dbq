# module DBQ
#   class Queue
#     class << self
#       def inherited(subclass)
#         table_name = subclass.to_s.underscore.pluralize

#         subclass.instance_variable_set(:@model, Class.new(ActiveRecord::Base))
#         subclass.instance_variable_get(:@model).table_name = table_name
#       end
#     end

#     def initialize(queue_name)
#       @queue_name = queue_name
#       @mem_queue = DBQ::MemQueue.new(queue_name)
#       @model = DBQ::DbModel
#       @model.table_name = queue_name
#       @model.mem_queue = @mem_queue
#     end

#     def push(data)
#       @model.create!(queue_name: @queue_name, wrapped_data: {'data' => data})
#     end

#     def pop
#       wrapped_data = @mem_queue.pop
#       @model.find(wrapped_data['id']).destroy
#       wrapped_data['data']
#     end
#   end
# end
