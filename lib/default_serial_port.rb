require 'serialport'

# This object creates a Serial IO with sane default, since most FarmBot setups
# follow the same serial configuration setup.
class DefaultSerialPort < SerialPort
  COM_PORT = '/dev/ttyACM0'
  OPTIONS  = { "baud"         => 115200,
               "data_bits"    => 8,
               "stop_bits"    => 1,
               "parity"       => SerialPort::NONE,
               "flow_control" => SerialPort::SOFT }

  # Why `def self::new()`? it was defined that way in the parent class,
  # therefore, I can't call super in #initialize().
  def self::new(com = COM_PORT, conf = OPTIONS)
    super
  end
end

