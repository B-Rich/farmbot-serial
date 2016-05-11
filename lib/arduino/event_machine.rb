require 'eventmachine'
module FB
  # Class that is fed into event machine's event loop to handle incoming serial
  # messages asynchronously via EM.attach(). See: EM.attach
  class ArduinoEventMachine < EventMachine::Connection
    class << self
      attr_accessor :arduino
    end

    attr_reader :q, :buffer, :bot

    def initialize
      @bot = self.class.arduino
      @q, @buffer = @bot.inbound_queue, ''
    end

    # Gets called when data arrives.
    def receive_data(data)
      split_into_chunks(data).each do |chunk|
        if chunk.end_with?("\r\n") || chunk.end_with?("R00\n")
          add_to_buffer(chunk)
          send_buffer
          clear_buffer
        else
          add_to_buffer(chunk) # Keep RXing the buffer until chunk completes.
        end
      end
    end

    # This is a nasty hack that takes incoming strings from the serial line and
    # splits the data on \r\n. Unlike Ruby's split() method, this method will
    # preserve the \r\n.
    def split_into_chunks(data)
      data.gsub("\r\n", '\b\a').split('\a').map{ |d| d.gsub('\b', "\r\n") }
    end

    def clear_buffer
      @buffer = ''
    end

    def add_to_buffer(d)
      @buffer += d
    end

    def send_buffer
      @q << Gcode.parse_lines(@buffer)
    end

    # Gets called when the connection breaks.
    def unbind
      self.class.arduino.disconnect
      EM.stop
    end

    def self.connect(arduino)
      @arduino = arduino
      EM.attach arduino.serial_port, self
    end
  end
end
