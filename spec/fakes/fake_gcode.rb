class FakeGcode
  attr_reader :name, :gcode

  def initialize(name, gcode)
    @name, @gcode = name, gcode
  end
end
