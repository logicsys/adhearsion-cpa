require "adhearsion"

# Reopen rather than assign (AdhearsionCpa = Module.new): bundler evaluates
# the gemspec first, which loads adhearsion_cpa/version.rb, so assignment
# would clobber the module already holding VERSION — and the version require
# below is then a no-op, losing the constant.
module AdhearsionCpa; end

require "adhearsion_cpa/version"
require "adhearsion_cpa/plugin"
require "adhearsion_cpa/tone_detector"
require "adhearsion_cpa/controller_methods"
