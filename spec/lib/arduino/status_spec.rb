require 'spec_helper'

describe FB::Status do

  let(:status) { FB::Status.new }

  it "capitalizes all incoming status keys" do
    status[:bUsY] = 345345345
    expect(status[:BUSY]).to eq(345345345)
    expect(status[:bUsy]).to eq(345345345)
    expect(status[:busy]).to eq(345345345)
  end

  it "symbolizes all incoming status keys" do
    status['busy'] = 878787
    expect(status[:bUsy]).to eq(878787)
  end

  it "indicates BUSY status via #ready?()" do
    status['busy'] = 1
    expect(status.ready?).to be_falsey
    status['busy'] = 0
    expect(status.ready?).to be_truthy
  end

  it 'broadcasts status changes' do
    @diff = {}

    within_event_loop do
      status.onchange { |diff| @diff = diff }
      status[:busy] = 1
      status[:busy] = 0
      status[:busy] = 1
    end

    expect(status[:busy]).to eq(1)
    expect(@diff).to eq(:BUSY => 1)
  end

  it 'Updates status registers directly from GCode' do
    command = FB::Gcode.new { "A1 X88 Y77 Z66" }
    status.gcode_update(command)
    expect(status[:x]).to eq(88)
    expect(status[:y]).to eq(77)
    expect(status[:z]).to eq(66)
  end

  it 'reads known and unknow pin values' do
    status.set_pin(1, 1)
    expect(status.get_pin(1)).to eq(:on)
    expect(status.get_pin(2)).to eq(:unknown)
  end

  it 'serializes into a hash' do
    reality = status.instance_variable_get("@info").to_h
    perception = status.to_h
    expect(perception).to eq(reality)
  end

end

