require 'fiber'

module Await
  # Declares an await group where any defer operations within this block will
  # need to be completed before the await block will resume.
  def await
    if (@__await)
      @__await_stack ||= [ ]
      @__await_stack << @__await
    end

    _await = @__await = {
      :fiber => Fiber.current
    }

    yield if (block_given?)

    if (@__await_stack)
      @__await = @__await_stack.pop
    end

    while (_await.length > 1)
      Fiber.yield
    end
    
    true
  end

  # Declares a defer operation. If a block is passed in, then a trigger proc
  # is passed to the block that should be executed when the operation is
  # complete. If a fiber is passed in as an argument, then the defer will
  # be considered complete when the fiber finishes.
  def defer(fiber = nil)
    _await = @__await

    case (fiber)
    when Fiber
      _await[fiber] = true

      fiber.resume

      _await.delete(fiber)

      unless (Fiber.current == _await[:fiber])
        _await[:fiber].resume
      end
    else
      block = Proc.new if (block_given?)
      
      case (block ? block.arity : 0)
      when 1
        trigger = lambda {
          _await.delete(trigger)

          unless (Fiber.current == _await[:fiber])
            _await[:fiber].resume
          end
        }

        block.call(trigger)

        _await[trigger] = true

        trigger
      else
        trigger = lambda {
          block.call if (block_given?)
          
          _await.delete(trigger)

          unless (Fiber.current == _await[:fiber])
            _await[:fiber].resume
          end
        }

        _await[trigger] = true

        trigger
      end
    end
  end
  
  # Import all mixin methods here as module methods so they can be used
  # directly without requiring an import.
  extend self
end
