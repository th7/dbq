module DBQ
  module Queue
    def self.included(receiver)
      receiver.include BasicQueue
      receiver.extend ClassMethods
    end

    module ClassMethods
      private

      def check_out_item
        thread = Thread.new do
          item = nil
          connection_pool.with_connection do
            transaction do
              item = where(checked_out_at: nil)
              .order(id: :asc).limit(1).lock(true).first
              item.try(:release!)
            end
          end
          item
        end
        thread.abort_on_exception = true
        thread.value
      end
    end
  end
end
