require_relative "fake_logger"
require_relative "fake_serial_port"

class FakeArduino < FB::Arduino
  def initialize(serial_port: FakeSerialPort.new, logger: FakeLogger.new)
    super
  end
end
