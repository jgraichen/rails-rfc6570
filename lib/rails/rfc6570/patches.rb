# frozen_string_literal: true

require 'addressable/uri'
require 'addressable/template'

module Addressable
  class URI
    def as_json(*)
      to_s
    end
  end

  class Template
    def to_s
      pattern
    end

    def as_json(*)
      pattern
    end
  end
end
