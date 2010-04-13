require File.join(File.dirname(__FILE__), 'gestalt', 'call')

require 'rubygems'
require 'formatador'

class Gestalt

  attr_accessor :calls

  def initialize
    @calls = []
    @stack = []
    @totals = {}
  end

  def display_calls
    Formatador.display_line
    for call in @calls
      call.display
    end
    Formatador.display_line
  end

  def display_profile
    for call in calls
      parse_call(call)
    end

    table = []
    for key, value in @totals
      table << {
        '#' => value[:occurances],
        :action => key,
        :duration => format("%.6f", value[:duration])
      }
    end
    table = table.sort {|x,y| y[:duration] <=> x[:duration]}

    Formatador.display_line
    Formatador.display_table(table)
    Formatador.display_line
  end

  def run(&block)
    Kernel.set_trace_func(
      lambda do |event, file, line, id, binding, classname|
        case event
        when 'call', 'c-call'
          # p "call #{classname}##{id}"
          call = Gestalt::Call.new(
            :action     => "#{classname}##{id}",
            :location   => "#{File.expand_path(file)}:#{line}"
          )
          unless @stack.empty?
            @stack.last.children.push(call)
          end
          @stack.push(call)
        when 'return', 'c-return'
          # p "return #{classname}##{id}"
          unless @stack.empty? # we get one of these when we set the trace_func
            call = @stack.pop
            call.finish
            if @stack.empty?
              @calls << call
            end
          end
        end
      end
    )
    yield
    Kernel.set_trace_func(nil)
    @stack.pop # pop Kernel#set_trace_func(nil)
    unless @stack.empty?
      @stack.last.children.pop # pop Kernel#set_trace_func(nil)
    end
    while call = @stack.pop # leftovers, not sure why...
      call.finish
      if @stack.empty?
        @calls << call
      end
    end
  end

  def self.profile(&block)
    gestalt = new
    gestalt.run(&block)
    gestalt.display_profile
  end

  def self.trace(&block)
    gestalt = new
    gestalt.run(&block)
    gestalt.display_calls
  end

  private
  def parse_call(call)
    @totals[call.action] ||= { :occurances => 0, :duration => 0 }
    @totals[call.action][:occurances] += 1
    @totals[call.action][:duration] += call.duration
    for child in call.children
      parse_call(child)
    end
  end

end

if __FILE__ == $0

  class Slow

    def single
      'slow' << 'er'
    end

    def double
      single
      single
    end

  end

  Gestalt.trace do

    slow = Slow.new
    slow.single

  end

  Gestalt.profile do

    slow = Slow.new
    slow.double

  end

end
