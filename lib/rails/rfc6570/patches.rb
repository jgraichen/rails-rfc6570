require 'action_dispatch'
require 'action_dispatch/journey'
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

module ActionDispatch
  module Routing
    class RouteSet
      def to_rfc6570(opts = {})
        routes.map{|r| r.to_rfc6570(opts) }
      end

      class NamedRouteCollection
        def to_rfc6570(opts = {})
          Hash[routes.map{|n, r| [n, r.to_rfc6570(opts)] }]
        end
      end
    end
  end

  module Journey
    class Route
      def to_rfc6570(opts = {})
        path.spec.to_rfc6570 opts.merge(route: self)
      end
    end

    class Nodes::Node
      def to_rfc6570(opts = {})
        ::Addressable::Template.new Visitors::RFC6570.new(opts).accept(self)
      end
    end
  end
end
