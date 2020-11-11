# frozen_string_literal: true

module Pulljoy
  class BugError < StandardError; end

  def self.format_error_and_backtrace(exception)
    result = String.new("#{exception} (#{exception.class})\n")
    exception.backtrace.each do |line|
      result << "    #{line}\n"
    end
    result.freeze
  end
end
