require 'ucenter/version'
require 'ucenter/configuration'
require 'ucenter/ucenter'

module UCenter

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.connect(agent: nil)
    ::UCenter::UCenter.new agent: agent
  end

end
