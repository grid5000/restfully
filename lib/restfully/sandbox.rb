require 'forwardable'

module Restfully
  class Sandbox
    extend Forwardable

    def_delegators :@session, :head, :get, :post, :put, :delete, :root, :logger

    attr_reader :session

    def initialize(session)
      @session = session
    end

  end
end