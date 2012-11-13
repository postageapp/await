# await

This implements the await/defer pattern in Ruby using fibers within the
EventMachine environment.

In general terms, `await` is used to define a group of operations that must
be completed before processing can continue, and `defer` is used to define
these individual operations.

This can be used to simplify otherwise complicated callback structures where
a number of operations can be performed in parallel. Further complexity arises
when some of these operations have optional steps.

## Examples

In order to execute properly, an `await` call must be created within a fiber
that can yield. Since the root fiber cannot yield, a secondary fiber must be
created.

A very simple example shows how a number of timers can be set to simulate
some long-running asynchronous operations:

```ruby
require 'await'
require 'eventmachine'

EventMachine.run do
  Fiber.new do
    include Await

    now = Time.now
    await do
      EventMachine::Timer.new(5, &defer)
      EventMachine::Timer.new(2, &defer)
      EventMachine::Timer.new(3, &defer)
    end

    puts "Took %.1fs to complete" % (Time.now - now).to_f

    EventMachine.stop_event_loop
  end.resume
end
```

In the end you should see that it took only as long as the longest timer.

In its default state, `defer` is simply used as a trigger. It can also wrap
around a callback block to add additional functionality:

```ruby
require 'await'
require 'eventmachine'

EventMachine.run do
  Fiber.new do
    include Await
    
    now = Time.now
    await do
      trigger = defer do |x, y|
        puts "Received arguments: #{[ x, y ].inspect}"
      end
      
      EventMachine::Timer.new(4) do
        trigger.call(1, '2')
      end
      
      EventMachine::Timer.new(
        3,
        &defer do
          EventMachine::Timer.new(
            2,
            &defer
          )
        end
      )
    end

    puts "Took %.1fs to complete" % (Time.now - now).to_f

    EventMachine.stop_event_loop
  end.resume
end
```

Since the `defer` method returns a standard Proc callback, it is possible to
pass it through as a callback method or to trigger it at an arbitrary time
with `call`.

More examples of callback structures are available in the various unit tests.

## Troubleshooting

If the secondary fiber has not been created you will see errors like:

    FiberError: can't yield from root fiber

Keep in mind that unless a `defer` call is made within a callback then the
operation is considered completed. If an additional asynchronous operation
must be performed before it is complete, be sure to wrap any and all of these
calls with `defer` as well to tag and track them properly.

## Copyright

Copyright (c) 2012 Scott Tadman, The Working Group Inc.
See LICENSE.txt for further details.

