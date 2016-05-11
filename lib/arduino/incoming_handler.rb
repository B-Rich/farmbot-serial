module FB
  # Handles Gcode that was sent by the ARDUINO to the RASPBERRY PI.
  class IncomingHandler
    attr_reader :bot

    def initialize(bot)
      @bot = bot
    end

    def execute(gcode)
      name = gcode.name
      if respond_to?(name)
        self.send(name, gcode)
      else
        bot.log "#{gcode.name} is a valid GCode, but no input handler method exists"
      end
    end

    def unknown(gcode)
      bot.log "Don't know how to parse incoming GCode: #{gcode}"
    end

    # Called when the Ardunio is reporting the status of a parameter.
    def report_parameter_value(gcode)
      bot.status.set_parameter(gcode.value_of(:P), gcode.value_of(:V))
    end

    def report_pin_value(gcode)
      bot.status.set_pin(gcode.value_of(:P), gcode.value_of(:V))
    end

    def report_end_stops(gcode)
      bot.status.gcode_update(gcode)
    end

    def report_current_position(gcode)
      bot.status.gcode_update(gcode)
    end

    def report_status_value(gcode)
      # TODO: Verfiy the accuracy of this code. CC: @timevww
      bot.status.set(gcode.value_of(:P), gcode.value_of(:V))
    end

    def received(gcode)
      bot.status[:busy] = 1
    end

    def idle(gcode)
      bot.status[:busy] = 0
    end

    def done(gcode)
      bot.status[:busy] = 0
    end

    def busy(gcode)
      bot.status[:busy] = 1
    end

    def report_software_version(gcode)
      nil # Don't need the info right now.
    end

    def debug_message(*)
      nil # Squelch debug messages.
    end
  end
end
