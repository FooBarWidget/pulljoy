# frozen_string_literal: true

require 'openssl'
require_relative 'spec_helper'

GITHUB_SIGNATURE_DIGEST_TYPE = 'sha1'
GITHUB_SIGNATURE_DIGEST = OpenSSL::Digest.new(GITHUB_SIGNATURE_DIGEST_TYPE)

def create_github_webhook_signature(payload)
  sig = OpenSSL::HMAC.hexdigest(
    GITHUB_SIGNATURE_DIGEST,
    PULLJOY_TEST_CONFIG.github_webhook_secret,
    payload
  )
  "#{GITHUB_SIGNATURE_DIGEST_TYPE}=#{sig}"
end
