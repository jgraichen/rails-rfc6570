# frozen_string_literal: true

module Rails
  module RFC6570
    module VERSION
      MAJOR = 2
      MINOR = 1
      PATCH = 0
      STAGE = nil

      STRING = [MAJOR, MINOR, PATCH, STAGE].reject(&:nil?).join('.').freeze

      def self.to_s
        STRING
      end
    end
  end
end
