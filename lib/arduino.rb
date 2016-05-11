require 'serialport'
require_relative 'default_serial_port'
require_relative 'arduino/incoming_handler'
require_relative 'arduino/outgoing_handler'
require_relative 'arduino/event_machine'
require_relative 'arduino/status'
module FB
  # Software abstraction layer for the Arduino's serial interface. Translates
  # Ruby method calls into serial commands.
  class Arduino
    Position = Struct.new(:x, :y, :z)

    attr_accessor :serial_port, :logger, :commands, :inbound_queue, :status,
      :inputs, :outbound_queue

    # Initialize and provide a serial object, as well as an IO object to send
    # log messages to. Default SerialPort is DefaultSerialPort. Default logger
    # is STDOUT
    def initialize(serial_port: DefaultSerialPort.new, logger: STDOUT)
      @outbound_queue = [] # Pi -> Arduino Gcode
      @inbound_queue  = EM::Channel.new # Pi <- Arduino

      @serial_port = serial_port
      @logger      = logger
      @commands    = FB::OutgoingHandler.new(self)
      @inputs      = FB::IncomingHandler.new(self)
      @status      = FB::Status.new

      start_event_listeners
    end

    # Log to screen/file/IO stream
    def log(message)
      logger.puts(message)
    end

    # Send outgoing test to arduino from pi
    def write(gcode)
      @outbound_queue.unshift gcode
    end

    def onchange(&blk)
      @onchange = blk
    end

    # Handle incoming text from arduino into pi
    def onmessage(&blk)
      @onmessage = blk
    end

    def onclose(&blk)
      @onclose = blk
    end

    # Handle loss of serial connection
    def disconnect
      log "Connection to device lost"
      @onclose.call if @onclose
    end

    def current_position
      Position.new(status[:X], status[:Y], status[:Z])
    end

    def next_cmd
      outbound_queue.first
    end

    def maybe_execute_command # This method smells procedural. Refactor?
      sleep 0.08 # Throttle CPU
      return unless can_execute?
      gcode = @outbound_queue.pop
      gcode.is_a?(FB::Gcode) ? execute_now(gcode) : reject_gcode(gcode)
    end

    def can_execute? # If the device is ready and commands are in the queue
      @outbound_queue.any? && status.ready?
    end

    def execute_now(gcode)
      log "RPI MSG: #{gcode}"
      serial_port.puts gcode
      status[:last] = gcode.name
      status[:BUSY] = 1 # If not, pi will race arduino and "talk too fast"
    end

    def reject_gcode(gcode)
      log "Outbound messages must be GCode objects. Use of "\
          "#{gcode.class}:#{gcode.inspect} is not permitted."
    end

    def start_event_listeners
      EM.tick_loop { maybe_execute_command }
      status.onchange { |diff| @onchange.call(diff) if @onchange }
      inbound_queue.subscribe do |gcodes|
        Array(gcodes).each do |gcode|
          parse_incoming(gcode)
          @onmessage.call(gcode) if @onmessage
        end
      end
    end

  private

    # Highest priority method for processing incoming Gcode. Use for system
    # level status changes.
    def parse_incoming(gcode)
      inputs.execute(gcode)
    end
  end
end
