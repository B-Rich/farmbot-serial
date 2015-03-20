require 'spec_helper'

describe HardwareInterface do

  before do
    HardwareInterface.current = HardwareInterface.new(true)
    HardwareInterface.current.status = Status.new
  end

  it "servo standard move" do
    pin      = rand(9999999).to_i
    value    = rand(9999999).to_i

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"
    HardwareInterface.current.servo_std_move(pin, value)

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("F61 P#{pin} V#{value}\n")
  end

  it "servo standard move" do
    pin      = rand(9999999).to_i
    value    = rand(9999999).to_i
    mode     = rand(9999999).to_i

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"
    HardwareInterface.current.pin_std_set_value(pin, value, mode)

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("F41 P#{pin} V#{value} M#{mode}\n")
  end

#  def pin_std_read_value(pin, mode, external_info)

  it "pin standard read value" do
    pin      = rand(9999999).to_i
    mode     = rand(9999999).to_i
    value    = rand(9999999).to_i
    ext_info = rand(9999999).to_s

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR41 P#{pin} V#{value}\nR02\n"
    HardwareInterface.current.pin_std_read_value(pin, mode, ext_info)

    pin_value = 0

    expect(pin_value.to_i).to eq(value.to_i)
    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("F42 P#{pin} M#{mode}\n")
  end

#  def pin_std_set_mode(pin, mode)

  it "pin standard set mode" do
    pin      = rand(9999999).to_i
    mode     = rand(9999999).to_i

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"
    HardwareInterface.current.pin_std_set_mode(pin, mode)

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("F43 P#{pin} M#{mode}\n")
  end

  it "pin standard set pulse" do
    pin      = rand(9999999).to_i
    value1   = rand(9999999).to_i
    value2   = rand(9999999).to_i
    time     = rand(9999999).to_i
    mode     = rand(9999999).to_i

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"
    HardwareInterface.current.pin_std_pulse(pin, value1, value2, time, mode)

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("F44 P#{pin} V#{value1} W#{value2} T#{time} M#{mode}\n")
  end

  it "dose water" do
    amount    = rand(9999999).to_i
    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"
    HardwareInterface.current.dose_water(amount)

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("F01 Q#{amount}\n")
  end

  it "read end stops" do
    xa    = (rand(2) >= 1) ? 1 : 0
    xb    = (rand(2) >= 1) ? 1 : 0
    ya    = (rand(2) >= 1) ? 1 : 0
    yb    = (rand(2) >= 1) ? 1 : 0
    za    = (rand(2) >= 1) ? 1 : 0
    zb    = (rand(2) >= 1) ? 1 : 0

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR81 XA#{xa} XB#{xb} YA#{ya} YB#{yb} ZA#{za} ZB#{zb}\nR02\n"
    HardwareInterface.current.read_end_stops()

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("F81\n")
    expect(HardwareInterface.current.status.info_end_stop_x_a).to eq(xa == 1)
    expect(HardwareInterface.current.status.info_end_stop_x_b).to eq(xb == 1)
    expect(HardwareInterface.current.status.info_end_stop_y_a).to eq(ya == 1)
    expect(HardwareInterface.current.status.info_end_stop_y_b).to eq(yb == 1)
    expect(HardwareInterface.current.status.info_end_stop_z_a).to eq(za == 1)
    expect(HardwareInterface.current.status.info_end_stop_z_b).to eq(zb == 1)
  end

  it "read position" do

    x      = rand(9999999).to_i
    y      = rand(9999999).to_i
    z      = rand(9999999).to_i

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR82 X#{x} Y#{y} Z#{z}\nR02\n"
    HardwareInterface.current.read_postition()

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("F82\n")
    expect(HardwareInterface.current.status.info_current_x_steps).to eq(x)
    expect(HardwareInterface.current.status.info_current_y_steps).to eq(y)
    expect(HardwareInterface.current.status.info_current_z_steps).to eq(z)
  end

  it "read device version" do

    version      = rand(9999999).to_s

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR83 #{version}\nR02\n"
    HardwareInterface.current.read_device_version()

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("F83\n")
    expect(HardwareInterface.current.status.device_version).to eq(version)
  end

  it "home all" do

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"
    HardwareInterface.current.move_home_all()

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("G28\n")
  end

  it "home x" do
    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"
    HardwareInterface.current.move_home_x()

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("F11\n")
  end

  it "home y" do

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"
    HardwareInterface.current.move_home_y()

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("F12\n")
  end

  it "home z" do

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"
    HardwareInterface.current.move_home_z()

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("F13\n")

  end

#  def calibrate_x

  it "calibrate x" do

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"
    HardwareInterface.current.calibrate_x()

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("F14\n")

  end

#  def calibrate_y

  it "calibrate y" do

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"
    HardwareInterface.current.calibrate_y()

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("F15\n")

  end

#  def calibrate_z

  it "calibrate z" do

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"
    HardwareInterface.current.calibrate_z()

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("F16\n")

  end

#  def move_absolute( coord_x, coord_y, coord_z)

  it "move absolute" do

    x      = rand(9999999).to_i
    y      = rand(9999999).to_i
    z      = rand(9999999).to_i

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"
    HardwareInterface.current.move_absolute( x, y, z)

    part_x = "X#{x * HardwareInterface.current.ramps_param.axis_x_steps_per_unit}"
    part_y = "Y#{y * HardwareInterface.current.ramps_param.axis_y_steps_per_unit}"
    part_z = "Z#{z * HardwareInterface.current.ramps_param.axis_z_steps_per_unit}"

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("G00 #{part_x} #{part_y} #{part_z}\n")
  end


#  def move_relative( amount_x, amount_y, amount_z)

  it "move relative" do

    x         = rand(9999999).to_i
    y         = rand(9999999).to_i
    z         = rand(9999999).to_i

    current_x = rand(9999999).to_i
    current_y = rand(9999999).to_i
    current_z = rand(9999999).to_i

    HardwareInterface.current.status.info_current_x_steps = current_x
    HardwareInterface.current.status.info_current_y_steps = current_y
    HardwareInterface.current.status.info_current_z_steps = current_z

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"
    HardwareInterface.current.move_relative( x, y, z)

    part_x = "X#{x * HardwareInterface.current.ramps_param.axis_x_steps_per_unit + current_x}"
    part_y = "Y#{y * HardwareInterface.current.ramps_param.axis_y_steps_per_unit + current_y}"
    part_z = "Z#{z * HardwareInterface.current.ramps_param.axis_z_steps_per_unit + current_z}"

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("G00 #{part_x} #{part_y} #{part_z}\n")
  end

#  def move_steps(steps_x, steps_y, steps_z)

  it "move steps" do

    x         = rand(9999999).to_i
    y         = rand(9999999).to_i
    z         = rand(9999999).to_i

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"
    HardwareInterface.current.move_steps( x, y, z)

    part_x = "X#{x}"
    part_y = "Y#{y}"
    part_z = "Z#{z}"

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("G01 #{part_x} #{part_y} #{part_z}\n")
  end

#  def move_to_coord(steps_x, steps_y, steps_z)

  it "move to coord" do

    x         = rand(9999999).to_i
    y         = rand(9999999).to_i
    z         = rand(9999999).to_i

    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"
    HardwareInterface.current.move_to_coord( x, y, z)

    part_x = "X#{x}"
    part_y = "Y#{y}"
    part_z = "Z#{z}"

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("G00 #{part_x} #{part_y} #{part_z}\n")
  end

#  def check_parameters

  it "check parameters" do

    db_version  = rand(9999999).to_i



    HardwareInterface.current.ramps_arduino.serial_port.test_serial_write = ""
    HardwareInterface.current.ramps_arduino.serial_port.test_serial_read  = "R21 P0 V#{db_version}\n"
    HardwareInterface.current.check_parameters()

    expect(HardwareInterface.current.ramps_arduino.serial_port.test_serial_write).to eq("F21 P0\n")
  end


end
