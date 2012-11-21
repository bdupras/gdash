module GDash
  class Widget
    class << self
      def define name, options = {}, &block
        name = name.to_s

        if widget = Widget[name]
          options.each do |k, v|
            widget.send :"#{k}=", v if widget.respond_to? :"#{k}="
          end
          yield widget if block_given?
        else
          Widget[name] = new(options.merge(:name => name), &block)
        end

        Widget[name]
      end

      def [] name
        widgets[name.to_s]
      end

      def []= name, widget
        widgets[name.to_s] = widget
      end

      private

      def widgets
        @widgets ||= {}
      end
    end

    attr_accessor :name, :parent, :window, :tags

    def initialize options = {}
      options.each do |k, v|
        send :"#{k}=", v if respond_to? :"#{k}="
      end

      yield self if block_given?
    end

    def tags
      @tags ||= []
    end

    def tag t
      tags << t.to_s
    end

    def tagged? matcher
      self_tagged = if matcher.is_a? Regexp
                      tags.any? do |t|
                        t =~ matcher
                      end
                    else
                      tags.include?(matcher.to_s)
                    end

      child_tagged = children.any? do |child|
                       child.tagged? matcher
                     end

      self_tagged || child_tagged
    end

    def clone
      fail "Should be overridden in #{self.class.name}"
    end

    def filter pattern
      if tagged? pattern
        cloned = clone
        children.each do |child|
          child = child.filter pattern
          if child
            child.parent = cloned
            cloned.children << child
          end
        end
        cloned
      end
    end

    [:dashboard, :ganglia_graph, :ganglia_report, :cacti_graph].each do |widget|
      define_method widget do |*args, &block|
        add_child GDash.const_get(widget.to_s.camelize).define(*args, &block)
      end
    end

    [:section, :nagios].each do |widget|
      define_method widget do |*args, &block|
        add_child GDash.const_get(widget.to_s.camelize).new(*args, &block)
      end
    end

    def children
      @children ||= []
    end

    def renderable_children
      children.reject do |child|
        child.is_a? Dashboard
      end
    end

    def nested_dashboards
      children.select do |child|
        child.is_a? Dashboard
      end.sort
    end

    def nested_dashboards?
      nested_dashboards.present?
    end

    def data_center
      @data_center || (parent && parent.data_center)
    end

    def data_center= data_center
      @data_center = data_center.is_a?(DataCenter) ? data_center : DataCenter[data_center]
    end

    def window
      @window || (parent && parent.window) || Window.default
    end

    private

    def add_child obj
      children << obj unless children.include?(obj)
      obj.parent = self
      obj
    end

    def child_groups n
      groups = []
      i = 0
      renderable_children.each do |child|
        if i == 0
          groups << []
        end

        groups.last << child
        i = (i + 1) % width
      end
      groups
    end
  end
end