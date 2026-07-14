# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "adhearsion_cpa/version"

Gem::Specification.new do |s|
  s.name        = "adhearsion_cpa"
  s.version     = AdhearsionCpa::VERSION
  s.authors     = ["Justin Aiken"]
  s.email       = ["60tonangel@gmail.com"]
  s.license     = 'MIT'
  s.required_ruby_version = ">= 3.3.0"
  s.homepage    = "https://github.com/grasshoppergroup/adhearsion-cpa"
  s.summary     = %q{A plugin for adding cpa to Adhearsion}
  s.description = %q{A plugin for adding cpa to Adhearsion}


  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.add_runtime_dependency %q<adhearsion>, ["~> 4.1", ">= 4.1.1"]
  s.add_runtime_dependency %q<punchblock>, ["~> 3.0", ">= 3.0.1"]
  s.add_runtime_dependency %q<activesupport>, ["~> 8.0"]

  s.add_development_dependency %q<simplecov>, ['>= 0.17']
  s.add_development_dependency %q<bundler>, [">= 1.0"]
  s.add_development_dependency %q<rspec>, [">= 4.0.0.beta1"]
  s.add_development_dependency %q<rake>, [">= 0"]
  s.add_development_dependency %q<guard-rspec>
 end
