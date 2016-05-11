require 'serialport'

# This object creates a Serial IO Object with sane defaults, since most FarmBot
# setups follow the same serial configuration setup. You can build your own
# SerialPort object also, if that's what you need. DefaultSerialPort is just a
# suggestion, rather than the only option. Any serial connection will work.
module FB
  class DefaultSerialPort < SerialPort
    COM_PORT = '/dev/ttyACM0'
    OPTIONS  = { "baud"         => 115200,
                 "data_bits"    => 8,
                 "stop_bits"    => 1,
                 "parity"       => SerialPort::NONE,
                 "flow_control" => SerialPort::SOFT }

    # Why `def self::new()`? it was defined that way in the parent class,
    # therefore, I can't call super in #initialize().
    #:nocov:
    def self::new(com = COM_PORT, conf = OPTIONS)
      super
    end
  end
end
