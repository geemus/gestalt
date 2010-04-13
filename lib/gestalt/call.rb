class Gestalt

  class Call

    attr_accessor :children
    attr_accessor :action, :finished_at, :location, :started_at

    def initialize(attributes = {})
      @started_at = Time.now.to_f
      for key, value in attributes
        send("#{key}=", value)
      end
      @children ||= []
    end

    def display(formatador = Formatador.new)
      formatador.display_line("#{format("%.6f",duration)}  [bold]#{action}[/]  [light_black]#{location}[/]")
      formatador.indent do
        for child in children
          child.display(formatador)
        end
      end
    end

    def duration
      finished_at - started_at
    end

    def finish
      @finished_at ||= Time.now.to_f
      for child in children
        child.finish
      end
    end

  end

end