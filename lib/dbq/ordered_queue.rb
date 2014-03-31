module DBQ
  module OrderedQueue
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

      def enforces_order_on(*attrs)
        @check_out_query = nil
        @enforce_order_on = attrs
        # check indexes and warn if they do not exist?
      end

      private

      def check_out_item
        # a separate thread means a separate connection/transaction/commit
        thread = Thread.new do
          item = nil
          connection_pool.with_connection do
            transaction do
              item = find_by_sql(check_out_query).first
              item.try(:release!)
            end
          end
          item
        end
        thread.abort_on_exception = true
        thread.value
      end

      def check_out_query
        @check_out_query ||= <<-SQL
          select * from #{table_name}
          where #{table_name}.id not in (
            select #{table_name}.id
            from #{table_name}
            inner join #{table_name} as self_join on
              #{join_clause}
            where self_join.checked_out_at is not null
          )
          and #{table_name}.checked_out_at is null
          order by #{table_name}.id asc
          limit 1
          for update;
        SQL
      end

      # possibly add check/warn for recommended indexes
      # def indexes
      #   connection.indexes(self)
      # end

      def join_clause
        @enforce_order_on.inject([]) do |items, ordered_attr|
          items << "#{table_name}.#{ordered_attr} = self_join.#{ordered_attr}"
          items
        end.join(' and ')
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
