require 'thread'
require 'fiber'

module Await
  module ThreadExtension
    def await
      # Capture the current context to properly chain this await in
      parent = @deferred
      
      deferred = @deferred = {
        :fiber => Fiber.current
      }

      if (parent)
        parent[deferred] = true
      end

      yield if (block_given?)
      
      # So long as there is at least one outstanding defer block, this fiber
      # must continue to yield.
      while (deferred.size > 1)
        fiber, trigger, block, args = Fiber.yield
        
        deferred.delete(trigger)

        if (block)
          # Always introduce the correct context here by setting the
          # thread-local @deferred instance variable.
          @deferred = deferred
          block.call(*args)
        end
      end
      
      # If this was part of an existing await call then remove the current
      # await operation from the list of pending entries.
      if (parent)
        if (deferred[:fiber] == Fiber.current)
          parent.delete(deferred)
        else
          parent[:fiber].transfer([ Fiber.current, deferred ])
        end
      end

      true
    end
    
    def defer(&block)
      deferred = @deferred
      
      trigger = lambda do |*args|
        if (deferred[:fiber] == Fiber.current)
          # Within the same fiber, remove this from the pending list
          deferred.delete(trigger)

          block.call(*args)
        else
          # If this is executing in a different fiber, transfer control back
          # to the original fiber for reasons of continuity.
          deferred[:fiber].transfer([ Fiber.current, trigger, block, args ])
        end
      end
      
      deferred[trigger] = true
      
      trigger
    end
  end

  # Define a group of operations that need to be completed before execution
  # will continue. The current fiber is suspended until all of the defer
  # operations have completed.
  def await(&block)
    Thread.current.await(&block)
  end

  # Used to define a deferred operation. The return value is a Proc that can
  # be passed through as a callback argument to any method. Once the callback
  # has been executed it is considered complete unless within that callback
  # other defer or await calls are made.
  def defer(*args, &block)
    Thread.current.defer(*args, &block)
  end
  
  # Import all mixin methods here as module methods so they can be used
  # directly without requiring an import.
  extend self
end

# == Hook Installation ======================================================

class Thread
  include Await::ThreadExtension
end
