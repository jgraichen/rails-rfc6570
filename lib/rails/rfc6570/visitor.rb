# frozen_string_literal: true

module Rails
  module RFC6570
    class Visitor < ::ActionDispatch::Journey::Visitors::Visitor
      DISPATCH_CACHE = {} # rubocop:disable MutableConstant

      def initialize(factory: nil)
        super()

        @stack   = []
        @factory = factory || method(:symbolize)
      end

      def accept(node)
        Array(visit(node)).flatten
      end

      def visit(node)
        @stack.unshift node.type
        send DISPATCH_CACHE.fetch(node.type), node
      ensure
        @stack.shift
      end

      def terminal(node)
        node.left
      end

      # rubocop:disable MethodName
      def visit_CAT(node)
        if (mth = DISPATCH_CACHE[:"#{node.left.type}_#{node.right.type}"])
          send mth, node.left, node.right
        else
          [visit(node.left), visit(node.right)]
        end
      end

      def visit_LITERAL(node)
        terminal(node)
      end

      def visit_SLASH(node)
        terminal(node)
      end

      def visit_DOT(node)
        terminal(node)
      end

      def visit_SYMBOL(node)
        symbol(node)
      end

      def visit_OR(_node)
        raise 'OR nodes cannot be serialized to URI templates'
      end

      def visit_GROUP(node)
        # if @stack.include?(:GROUP) && @stack[1..-1].include?(:GROUP)
        #   raise 'Cannot transform nested groups.'
        # end

        visit node.left
      end

      def visit_DOT_SYMBOL(dot, node)
        if @stack[0..1] == %i[CAT GROUP]
          symbol(node, prefix: '.')
        else
          [visit(dot), visit(node)]
        end
      end

      def visit_SLASH_SYMBOL(slash, node)
        if @stack[0..1] == %i[CAT GROUP]
          symbol(node, prefix: '/')
        else
          [visit(slash), visit(node)]
        end
      end

      # rubocop:disable AbcSize
      def visit_SLASH_CAT(slash, cat)
        if cat.left.type == :STAR
          [symbol(cat.left.left, prefix: '/', suffix: '*'), visit(cat.right)]
        elsif cat.left.type == :SYMBOL && @stack[0..1] == %i[CAT GROUP]
          [symbol(cat.left, prefix: '/'), visit(cat.right)]
        else
          [visit(slash), visit(cat)]
        end
      end
      # rubocop:enable AbcSize

      def visit_SLASH_STAR(_slash, star)
        symbol(star.left, prefix: '/', suffix: '*')
      end

      def visit_STAR_CAT(star, cat)
        [symbol(star.left, prefix: '/', suffix: '*'), visit(cat)]
      end
      # rubocop:enable MethodName

      instance_methods(true).each do |meth|
        next unless meth =~ /^visit_(.*)$/

        DISPATCH_CACHE[Regexp.last_match(1).to_sym] = meth
      end

      private

      def symbol(node, **kwargs)
        @factory.call(node, **kwargs)
      end

      def symbolize(node, prefix: nil, suffix: nil)
        "{#{prefix}#{node.name}#{suffix}}"
      end
    end
  end
end
