require 'spec_helper'

describe FB::ArduinoEventMachine do
  let(:logger) { FakeLogger.new }
  let(:serial_port) { FakeSerialPort.new }
  let(:bot) { FB::Arduino.new(serial_port: serial_port, logger: logger) }
  let(:em) do
    FB::ArduinoEventMachine.arduino = bot
    FB::ArduinoEventMachine.new(serial_port)
  end

  it 'initializes' do
    em
    expect(FB::ArduinoEventMachine.arduino).to eq(bot)
    expect(em.bot).to eq(bot)
    expect(em.q).to eq(bot.inbound_queue)
    expect(em.buffer).to eq('')
  end

  it 'splits incoming data' do
    text = em.split_into_chunks "hello\r\nworld\r\n"
    expect(text).to include("hello\r\n")
    expect(text).to include("world\r\n")
  end

  it 'fills / clears the buffer' do
    msg = "A1 B2 C3\r\nD4 E5 F6\r\n"
    em.add_to_buffer("A1 B2 C3\r\nD4 E5 F6\r\n")
    expect(em.buffer).to eq(msg)

    within_event_loop do
      #subscribe to the message queue and grab the last result.
      em.q.subscribe { |x| @results = x }
      em.send_buffer
    end

    expect(@results.length).to eq(2)
    expect(@results.first.cmd.head).to eq(:A)
    expect(@results.last.cmd.head).to eq(:D)

    em.clear_buffer
    expect(em.buffer).to eq('')
  end

  it 'receives data (normal end of chunk)' do
    allow(em).to receive(:add_to_buffer).ordered
    allow(em).to receive(:send_buffer).ordered
    allow(em).to receive(:clear_buffer).ordered
    allow(em.q).to receive(:clear_buffer)
    em.receive_data("\r\n")
    expect(em).to have_received(:add_to_buffer)
    expect(em).to have_received(:send_buffer)
    expect(em).to have_received(:clear_buffer)
  end

  it 'receives data (incomplete end of chunk)' do
    allow(em).to receive(:add_to_buffer).ordered
    allow(em).to receive(:send_buffer).ordered
    allow(em).to receive(:clear_buffer).ordered
    msg = "R00\n"
    em.receive_data(msg)
    expect(em).to have_received(:add_to_buffer).with(msg)
    expect(em).to have_received(:send_buffer)
    expect(em).to have_received(:clear_buffer)
  end

  it 'receives data (middle of chunk)' do
    allow(em).to receive(:add_to_buffer)
    allow(em).to receive(:send_buffer).ordered
    allow(em).to receive(:clear_buffer).ordered
    msg = "R01\n"
    em.receive_data(msg)
    expect(em).to have_received(:add_to_buffer).with(msg)
    expect(em).to_not have_received(:send_buffer)
    expect(em).to_not have_received(:clear_buffer)
  end

  it 'unbinds' do
    allow(EM).to receive(:stop)#.ordered
    em.unbind
    expect(EM).to have_received(:stop)
  end

  it 'connects a bot' do
    allow(EM).to receive(:attach)
    em.class.connect(bot)
    expect(EM).to have_received(:attach).with(bot.serial_port, em.class)
    expect(em.class.arduino).to be(bot)
  end
end
