# frozen_string_literal: true

require 'dry-struct'
require_relative 'types'

module Pulljoy
  COMMAND_PREFIX = '/pulljoy'
  COMMAND_PREFIX_RE = %r{^#{Regexp.escape(COMMAND_PREFIX)} }

  class UnsupportedCommandType < StandardError; end
  class CommandSyntaxError < StandardError; end

  # Parses the given text as a command.
  #
  # @param text [String] The text to parse.
  # @return [ApproveCommand, nil] A command object, or nil if `text` didn't contain a command.
  # @raise [UnsupportedCommandType, CommandSyntaxError]
  def self.parse_command(text)
    text = text.strip
    return nil if text !~ COMMAND_PREFIX_RE

    text.sub!(COMMAND_PREFIX_RE, '')
    command_type, *args = text.split

    begin
    case command_type
      when 'approve'
        if args.size != 1
          raise CommandSyntaxError, "'approve' command requires exactly 1 argument"
        end
        ApproveCommand.new(review_id: args[0])
      else
        raise UnsupportedCommandType, "Unsupported command type #{args[0].inspect}"
      end
    rescue Dry::Struct::Error => e
      raise "Invalid command argument: #{e.message}"
    end
  end

  class ApproveCommand < Dry::Struct
    attribute :review_id, Types::Coercible::String
  end
end
