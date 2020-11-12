# frozen_string_literal: true

require_relative 'spec_helper'
require_relative '../lib/command_parser'

describe 'Pulljoy.parse_command' do
  def parse_command(text)
    Pulljoy.parse_command(text)
  end


  it "returns nil if text doesn't contain the command prefix" do
    expect(parse_command('')).to be_nil
    expect(parse_command('hi')).to be_nil
  end

  it 'ignores leading whitespaces' do
    result = parse_command("  #{Pulljoy::COMMAND_PREFIX} approve 1234")
    expect(result).to be_kind_of(Pulljoy::ApproveCommand)
    expect(result.review_id).to eq('1234')
  end

  it 'ignores middle whitespaces' do
    result = parse_command("#{Pulljoy::COMMAND_PREFIX}   approve   1234")
    expect(result).to be_kind_of(Pulljoy::ApproveCommand)
    expect(result.review_id).to eq('1234')
  end

  it 'ignores trailing whitespaces' do
    result = parse_command("#{Pulljoy::COMMAND_PREFIX} approve 1234  ")
    expect(result).to be_kind_of(Pulljoy::ApproveCommand)
    expect(result.review_id).to eq('1234')
  end


  it 'parses the approve command' do
    result = parse_command("#{Pulljoy::COMMAND_PREFIX} approve 1234")
    expect(result).to be_kind_of(Pulljoy::ApproveCommand)
    expect(result.review_id).to eq('1234')
  end
end
