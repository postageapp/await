require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'await'

require 'eventmachine'

class Test::Unit::TestCase
  def em
    EventMachine.run do
      Fiber.new do
        yield
      end.resume
      
      EventMachine.stop_event_loop
    end
  end
end
