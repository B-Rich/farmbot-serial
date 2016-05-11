require 'spec_helper'


describe FB::IncomingHandler do
  let(:bot) { FakeArduino.new }
  let(:handler) { FB::IncomingHandler.new(bot) }

  it 'gets calibration data' do
    gcode = FB::Gcode.new { "R21 P71 V7654" }
    handler.execute(gcode)
    expect(bot.status.to_h[:MOVEMENT_MAX_SPD_X]).to eq(7654)
  end

  it 'handles unknowns' do
    handler.execute(FakeGcode.new('hello', 'abc'))
    expectation = "hello is a valid GCode, but no input handler method exists"
    expect(bot.logger.message).to eq(expectation)
  end

  it 'reports the value of a parameter' do
    handler.report_pin_value(FB::Gcode.new { "A1 P1 V0" })
    expect(bot.status.get_pin(1)).to eq(:off)
    handler.report_pin_value(FB::Gcode.new { "A1 P1 V1" })
    expect(bot.status.get_pin(1)).to eq(:on)
  end

  it 'reports end stops' do
    gcode = FB::Gcode.new { "LOL1 S99" }
    handler.report_end_stops(gcode)
    expect(bot.status[:S]).to eq(99)
  end

  it 'reports current position' do
    gcode = FB::Gcode.new { "LOL1 X99" }
    handler.report_current_position(gcode)
    expect(bot.status[:X]).to eq(99)
  end

  it 'reports the value of a status' do
    handler.report_pin_value(FB::Gcode.new { "A1 P1 V0" })
    expect(bot.status.get_pin(1)).to eq(:off)
    handler.report_pin_value(FB::Gcode.new { "A1 P1 V1" })
    expect(bot.status.get_pin(1)).to eq(:on)
  end

  it 'responds to message received' do
    handler.received(FakeGcode.new('doesnt', 'matter'))
    expect(bot.status[:busy]).to eq(1)
  end
  it 'responds to idle message' do
    handler.idle(FakeGcode.new('doesnt', 'matter'))
    expect(bot.status[:busy]).to eq(0)
  end
  it 'responds to done message' do
    handler.done(FakeGcode.new('doesnt', 'matter'))
    expect(bot.status[:busy]).to eq(0)
  end
  it 'responds to busy message' do
    handler.busy(FakeGcode.new('doesnt', 'matter'))
    expect(bot.status[:busy]).to eq(1)
  end

  it 'has not implemented report_software_version' do
    expectation = handler.report_software_version("Does not matter")
    expect(expectation).to be_nil
  end
end
