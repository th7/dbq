# DBQ

DuraBle Queues

## Installation

Add this line to your application's Gemfile:

    gem 'dbq'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dbq

## Usage

### Queue

Create a table with the following column and index:

* checked_out_at (timestamp, indexed)

Add any data columns you want.

Create an ActiveRecord model for your table and include DBQ:Queue:

```
class MyQueue < ActiveRecord::Base
  include DBQ::Queue
end
```

Push some data onto your queue (push is, for now, synonymous with create):

```MyQueue.push(my_data: 'some data')```

Pop your data back off your queue:

```MyQueue.pop.my_data #=> 'some data'```

### OrderedQueue

Create a table with the following columns:

* checked_out_at (timestamp, indexed)
* my_ordered_attr1 (any type, indexed)
* my_ordered_attr2 (any type, indexed)
* ...

Again, add any data fields you want.

Create an ActiveRecord model for your table and include DBQ:OrderedQueue. Be sure to specify which fields should enforce order (detailed explanation below). I'd recommend validating presence on those fields as well.

```
class MyOrderedQueue < ActiveRecord::Base
  include DBQ::OrderedQueue
  validates :my_ordered_attr1, :my_ordered_attr2, presence: true
  enforces_order_on :my_ordered_attr1, :my_ordered_attr2
end
```

Push some data onto your queue:

```MyOrderedQueue.push(my_ordered_attr1: 'attr1', my_ordered_attr2: 'attr2', my_data 'some data')```

Pop your data back off your queue:

```MyOrderedQueue.pop.my_data #=> 'some data'```

What's the point!?

DBQ::OrderedQueue will enforce processing order for records which have matching ordered_attrs. If a 'sibling' record is checked out, its siblings will not come off the queue until the first sibling's pop is committed. Here's an example:

Two sibling records exist (using one ordered attr for brevity):

```
MyOrderedQueue.push(ordered: 1, data: 'first item')
MyOrderedQueue.push(ordered: 1, data: 'second item')
```

One process/thread pops the first item (in a transaction!):

```do_some_slow_transactional_work(MyOrderedQueue.pop) ```

Before the first transaction commits, DBQ::OrderedQueue restricts access to the sibling item:

```MyOrderedQueue.pop #=> nil```

After the first transaction commits, DBQ::OrderedQueue allows the second item to be popped:

```MyOrderedQueue.pop.data #=> 'second item'```

If the first transaction rolls back, the first item will come off the queue again:

```MyOrderedQueue.pop.data #=> 'first item'```

If the process gets killed or the OS crashes while the first item is checked out, you may need to manually check the item back in by setting checked_out_at to null.


## Contributing

1. Fork it ( http://github.com/<my-github-username>/dbq/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
