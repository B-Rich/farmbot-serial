# STOP! You might not need this.

`farmbot-serial` is a component used by the [Farmbot Raspberry Pi](https://github.com/FarmBot/farmbot-raspberry-pi-controller). If you are just trying to install a FarmBot, you do not need to use this. This component will be auto installed when you install the [Raspberry Pi Controller](https://github.com/FarmBot/farmbot-raspberry-pi-controller).

If you are a developer looking to work directly with the FarmBot serial interface, you're in the right place.

# Farmbot-Serial

A ruby gem for controlling Farmbot via serial line with EventMachine.

# Usage

## As an Interactive Console or Debugger

```
  git clone https://github.com/FarmBot/farmbot-serial.git
  cd farmbot-serial
  ruby console.rb

```

From there, you can type commands, such as:

```
move_relative x: 100
```

All REPL commands will be executed within the context of `bot.commands`.

## As an Application

```
gem install farmbot-serial, '0.7.6'

```

```ruby
require 'eventmachine'
require 'farmbot-serial'

bot = FB::Arduino.new # Defaults to '/dev/ttyACM0', can be configured.

EM.run do
  FB::ArduinoEventMachine.connect(bot)

  # Example 1: Writing to the serial line the "correct way" every 1.5 seconds.
  EventMachine::PeriodicTimer.new(1.5) do
    bot.commands.move_relative(x: 100, y: 50)
  end

  # Example 2: Writing raw gcode object to serial every 2.5
  EventMachine::PeriodicTimer.new(2.5) { bot.write FB::Gcode.new("F31 P8") }

  # This will execute after status has been updated / internal code.
  bot.onmessage { |gcode| puts "Message just came in." }

  # Try pulling the USB cable out to test this one.
  bot.onclose { puts "bye!"; EM.stop }
end

```

# Upgrading to Ruby 2.2

This gem requires Ruby 2.2. As of this writing, a Pi is loaded with 1.9.3 by default.

To upgrade your ruby version, try this:

```
 curl -L https://get.rvm.io | bash -s stable --ruby
```

This will take about 25 minutes on a pi3 and 2 hours on a pi2.
