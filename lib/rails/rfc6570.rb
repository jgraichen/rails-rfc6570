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
      class Railtie < Rails::Railtie # :nodoc:
        initializer 'rails-rfc6570', :group => :all do |app|
          require 'rails/rfc6570/patches'

          ActiveSupport.on_load(:action_controller) do
            include Rails::RFC6570::Helper
            extend Rails::RFC6570::ControllerExtension
            Rails.application.routes.url_helpers.send :include,
              Rails::RFC6570::UrlHelper
          end
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

    module UrlHelper
      include Rails::RFC6570::Helper

      def respond_to_missing?(mth, include_private = false)
        if mth =~ /^(\w+)_rfc6570$/
          Rails.application.routes.named_routes.names.include?($1)
        else
          super
        end
      end

      def method_missing(mth, *args, &block)
        opts = args.first || {}
        case mth
          when /^(\w+)_path_rfc6570$/
            rfc6570_route $1, opts.merge(path_only: true)
          when /^(\w+)_url_rfc6570$/
            rfc6570_route $1, opts.merge(path_only: false) # independent of whatever future defaults
          when /^(\w+)_rfc6570$/
            rfc6570_route $1, opts
          else
            super
        end
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
