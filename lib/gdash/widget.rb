module GDash
  class Widget
    class << self
      def inherited widget
        define_method widget.name.demodulize.underscore do |*args, &block|
          add_child widget.new(*args, &block)
        end
      end
    end

    attr_accessor :parent, :window, :ganglia_host, :graphite_host, :cacti_host, :nagios_host, :nagios_username, :nagios_password

    def initialize options = {}
      options.each do |k, v|
        send :"#{k}=", v if respond_to? :"#{k}="
      end

      yield self if block_given?
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

    def ganglia_host
      @ganglia_host || (parent && parent.ganglia_host)
    end

    def graphite_host
      @graphite_host || (parent && parent.graphite_host)
    end

    def cacti_host
      @cacti_host || (parent && parent.cacti_host)
    end

    def nagios_host
      @nagios_host || (parent && parent.nagios_host)
    end

    def nagios_username
      @nagios_username || (parent && parent.nagios_username)
    end

    def nagios_password
      @nagios_password || (parent && parent.nagios_password)
    end

    def window
      @window || (parent && parent.window) || Window.default
    end

    private

    def add_child obj
      children << obj
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