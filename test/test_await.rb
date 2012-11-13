require File.expand_path('helper', File.dirname(__FILE__))

class TestAwait < Test::Unit::TestCase
  include Await
  
  def test_module
    assert_equal true, Await.respond_to?(:await)
    assert_equal true, Await.respond_to?(:defer)
  end
  
  def test_await_default_state
    triggered = false

    em do
      await do
        triggered = true
      end
    end

    assert_equal true, triggered
  end
  
  def test_await_block_object
    trigger = nil
    exited = false
    
    em do
      await do
        trigger = defer
      end
    
      exited = true
    end
    
    assert_equal false, exited

    trigger.call

    assert_equal true, exited
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

  def test_await_nested
    triggered = 0

    em do
      await do
        defer do
          await do
            defer do
              triggered += 1
            end.call
          end

          assert_equal 1, triggered

          await do
            defer do
              triggered += 2
            end.call
          end
        end.call
      end

      assert_equal 3, triggered
    end

    assert_equal 3, triggered
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

  def test_await_delayed_double_defer
    outer_trigger = nil
    inner_trigger = nil
    triggered = false
    continued = false
    
    em do
      await do
        outer_trigger = defer do
          inner_trigger = defer do
            triggered = true
          end
        end
      end
      
      continued = true
    end

    assert_equal false, triggered
    assert_equal false, continued

    assert !inner_trigger

    outer_trigger.call
    
    assert_equal false, triggered
    assert_equal false, continued

    assert inner_trigger
    
    inner_trigger.call
    
    assert_equal true, triggered
    assert_equal true, continued
  end

  def test_await_nested_delayed_trigger
    outer_trigger = nil
    inner_trigger = nil
    triggered = false
    continued = false
    
    em do
      await do
        outer_trigger = defer do
          await do
            inner_trigger = defer do
              triggered = true
            end
          end
        end
      end
      
      continued = true
    end

    assert_equal false, triggered
    assert_equal false, continued

    assert !inner_trigger

    outer_trigger.call
    
    assert_equal false, triggered
    assert_equal false, continued

    assert inner_trigger
    
    inner_trigger.call
    
    assert_equal true, triggered
    assert_equal true, continued
  end
  
  def test_await_delayed_defer_callback
    triggered = false
    trigger_callback = nil
    results = nil

    em do
      await do
        trigger_callback = defer do |*args|
          results = args
        end
      end

      triggered = true
    end
    
    assert_equal false, triggered

    assert trigger_callback
    trigger_callback.call(1, :two, '3')
    
    assert_equal true, triggered
    assert_equal [ 1, :two, '3' ], results
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
