require_relative 'lib/farmbot-serial'
require 'pry'

connection =  FB::DefaultSerialPort.new('/dev/ttyUSB0')

puts """
THIS IS A SERIAL TERMINAL.

"""

print "> "

class KeyboardHandler < EM::Connection
  include EM::Protocols::LineText2

  attr_reader :connection

  def initialize(connection)
    @connection = connection
  end

  def receive_line(data)
    connection.puts(data.chomp + "\r\n")
    puts("Computer: #{data}")
  end

  def unbind
    EM.stop
  end
end

class SerialHandler < EventMachine::Connection
  def receive_data(data)
    puts("Arduino: #{data}")
  end

  def unbind
    EM.stop
  end
end

EM.run do
  EM.open_keyboard(KeyboardHandler, connection)
  EM.attach(connection,)
end
