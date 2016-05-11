require 'spec_helper'

describe FB::Arduino do
  let(:logger) { FakeLogger.new }
  let(:serial_port) { FakeSerialPort.new }
  let(:command) { FB::Gcode.new { 'A1 B2 C3' } }
  let(:bot) do
    FB::Arduino.new(serial_port: serial_port, logger: logger)
  end


  it 'logs' do
    bot.log 'Hello, world!'
    expect(logger.message).to eq('Hello, world!')
  end


  it 'initializes' do
    expect(bot).to be_kind_of(FB::Arduino)
    expect(bot.serial_port).to be_kind_of(FakeSerialPort)
    expect(bot.logger).to be_kind_of(StringIO)
    expect(bot.commands).to be_kind_of(FB::OutgoingHandler)
    expect(bot.inbound_queue).to be_kind_of(EM::Channel)
    expect(bot.status).to be_kind_of(FB::Status)
    expect(bot.inputs).to be_kind_of(FB::IncomingHandler)
  end

  it 'prints to the logger object' do
    bot.log 'Hello, World!'
    expect(logger.message).to eq('Hello, World!')
  end

  it 'writes to outbound command queue' do
    bot.write('A1 B2 C3')
    expect(bot.outbound_queue).to include('A1 B2 C3')
  end

  it 'sets change/message/close callbacks' do
    yowza = ->{ bot.log 'QQQ' }
    bot.onmessage(&yowza)
    bot.onclose(&yowza)
    bot.onchange(&yowza)
    expect(bot.instance_variable_get(:@onmessage)).to be(yowza)
    expect(bot.instance_variable_get(:@onclose)).to be(yowza)
    expect(bot.instance_variable_get(:@onchange)).to be(yowza)
  end

  it 'calls onclose callback via disconnect()' do
    calls = []
    bot.onclose { calls << 'Hey!' }
    bot.disconnect
    expect(logger.message).to eq('Connection to device lost')
    expect(calls.length).to eq(1)
    expect(calls).to include('Hey!')
  end

  it 'reports current_position' do
    bot.status[:x] = 1
    bot.status[:y] = 2
    bot.status[:z] = 3
    expect(bot.current_position.x).to eq(1)
    expect(bot.current_position.y).to eq(2)
    expect(bot.current_position.z).to eq(3)
  end

  it 'pops gcode off queue' do
    bot.outbound_queue.push(command)
    expect(bot.outbound_queue.length).to eq(1)
    bot.status[:BUSY] = 0
    within_event_loop { bot.maybe_execute_command }
    expect(bot.outbound_queue.length).to eq(0)
    expect(serial_port.message).to eq('A1 B2 C3')
    expect(bot.status.ready?).to be_falsey
    expect(bot.status[:last]).to eq(:unknown)
  end

  it 'starts event listeners' do
    called_onmessage = 0
    called_onchange  = 0
    bot.inbound_queue.push(command)

    bot.onmessage do |msg|
      called_onmessage += 1
      bot.status[:X] = 33
    end

    bot.onchange do |diff|
      called_onchange += 1
    end

    within_event_loop { nil }

    expect(called_onmessage).to eq(1)
    expect(called_onchange).to eq(1)
  end

  it 'Flips out if a message is not a GCode object.' do
    bot.outbound_queue.push "I don't think so!"
    bot.status[:BUSY] = 0
    bot.maybe_execute_command
    expect(logger.message).to eq("Outbound messages must be GCode objects. "\
      "Use of String:\"I don't think so!\" is not permitted.")
  end
end
