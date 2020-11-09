# frozen_string_literal: true

module Pulljoy
  class BugError < StandardError; end

  def self.format_error_and_backtrace(e)
    result = String.new("#{e} (#{e.class})\n")
    e.backtrace.each do |line|
      result << "    #{line}\n"
    end
    result.freeze
  end
end
