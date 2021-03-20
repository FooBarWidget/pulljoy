# frozen_string_literal: true

module Pulljoy
  # A generic factory for creating objects of a certain class.
  # That class' constructor must only accept keyword arguments.
  #
  # We use this in order to be able to mock Sinatra helper methods
  # in tests.
  class Factory
    def initialize(klass, **args)
      @klass = klass
      @args = args
    end

    def create
      @klass.new(**args)
    end
  end
end
