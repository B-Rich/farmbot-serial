require 'spec_helper'

describe FB::OutgoingHandler do

  let(:handler) { FB::OutgoingHandler.new(FakeArduino.new) }
  let(:bot) { handler.bot }
  it 'initializes' do
    handler
    expect(handler.bot).to be_kind_of(FB::Arduino)
  end

  it 'emergency_stop()s' do
    10.times { handler.move_relative(x: 1) }

    handler.emergency_stop

    expect(bot.outbound_queue.length).to eq(0)
    expect(bot.status[:LAST]).to eq(:emergency_stop)
    expect(bot.serial_port.message).to eq('E')
  end

  it 'adjusts relative movements to bots position RIGHT NOW' do
    handler.move_relative(x: 1, y: 2, z: 3)
    expect(bot.next_cmd.to_s).to eq("G0 X1 Y2 Z3")
    [:x, :y, :z].each { |pos| bot.status[pos] = 3 }
    expect(bot.next_cmd.to_s).to eq("G0 X4 Y5 Z6")
  end

  it 'never allows X / Y behind the 0 line' do
    handler.move_relative(x: -999, y: -999, z: -999)
    expect(bot.outbound_queue.first.value_of(:x)).to eq(0)
    expect(bot.outbound_queue.first.value_of(:y)).to eq(0)
  end

  it 'allows Z to be negative' do
    handler.move_relative(z: -999)
    expect(bot.outbound_queue.first.value_of(:z)).to eq(-999)
  end

  it 'Moves absolute' do
    [:x, :y, :z].each { |pos| bot.status[pos] = 300 }
    handler.move_absolute(x: 5, y: 6, z: 7)
    expect(bot.next_cmd.to_s).to eq("G0 X5 Y6 Z7")
    handler.move_absolute(x: 7, y: 8, z: 9)
    expect(bot.next_cmd.to_s).to eq("G0 X7 Y8 Z9")
  end

  it 'Never sends X/Y behind 0' do
    handler.move_absolute(x: -987, y: -654, z: 0)
    expect(bot.next_cmd.to_s).to eq("G0 X0 Y0 Z0")
  end

  it 'sends Z to subzero coords' do
    handler.move_absolute(x: 0, y: 0, z: -123)
    expect(bot.next_cmd.to_s).to eq("G0 X0 Y0 Z-123")
  end

  it 'homes x, y, z, all' do
    handler.home_x
    expect(bot.next_cmd.to_s).to eq("F11")
    handler.home_y
    expect(bot.next_cmd.to_s).to eq("F12")
    handler.home_z
    expect(bot.next_cmd.to_s).to eq("F13")
    handler.home_all
    expect(bot.next_cmd.to_s).to eq("G28")
  end

  it 'reads / writes parameters' do
    handler.read_parameter(0)
    expect(bot.next_cmd.to_s).to eq("F21 P0")
    handler.write_parameter(0, 1)
    expect(bot.next_cmd.to_s).to eq("F22 P0 V1")
  end

  it 'reads status' do
    handler.read_status(0)
    expect(bot.next_cmd.to_s).to eq("F31 P0")
  end

  it 'writes to a pin' do
    handler.write_pin(pin: 0, value: 1, mode: 3)
    expect(bot.next_cmd.to_s).to eq("F41 P0 V1 M3")
  end

  it 'sets max speed' do
    handler.set_max_speed(:x, 1000)
    expect(bot.next_cmd.to_s).to eq("F22 P71 V1000")
    handler.set_max_speed(:Y, 100)
    expect(bot.next_cmd.to_s).to eq("F22 P72 V100")
    handler.set_max_speed('z', 1)
    expect(bot.next_cmd.to_s).to eq("F22 P73 V1")
  end

  it 'sets acceleration' do
    handler.set_acceleration(:x, 123)
    expect(bot.next_cmd.to_s).to eq("F22 P41 V123")
    handler.set_acceleration(:y, 123)
    expect(bot.next_cmd.to_s).to eq("F22 P42 V123")
    handler.set_acceleration(:z, 123)
    expect(bot.next_cmd.to_s).to eq("F22 P43 V123")
  end

  it 'sets a timeout' do
    handler.set_timeout(:x, 223)
    expect(bot.next_cmd.to_s).to eq("F22 P11 V223")
    handler.set_timeout(:y, 223)
    expect(bot.next_cmd.to_s).to eq("F22 P12 V223")
    handler.set_timeout(:z, 223)
    expect(bot.next_cmd.to_s).to eq("F22 P13 V223")
  end

  it 'sets end stop inversion' do
    handler.set_end_inversion(:x, true)
    expect(bot.next_cmd.to_s).to eq("F22 P21 V1")
    handler.set_end_inversion(:y, '0')
    expect(bot.next_cmd.to_s).to eq("F22 P22 V0")
    handler.set_end_inversion(:z, 1)
    expect(bot.next_cmd.to_s).to eq("F22 P23 V1")
  end

  it 'sets motor inversion' do
    handler.set_motor_inversion(:x, false)
    expect(bot.next_cmd.to_s).to eq("F22 P31 V0")
    handler.set_motor_inversion(:y, '1')
    expect(bot.next_cmd.to_s).to eq("F22 P32 V1")
    handler.set_motor_inversion(:z, 0)
    expect(bot.next_cmd.to_s).to eq("F22 P33 V0")
  end

  it 'does NOT set negative coordinates' do
    expect do
      handler.set_negative_coordinates(:x, 99)
    end.to raise_exception
  end

  it 'does NOT set steps per mm (thats not the Arduinos job)' do
    expect do
      handler.set_steps_per_mm(:x, 99)
    end.to raise_exception
  end

  it 'sets end inversion' do
    expect do
      handler.set_steps_per_mm(:x, 99)
    end.to raise_exception
  end

  it 'raises exceptions when given invalid axis names' do
    expect do
      handler.set_max_speed('q', 1)
    end.to raise_exception(FB::OutgoingHandler::InvalidAxisEntry)
  end

  it 'handles bad inputs when inverting motors / steps' do
    expect do
      handler.set_motor_inversion(:x, 4)
    end.to raise_exception(FB::OutgoingHandler::BadBooleanValue)
  end
end
