# frozen_string_literal: true

require 'json'
require 'time'

module Pulljoy
  class PumaJSONFormatter
    def initialize
      @hostname = Socket.gethostname
    end

    def call(msg)
      JSON.generate({
        name: 'pulljoy',
        hostname: @hostname,
        pid: $$,
        level: 30,
        time: Time.now.iso8601(3),
        v: 0,
        msg: msg,
      })
    end
  end
end
