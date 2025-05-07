# frozen_string_literal: true

module Rails
  module RFC6570
    class Formatter
      attr_reader :route

      def initialize(route)
        @route = route
        @parts = Visitor.new(factory: method(:symbol)).accept(route.path.spec)
      end

      def evaluate(ctx:, ignore: %w[format], **kwargs)
        parts = @parts.reject do |part|
          part.is_a?(Subst) && ignore.include?(part.name)
        end

        if kwargs.fetch(:params, true) && route
          controller = route.defaults[:controller].to_s
          action     = route.defaults[:action].to_s

          if controller.present? && action.present?
            params = ::Rails::RFC6570.params_for(controller, action)
            parts << "{?#{params.join(',')}}" if params&.any?
          end
        end

        if kwargs.fetch(:path_only, false)
          ::Addressable::Template.new parts.join
        else
          options = ctx.url_options.merge(kwargs)
          options[:path] = parts.join

          if (osn = options.delete(:original_script_name))
            options[:script_name] = osn + options[:script_name]
          end

          ::Addressable::Template.new \
            ActionDispatch::Http::URL.url_for(options)
        end
      end

      def symbol(node, prefix: nil, suffix: nil)
        Subst.new(node.name, "{#{prefix}#{node.name}#{suffix}}")
      end

      Subst = Struct.new(:name, :string) do
        alias_method :to_s, :string
      end
    end
  end
end
