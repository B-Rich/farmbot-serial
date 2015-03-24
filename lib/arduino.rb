## HARDWARE INTERFACE
## ******************

# Communicate with the arduino using a serial interface
# All information is exchanged using a variation of g-code
# Parameters are stored in the database
module FB
  class Arduino
    class << self
      def current
        @current ||= self.new
      end
    end

    class EmergencyStop < StandardError; end # Not yet used.

    attr_reader :serial_port, :logger

    # Initial and provide a serial object, as well as an IO object to send
    # log messages to. Default SerialPort is DefaultSerialPort. Default logger
    # is STDOUT
    def initialize(serial_port = DefaultSerialPort.new, logger = STDOUT)
      @serial_port, @logger = serial_port, logger
    end

    # Log to screen/file/IO stream
    def log(message)
      logger.puts(message)
    end

    # Handle incoming text from arduino into pi
    def read(string)
      log "RECEIVED #{string}"
    end

    # Send outgoing test to arduino from pi
    def write(string)
      serial_port.puts string
      log "SENT #{string}"
    end

    # Handle loss of serial connection
    def disconnect
      log "Connection to device lost"
    end
  end
end
