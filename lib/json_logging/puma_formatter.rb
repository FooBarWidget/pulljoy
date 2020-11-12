# frozen_string_literal: true

require 'json'
require 'time'
require 'english'

module Pulljoy
  module JSONLogging
    class PumaFormatter
      def initialize
        @hostname = Socket.gethostname
      end

      def call(msg)
        JSON.generate(
          name: 'pulljoy',
          hostname: @hostname,
          pid: $PROCESS_ID,
          level: 30,
          time: Time.now.iso8601(3),
          v: 0,
          msg: msg,
        )
      end
    end
  end
end
