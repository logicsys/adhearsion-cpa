require 'adhearsion'
require 'punchblock'

require 'simplecov'
SimpleCov.start

require 'adhearsion_cpa'

Punchblock.logger = Logger.new(STDOUT)
Punchblock.logger.level = Logger::DEBUG

RSpec.configure do |config|

  config.filter_run_when_matching :focus

  config.before(:all) do
    Adhearsion::Plugin.initializers.each do |plugin_initializer|
      plugin_initializer.run
    end
  end
end

