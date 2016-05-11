require 'yaml'
module FB
  class Gcode
    GCODE_DICTIONARY     = YAML.load_file(File.join(File.dirname(__FILE__),
                                          'gcode.yml'))
    PARAMETER_DICTIONARY = YAML.load_file(File.join(File.dirname(__FILE__),
                                          'parameters.yml'))

    attr_accessor :cmd, :params, :block

    def initialize(&block)
      @block  = block
    end

    # Turns a string of many gcodes into an array of many gcodes. Used to parse
    # incoming serial.
    def self.parse_lines(string)
      string.gsub("\r", '').split("\n").map { |s| self.new { s } }
    end

    # Returns a symbolized english version of the gcode's name.
    def name
      GCODE_DICTIONARY[cmd.to_sym] || :unknown
    end

    def to_s
      # self.to_s # => "A12 B23 C45"
      [cmd, *params].map(&:to_s).join(" ")
    end

    def params
      @block
        .call
        .split(' ')
        .map { |line| GcodeToken.new(line) }
        .tap { |p| p.shift }
    end

    def cmd
      cmd = @block.call.split(' ')
      GcodeToken.new(cmd.any? ? cmd.first : "NULL0")
    end

    def value_of(param)
      params.find{ |p| p.head == param.to_sym.upcase }.tail
    end

    # A head/tail pair of a single node of GCode. Ex: R01 = [:R, '01']
    class GcodeToken
      attr_reader :head, :tail

      def initialize(str)
        nodes = str.scan(/[a-zA-Z]+|\-?\d+/) # ["R", "-19"], ["Z", "4"]

        @head, @tail = nodes.shift.to_sym, nodes.join(" ")
        # Coerce to ints if possible, since serial line is all string types.
        @tail = @tail.to_i if @tail.match(/^\-?\d+$/)
      end

      def to_sym
        to_s.to_sym
      end

      def to_s
        "#{head}#{tail}"
      end
    end
  end
end
