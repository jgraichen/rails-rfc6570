require 'rails/rfc6570/version'

module ActionDispatch
  module Journey
    module Visitors
      class RFC6570 < String
        def initialize(opts = {})
          super()

          @opts        = opts
          @stack       = []
          @group_depth = 0
        end

        def ignore
          @opts.fetch(:ignore) { %w(format) }
        end

        def route
          @route ||= @opts[:route]
        end

        def accept(node)
          str = super

          if @opts.fetch(:params, true) && route
            controller = route.defaults[:controller].to_s
            action     = route.defaults[:action].to_s

            if controller.present? && action.present?
              params = Rails::RFC6570.params_for(controller, action)
              str += '{?' + params.join(',') + '}' if params && params.any?
            end
          end

          str
        end

        def visit(node)
          @stack.unshift node.type
          super node
        ensure
          @stack.shift
        end

        def symbol_name(node)
          name = node.to_s.tr '*:', ''

          if ignore.include?(name)
            nil
          else
            name
          end
        end

        def placeholder(node, prefix = nil, suffix = nil, pretext = nil)
          name = symbol_name node
          if name
            "#{pretext}{#{prefix}#{name}#{suffix}}"
          else
            ''
          end
        end

        def visit_SYMBOL(node)
          placeholder node
        end

        def binary(node)
          case [node.left.type, node.right.type]
            when [:DOT, :SYMBOL]
              if @stack[0..1] == [:CAT, :GROUP]
                placeholder node.right, '.'
              else
                placeholder(node.right, nil, nil, '.')
              end
            when [:SLASH, :SYMBOL]
              if @stack[0..1] == [:CAT, :GROUP]
                placeholder(node.right, '/')
              else
                placeholder(node.right, nil, nil, '/')
              end
            when [:SLASH, :STAR]
              placeholder node.right, '/', '*'
            when [:SLASH, :CAT]
              if node.right.left.type == :STAR
                placeholder(node.right.left, '/', '*') + visit(node.right.right)
              else
                super
              end
            when [:CAT, :STAR]
              visit(node.left).to_s.gsub(/\/+$/, '') + placeholder(node.right, '/', '*')
            else
              super
          end
        end

        def visit_GROUP(node)
          if @group_depth >= 1
            raise RuntimeError.new \
              'Cannot transform nested groups.'
          else
            @group_depth += 1
            visit node.left
          end
        ensure
          @group_depth -= 1
        end
      end
    end
  end
end

module Rails
  module RFC6570
    if defined?(::Rails::Railtie)
      class Railtie < ::Rails::Railtie # :nodoc:
        initializer 'rails-rfc6570', :group => :all do |app|
          require 'rails/rfc6570/patches'
          require 'action_dispatch/journey'

          MAJOR = Rails::VERSION::MAJOR
          MINOR = Rails::VERSION::MINOR

          ::ActionDispatch::Routing::RouteSet.send :include,
            Rails::RFC6570::Extensions::RouteSet

          if MAJOR == 4 && (0..1).include?(MINOR)
            ::ActionDispatch::Routing::RouteSet::NamedRouteCollection.send \
              :prepend, Rails::RFC6570::Extensions::NamedRouteCollection40
          else
            ::ActionDispatch::Routing::RouteSet::NamedRouteCollection.send \
              :prepend, Rails::RFC6570::Extensions::NamedRouteCollection42
          end

          ::ActionDispatch::Routing::RouteSet::NamedRouteCollection.send \
            :include, Rails::RFC6570::Extensions::NamedRouteCollection

          ::ActionDispatch::Journey::Route.send :include,
            Rails::RFC6570::Extensions::JourneyRoute

          ::ActionDispatch::Journey::Nodes::Node.send :include,
            Rails::RFC6570::Extensions::JourneyNode

          ::ActiveSupport.on_load(:action_controller) do
            include Rails::RFC6570::Helper
            extend Rails::RFC6570::ControllerExtension
          end
        end
      end
    end

    module Extensions
      module RouteSet
        def to_rfc6570(opts = {})
          routes.map{|r| r.to_rfc6570(opts) }
        end
      end

      module NamedRouteCollection
        def to_rfc6570(opts = {})
          Hash[routes.map{|n, r| [n, r.to_rfc6570(opts)] }]
        end

        def define_rfc6570_helpers(name, route, mod, set)
          rfc6570_name      = :"#{name}_rfc6570"
          rfc6570_url_name  = :"#{name}_url_rfc6570"
          rfc6570_path_name = :"#{name}_path_rfc6570"

          [rfc6570_name, rfc6570_url_name, rfc6570_path_name].each do |helper|
            mod.send :undef_method, helper if mod.respond_to? helper
          end

          mod.module_eval do
            define_method(rfc6570_name) do |opts = {}|
              template = route.to_rfc6570(opts)

              if opts.fetch(:path_only, false)
                template
              else
                root_uri = Addressable::URI.parse(root_url)

                Addressable::Template.new root_uri.join(template.pattern).to_s
              end
            end

            define_method(rfc6570_url_name) do |opts = {}|
              send rfc6570_name, opts.merge(path_only: false)
            end

            define_method(rfc6570_path_name) do |opts = {}|
              send rfc6570_name, opts.merge(path_only: true)
            end
          end

          set << rfc6570_name
          set << rfc6570_url_name
          set << rfc6570_path_name
        end
      end

      module NamedRouteCollection40
        def to_rfc6570(opts = {})
          Hash[routes.map{|n, r| [n, r.to_rfc6570(opts)] }]
        end

        def add(name, route)
          define_rfc6570_helpers name, route, @module, @helpers
          super
        end

        alias_method :[]=, :add
      end

      module NamedRouteCollection42
        def helper_names
          super
        end

        def add(name, route)
          define_rfc6570_helpers name, route, @url_helpers_module, @url_helpers
          super
        end

        alias_method :[]=, :add
      end

      module JourneyRoute
        def to_rfc6570(opts = {})
          path.spec.to_rfc6570 opts.merge(route: self)
        end
      end

      module JourneyNode
        def to_rfc6570(opts = {})
          ::Addressable::Template.new \
            ::ActionDispatch::Journey::Visitors::RFC6570.new(opts).accept(self)
        end
      end
    end

    module Helper
      def rfc6570_routes(opts = {})
        routes = {}
        Rails.application.routes.named_routes.names.each do |key|
          routes[key] = rfc6570_route(key, opts)
        end

        routes
      end

      def rfc6570_route(name, opts = {})
        route    = Rails.application.routes.named_routes[name]
        unless route
          raise KeyError.new "No named routed for `#{name}'."
        end

        template = route.to_rfc6570(opts)

        if opts.fetch(:path_only, false)
          template
        else
          root_uri = Addressable::URI.parse(root_url)

          Addressable::Template.new root_uri.join(template.pattern).to_s
        end
      end
    end

    module ControllerExtension
      def rfc6570_defs
        @__rfc6570_defs ||= {}
      end

      def rfc6570_params(defs)
        rfc6570_defs.merge! defs
      end

      def rfc6570_params_for(defs)
        rfc6570_defs[defs]
      end
    end

    def params_for(controller, action)
      ctr = "#{controller.camelize}Controller".constantize
      ctr.rfc6570_defs[action.to_sym] if ctr.respond_to?(:rfc6570_defs)
    rescue NameError
      nil
    end
    extend self
  end
end
