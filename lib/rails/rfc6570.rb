# frozen_string_literal: true

require 'action_dispatch/journey'

require 'rails/rfc6570/formatter'
require 'rails/rfc6570/version'
require 'rails/rfc6570/visitor'

module Rails
  module RFC6570
    if defined?(::Rails::Railtie)
      class Railtie < ::Rails::Railtie # :nodoc:
        initializer 'rails-rfc6570', group: :all do |_app|
          require 'rails/rfc6570/patches'

          ::ActionDispatch::Routing::RouteSet.include \
            Rails::RFC6570::Extensions::RouteSet

          ::ActionDispatch::Routing::RouteSet::NamedRouteCollection.prepend \
            Rails::RFC6570::Extensions::NamedRouteCollection

          ::ActionDispatch::Journey::Route.include \
            Rails::RFC6570::Extensions::JourneyRoute

          ::ActiveSupport.on_load(:action_controller) do
            include Rails::RFC6570::Helper
            extend Rails::RFC6570::ControllerExtension
          end
        end
      end
    end

    module Extensions
      module RouteSet
        def to_rfc6570(**opts)
          named_routes.to_rfc6570(**opts)
        end
      end

      module NamedRouteCollection
        def to_rfc6570(**opts)
          routes.to_h {|name, route| [name, route.to_rfc6570(**opts)] }
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
              route.to_rfc6570(**opts, ctx: self)
            end

            define_method(rfc6570_url_name) do |opts = {}|
              route.to_rfc6570(**opts, ctx: self, path_only: false)
            end

            define_method(rfc6570_path_name) do |opts = {}|
              route.to_rfc6570(**opts, ctx: self, path_only: true)
            end
          end

          set << rfc6570_name
          set << rfc6570_url_name
          set << rfc6570_path_name
        end

        def add(name, route)
          super
          define_rfc6570_helpers name, route, @url_helpers_module, @url_helpers
        end

        alias []= add
      end

      module JourneyRoute
        def to_rfc6570(**opts)
          @rfc6570_formatter ||= RFC6570::Formatter.new(self)
          @rfc6570_formatter.evaluate(**opts)
        end
      end
    end

    module Helper
      def rfc6570_routes(**opts)
        _routes.named_routes.to_rfc6570(**opts, ctx: self)
      end

      def rfc6570_route(name, **opts)
        route = _routes.named_routes[name]
        raise KeyError.new "No named routed for `#{name}'." unless route

        route.to_rfc6570(**opts, ctx: self)
      end
    end

    module ControllerExtension
      def rfc6570_defs
        @rfc6570_defs ||= {}
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
      ctr.rfc6570_params_for(action.to_sym) if ctr.respond_to?(:rfc6570_params_for)
    rescue NameError
      nil
    end

    extend self # rubocop:disable Style/ModuleFunction
  end
end
