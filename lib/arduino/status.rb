require 'ostruct'
module FB
  # A status register that caches the state of the Arduino into a struct. Also
  # broadcasts changes that can be hooked into via the onchange() event.
  # bot.status[:X] # => Returns bot X coordinate.
  class Status
    # Map of informational status and default values for status within Arduino.
    DEFAULT_INFO = {X: 0, Y: 0, Z: 0, S: 10, BUSY: 1, LAST: 'none', PINS: {}}

    def initialize
      @changes = EM::Channel.new
      @info    = OpenStruct.new(DEFAULT_INFO)
    end

    def transaction(&blk)
      old = @info.to_h
      yield(@info)
      # Broadcast a diff between the old status and new status
      diff = (@info.to_h.to_a - old.to_a).to_h
      @changes << diff unless diff.empty?
    end

    def []=(register, value)
      transaction { @info[register.to_s.upcase] = value }
    end

    def [](value)
      @info[value.to_s.upcase] || :unknown
    end

    def to_h
      @info.to_h
    end

    def gcode_update(gcode)
      transaction do
        gcode.params.each { |p| @info[p.head] = p.tail }
      end
    end

    def onchange
      @changes.subscribe { |diff| yield(diff) }
    end

    def ready?
      self[:BUSY] == 0
    end

    def get_pin(num)
      @info.PINS[num] || :unknown
    end

    def set_pin(num, val)
      val = [true, 1, '1'].include?(val) ? :on : :off
      transaction { |info| info.PINS[num] = val }
    end

    def set_parameter(key, val)
      transaction do |info|
        info[Gcode::PARAMETER_DICTIONARY.fetch(key,
          "UNKNOWN_PARAMETER_#{key}".to_sym)] = val
      end
    end
  end
end
