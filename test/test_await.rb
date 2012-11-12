require File.expand_path('helper', File.dirname(__FILE__))

class TestAwait < Test::Unit::TestCase
  include Await
  
  def test_module
    assert_equal true, Await.respond_to?(:await)
    assert_equal true, Await.respond_to?(:defer)
  end
  
  def test_await_default_state
    executed = false

    em do
      await do
        executed = true
      end
    end

    assert_equal true, executed
  end
  
  def test_await_single_defer
    triggered = false

    em do
      await do
        defer do
          triggered = true
        end.call
      end
    end

    assert_equal true, triggered
  end

  def test_await_delayed_defer
    triggered = false
    defer_block = nil

    em do
      await do
        defer_block = defer do
          triggered = true
        end
      end
    end
    
    assert defer_block
    assert_equal false, triggered

    assert defer_block
    defer_block.call
    
    assert_equal true, triggered
  end

  def test_await_delayed_defer_fiber
    triggered = false
    trigger_fiber = Fiber.new do
      Fiber.yield
      triggered = true
    end

    em do
      await do
        defer(trigger_fiber)
      end
    end

    assert_equal false, triggered

    assert trigger_fiber
    trigger_fiber.resume
    
    assert_equal true, triggered
  end
  
  def test_await_delayed_defer_callback
    triggered = false
    trigger_callback = nil

    em do
      await do
        defer do |callback|
          trigger_callback = callback
        end
      end

      triggered = true
    end
    
    assert_equal false, triggered

    assert trigger_callback
    trigger_callback.call
    
    assert_equal true, triggered
  end

  def test_await_multiple_defer
    triggered = false
    triggers = [ ]
    count = 10
    
    em do
      await do
        count.times do
          triggers << defer
        end
      end
      
      triggered = true
    end
    
    assert_equal false, triggered

    while (triggers.length > 1)
      triggers.pop.call
    end

    assert_equal false, triggered

    triggers.pop.call
    
    assert_equal true, triggered
  end

  def test_await_chained_defer
    triggered = false
    trigger_block_outer = nil
    trigger_block_inner = nil
    
    em do
      await do
        trigger_block_outer = defer do
          trigger_block_inner = defer do
          end
        end
      end

      triggered = true
    end
    
    assert_equal false, triggered
    
    assert trigger_block_outer
    trigger_block_outer.call

    assert_equal false, triggered

    assert trigger_block_inner
    trigger_block_inner.call
    
    assert_equal true, triggered
  end
end
