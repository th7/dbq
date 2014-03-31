module DBQ
  module Queue
    def self.included(receiver)
      receiver.after_rollback :return!
      receiver.extend ClassMethods
    end

    module ClassMethods
      def pop
        item = check_out_item
        item.try(:destroy)
        item.try(:data)
      end

      def push(data)
        create!(wrapped_data: { 'data' => data })
      end

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

    def release!
      self.update_attributes!(checked_out_at: Time.now)
    end

    def return!
      self.class.update(id, checked_out_at: nil)
    end

    def data
      wrapped_data['data'] if wrapped_data
    end
  end
end
