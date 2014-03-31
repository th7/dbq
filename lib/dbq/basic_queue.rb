module DBQ
  module BasicQueue
    def self.included(receiver)
      receiver.after_rollback :return!
      receiver.extend ClassMethods
    end

    module ClassMethods
      def pop
        item = check_out_item
        item.try(:destroy)
        item
      end

      def push(opts)
        create!(opts)
      end
    end

    def release!
      self.update_attributes(checked_out_at: Time.now)
    end

    def return!
      # necessary if we were frozen by a rolled back destroy call
      self.class.update(id, checked_out_at: nil)
    end

    def data=(new_data)
      self.wrapped_data ||= {}
      wrapped_data['data'] = new_data
    end

    def data
      wrapped_data['data'] if wrapped_data
    end
  end
end
