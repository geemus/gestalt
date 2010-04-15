class Gestalt

  class Call

    attr_accessor :children, :durations
    attr_accessor :action, :finished_at, :location, :started_at

    def initialize(attributes = {})
      @started_at = Time.now.to_f
      for key, value in attributes
        send("#{key}=", value)
      end
      @children ||= []
      @durations ||= []
    end

    def ==(other)
      action == other.action && location == other.location && children == other.children
    end

    def display(formatador = Formatador.new)
      data = []
      data << format("[light_black]x%0.4d[/]", durations.length)
      data << format("%.6f", duration)
      data << "[bold]#{action}[/]"
      data << "[light_black]#{location}[/]"
      condensed = []
      for child in children
        if condensed.last && condensed.last == child
          condensed.last.durations.concat(child.durations)
        else
          condensed << child
        end
      end
      formatador.display_line(data.join('  '))
      formatador.indent do
        for child in condensed
          child.display(formatador)
        end
      end
    end

    def duration
      sum = durations.inject(0) {|memo, duration| duration + memo}
      sum / durations.length
    end

    def durations
      if @durations.empty?
        @durations << finished_at - started_at
      end
      @durations
    end

    def finish
      @finished_at ||= Time.now.to_f
      for child in children
        child.finish
      end
    end

  end

end