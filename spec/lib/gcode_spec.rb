require 'spec_helper'
describe FB::Gcode do
  let(:gcode) { FB::Gcode.new{ "F31 P8 " } }
  let(:null_token) { FB::Gcode::GcodeToken.new("NULL0") }

  it("initializes from string") { expect(gcode).to be_kind_of(FB::Gcode) }

  it("infers Gcode name") { expect(gcode.name).to eq(:read_status) }

  it "returns :unknown for bad Gcode tokens" do
    unknown = FB::Gcode.new{ "QQQ31 F32 " }.name
    expect(unknown).to eq(:unknown)
  end

  it("sets the original input string") { expect(gcode.block[]).to eq("F31 P8 ") }

  it("sets @cmd using the first Gcode node") do
    expect(gcode.cmd).to be_kind_of(FB::Gcode::GcodeToken)
    expect(gcode.cmd.head).to eq(:F)
    expect(gcode.cmd.tail).to eq(31)
  end

  it("sets @params using the last Gcode node(s)") do
    expect(gcode.params).to be_kind_of(Array)
    expect(gcode.params[0]).to be_kind_of(FB::Gcode::GcodeToken)
    expect(gcode.params[0].head).to eq(:P)
    expect(gcode.params[0].tail).to eq(8)
  end

  it("serializes back to string via #to_s") do
    expect(gcode.to_s).to eq("F31 P8")
  end

  it "parses multiple Gcodes in a single string via parse_lines" do
    codes = FB::Gcode.parse_lines("A12 B34\nC56 D78\r\n")
    expect(codes.count).to eq(2)
    expect(codes.first).to be_kind_of(FB::Gcode)
    expect(codes.last.cmd.head).to eq(:C)
    expect(codes.first.params.first.tail).to eq(34)
  end

  it 'handles parameterless Gcode' do
    expect(FB::Gcode.new{ "  " }.name).to be(:unknown)
    expect(FB::Gcode.new{ "  " }.cmd.head).to eq(null_token.head)
    expect(FB::Gcode.new{ "  " }.cmd.tail).to eq(null_token.tail)
  end
end

