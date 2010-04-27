require File.join(File.dirname(__FILE__), 'gestalt', 'call')

require 'rubygems'
require 'formatador'

class Gestalt

  VERSION = '0.0.2'

  attr_accessor :calls, :formatador

  def initialize
    @calls = []
    @stack = []
    @totals = {}
  end

  def display_calls
    formatador.display_line
    condensed = []
    total = 0.0
    for call in @calls
      if condensed.last && condensed.last == call
        condensed.last.durations.concat(call.durations)
      else
        condensed << call
      end
      total += call.duration
    end
    for call in condensed
      call.display(total, formatador)
    end
    formatador.display_line
  end

  def display_profile
    for call in calls
      parse_call(call)
    end

    table = []
    for key, value in @totals
      table << {
        :action => "#{value[:occurances]}x #{key}",
        :duration => format("%.6f", value[:duration])
      }
    end
    table = table.sort {|x,y| y[:duration] <=> x[:duration]}

    formatador.display_line
    formatador.display_table(table)
    formatador.display_line
  end

  def formatador
    @formatador ||= Formatador.new
  end

  def run(&block)
    Kernel.set_trace_func(
      lambda do |event, file, line, id, binding, classname|
        case event
        when 'call', 'c-call'
          # p "call #{classname}##{id}"
          call = Gestalt::Call.new(
            :action     => "#{classname}##{id}",
            :location   => "#{file}:#{line}"
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
    rescue StandardError, Interrupt
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

  Gestalt.trace do
    raise StandardError.new('exception')
    slow = Slow.new
    slow.slowing
  end

  class Slow

    def slow(est = false)
      unless est
        'slow' << 'e' << 'r'
      else
        'slow' << 'e' << 's' << 't'
      end
    end

    def slowing
      slow
      slow
      slow(true)
    end

  end

  Gestalt.trace do

    slow = Slow.new
    slow.slowing

  end

  Gestalt.profile do

    slow = Slow.new
    slow.slowing

  end

end
