# frozen_string_literal: true

module Rails
  module RFC6570
    module VERSION
      MAJOR = 3
      MINOR = 4
      PATCH = 0
      STAGE = nil

      STRING = [MAJOR, MINOR, PATCH, STAGE].compact.join('.').freeze

      def self.to_s
        STRING
      end
    end
  end
end
