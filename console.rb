require_relative 'lib/farmbot-serial'
require 'pry'
                  # Defaults to '/dev/ttyACM0', can be configured.

puts """
Select a port, or press enter for '/dev/ttyACM0'
1. /dev/ttyUSB0
2. /dev/ttyACM0
"""
case gets.chomp
when "1"
  port = "/dev/ttyUSB0"
else
  port = "/dev/ttyACM0"
end

bot = FB::Arduino.new(serial_port: FB::DefaultSerialPort.new(port))

puts """
FARMBOT SERIAL SANDBOX. WELCOME!
================================

Example commands:

emergency_stop
move_relative x: 600, y: 100, z: 4
move_relative y: -600
home_x
home_y
home_z
home_all
read_parameter(8)
write_parameter('x', 0)
write_pin(pin: 13, value: 1, mode: 0)
write_pin(pin: 13, value: 0, mode: 0)
read_status(8)
"""
print "> "

class KeyboardHandler < EM::Connection
  include EM::Protocols::LineText2

  attr_reader :bot

  def initialize(bot)
    @bot = bot
  end

  def receive_line(data)
    puts (bot.commands.instance_eval(data) || "OK")
    print "> "
  rescue Exception => exc
    exit(0) if data.start_with?('q')
    puts "#{exc.message} : "
    print "> "
  end
end

EM.run do
  FB::ArduinoEventMachine.connect(bot)
  bot.onmessage do |gcode|
    bot.log "NEW MESSAGE  : #{gcode.name};" unless gcode.cmd.head == :R
  end
  bot.onchange  { |diff|  puts "STATUS CHANGE: #{diff};" }
  bot.onclose { puts "bye!"; EM.stop } # Unplug the bot and see
  EM.open_keyboard(KeyboardHandler, bot)
  0.upto(14) { |num| bot.commands.read_parameter(num) }

end

