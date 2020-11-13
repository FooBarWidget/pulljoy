# frozen_string_literal: true

require 'dry-struct'
require_relative 'utils'

module Pulljoy
  COMMAND_PREFIX = '/pulljoy'
  COMMAND_PREFIX_RE = /^#{Regexp.escape(COMMAND_PREFIX)} /.freeze

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
        raise CommandSyntaxError, "'approve' command requires exactly 1 argument" if args.size != 1

        ApproveCommand.new(review_id: args[0])
      else
        raise UnsupportedCommandType, "Unsupported command type #{command_type.inspect}"
      end
    rescue Dry::Struct::Error => e
      raise CommandSyntaxError, "Invalid command argument: #{e.message}"
    end
  end

  class ApproveCommand < Dry::Struct
    attribute :review_id, Types::Coercible::String
  end
end
