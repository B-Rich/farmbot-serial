# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "farmbot-serial"
  spec.version       = '1.1.1'
  spec.authors       = ["Tim Evers", "Rick Carlino"]
  spec.email         = ["rick.carlino@gmail.com"]
  spec.description   = "Serial library for Farmbot"
  spec.summary       = "Serial library for Farmbot"
  spec.homepage      = "http://github.com/farmbot/farmbot-serial"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/).select{|f| !f.include?('.gem')}
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_development_dependency "bundler"#,    "~> 1.3"
  spec.add_development_dependency "rake"#,       "~> 10.4"
  spec.add_development_dependency "rspec"#,      "~> 3.2"
  spec.add_development_dependency "pry"#,        "~> 0.10"
  spec.add_development_dependency "simplecov"#,  "~> 0.9"
  spec.add_development_dependency "ruby-prof"

  spec.add_runtime_dependency     "eventmachine"#, "~> 1.3"
  spec.add_runtime_dependency     "serialport"#, "~> 1.3"

end
