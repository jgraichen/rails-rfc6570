# frozen_string_literal: true

module Rails
  module RFC6570
    module VERSION
      MAJOR = 3
      MINOR = 5
      PATCH = 1
      STAGE = nil

      STRING = [MAJOR, MINOR, PATCH, STAGE].compact.join('.').freeze

      def self.to_s
        STRING
      end
    end
  end
end
