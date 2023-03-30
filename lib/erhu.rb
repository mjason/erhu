# frozen_string_literal: true
require_relative "erhu/init"
require_relative "erhu/version"
require_relative "erhu/app"
require_relative "erhu/cli"

module Erhu
  class Error < StandardError; end
  # Your code goes here...

  module_eval do
    Dotenv.load
  end
end