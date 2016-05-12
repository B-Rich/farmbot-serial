module FB
  # Writes GCode to the serial line. Creates messages the travel from the PI to
  # the ARDUINO.
  class OutgoingHandler
    attr_reader :bot

    def initialize(bot)
      @bot = bot
    end

    def emergency_stop(*)
      # This message is special- it is the only method that bypasses the queue.
      bot.outbound_queue = []  # Dump pending commands.
      bot.serial_port.puts "E" # Don't queue this one- write to serial line.
      bot.status[:last] = :emergency_stop
    end

    def move_relative(x: 0, y: 0, z: 0, s: 100)
      write do
        # REMEBER: YOU NEVER WANT TO MUTATE VARIABLES HERE. If you mutate vars
        # in a block, it will result in the return value getting incremented
        # every time the value is read. For this reason, we use ||= and not =.
        x1 ||= [(bot.current_position.x + (x || 0)), 0].max
        y1 ||= [(bot.current_position.y + (y || 0)), 0].max
        z1 ||= (bot.current_position.z + (z || 0)) || 0

        "G00 X#{x1} Y#{y1} Z#{z1}"
      end
    end

    def move_absolute(x: 0, y: 0, z: 0, s: 100)
      x = [x.to_i, 0].max
      y = [y.to_i, 0].max
      z = z.to_i || 0
      write { "G00 X#{x} Y#{y} Z#{z}" }
    end

    def home_x
      write { "F11" }
    end

    def home_y
      write { "F12" }
    end

    def home_z
      write { "F13" }
    end

    def home_all
      write { "G28" }
    end

    # Parameters are settings, which is not to be confused with status.
    def read_parameter(num)
      write { "F21 P#{num}" }
    end

    def read_pin(pin, mode = :digital)
      unless [:analog, :digital].include?(mode)
        raise "Mode must be :analog or :digital"
      end
      write { "F42 P#{pin} M#{(mode == :digital) ? 0 : 1}" }
    end

    def read_status(num)
      write { "F31 P#{num}" }
    end

    def write_parameter(num, val)
      write { "F22 P#{num} V#{val}" }
      key = Gcode::PARAMETER_DICTIONARY.fetch(num, "UNKNOWN_PARAMETER_#{num}")
      bot.status.transaction { |i| i[key] = val }
    end

    def write_pin(pin:, value:, mode:)
      write { "F41 P#{pin} V#{value} M#{mode}" }
      bot.status.set_pin(pin, value)
    end

    def set_max_speed(axis, value)
      set_paramater_value(axis, value, 71, 72, 73)
    end

    def set_acceleration(axis, value)
      set_paramater_value(axis, value, 41, 42, 43)
    end

    def set_timeout(axis, value)
      set_paramater_value(axis, value, 11, 12, 13)
    end

    def set_steps_per_mm(axis, value)
      raise "The Farmbot Arduino does not currently store a value for steps "\
            "per mm. Keep track of this information at the application level"
    end

    def set_end_inversion(axis, value)
      set_paramater_value(axis, bool_to_int(value), 21, 22, 23)
    end

    def set_motor_inversion(axis, value)
      set_paramater_value(axis, bool_to_int(value), 31, 32, 33)
    end

    def set_negative_coordinates(axis, value)
      raise "Not yet implemented. TODO: This method."
    end

    def wait(ms)
      if (ms.is_a?(Integer))
        write { "F44 P13 T#{ ms } M0 v1" }
      else
        raise BadNumericValue, "Expected sleep command to receive an integer."
      end
    end

  private

    class InvalidAxisEntry < Exception; end
    class BadBooleanValue < Exception; end
    class BadNumericValue < Exception; end
    # The Arduino uses a different parameter number for each axis. Ex:
    # MOVEMENT_TIMEOUT_X is 11 and MOVEMENT_TIMEOUT_Y is 12. To keep things dry,
    # this method will lookup the correct paramater numer based on the axis
    # provided and the three options available (if_x, if_y, if_z)
    def set_paramater_value(axis, value, if_x, if_y, if_z)
      param_num = { 'x' => if_x, 'y' => if_y, 'z' => if_z }[axis.to_s.downcase]
      raise InvalidAxisEntry, "You entered an invalid axis" unless param_num
      write { "F22 P#{param_num} V#{value.to_s}" }
    end

    def write(&blk)
      bot.write(FB::Gcode.new(&blk))
    end

    def bool_to_int(value)
      case value
      when true, 'true', 1, '1'   then 1
      when false, 'false', 0, '0' then 0
      else
        raise BadBooleanValue, "Farmbot expected a boolean value in one of "\
                               "the following forms: [true, false, 1, 0]"
      end
    end
  end
end
