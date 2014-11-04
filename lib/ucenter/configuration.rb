module UCenter
  class Configuration
    attr_accessor :appid, :key, :api, :charset
    attr_accessor :default_agent

    def initialize
      @default_agent = 'S.H.I.E.L.D.'
    end
  end
end
