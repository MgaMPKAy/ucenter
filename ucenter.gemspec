# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ucenter/version'

Gem::Specification.new do |spec|
  spec.name          = "ucenter"
  spec.version       = UCenter::VERSION
  spec.authors       = ['mgampkay']
  spec.email         = ['mgampkay@gmail.com']
  spec.summary       = 'Non-official UCenter SDK for Ruby'
  spec.description   = 'Non-official UCenter SDK for Ruby.'
  spec.homepage      = 'http://github.com/mgampkay/ucenter'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency("rack", "~> 1.5")
  spec.add_dependency("nokogiri", "~> 1.6")
end
