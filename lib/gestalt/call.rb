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

    def display(total, formatador = Formatador.new)
      data = []
      data << format("[bold]%.1f%%[/]", (duration / total) * 100.0)
      if durations.length > 1
        data << "[light_black]#{durations.length}x[/]"
      end
      data << "[bold]#{action}[/]"
      data << "[light_black]#{location}[/]"
      condensed = []
      total = 0.0
      for call in children
        if condensed.last && condensed.last == call
          condensed.last.durations.concat(call.durations)
        else
          condensed << call
        end
        total += call.duration
      end
      formatador.display_line(data.join('  '))
      formatador.indent do
        for child in condensed
          child.display(total, formatador)
        end
      end
    end

    def duration
      durations.inject(0.0) {|memo, duration| duration + memo}
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