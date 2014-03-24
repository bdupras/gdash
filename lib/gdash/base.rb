module GDash
  class Base
    class << self
      def inherited subclass
        (class << GDash; self; end).send :define_method, subclass.to_s.demodulize.underscore do |*args, &block|
          subclass.define *args, &block
        end
      end

      def define *args, &block
        new *args, &block
      end

      def attr *args, &block
        options = args.extract_options!
        options[:default] ||= block if block_given?

        args.each do |name|
          instance_variable = "@#{name}"

          attrs << name.to_sym

          define_method name do |*args|
            if args.length == 0
              if instance_variable_get(instance_variable).nil?
                if options.has_key?(:default)
                  if options[:default].is_a? Proc
                    yld &options[:default]
                  else
                    default = (options[:default].is_a?(Array) || options[:default].is_a?(Hash)) ? options[:default].dup : options[:default]
                    instance_variable_set instance_variable, default
                    instance_variable_get instance_variable
                  end
                elsif @prototype.present? && @prototype.respond_to?(name)
                  @prototype.send name
                end
              else
                instance_variable_get instance_variable
              end
            else
              instance_variable_set instance_variable, *args
            end
          end

          attr_writer name
        end
      end

      ## TODO - Cuz says, "Make this suck less"
      def compare_order x, y
        if (x.is_a?(Base) && x.options.has_key?(:before) && x.options[:before] == :all) && (y.is_a?(Base) && y.options.has_key?(:before) && y.options[:before] == :all)
          0
        elsif (x.is_a?(Base) && x.options.has_key?(:before) && x.options[:before] == :all)
          -1
        elsif (y.is_a?(Base) && y.options.has_key?(:before) && y.options[:before] == :all)
          1
        else
          0
        end
      end

      def collection name, options = {}, &block
        instance_variable = "@#{name.to_s.pluralize}"
        options = { :default => [], :prototype => true }.merge options

        attrs << name.to_s.pluralize.to_sym

        define_method name.to_s.pluralize do |*args|
          if args.length == 0
            default = (options[:default].is_a?(Array) || options[:default].is_a?(Hash)) ? options[:default].dup : options[:default]
            proto = (options[:prototype] && @prototype.present? && @prototype.respond_to?(name)) ? @prototype.send(name) : default
            instance_variable_set instance_variable, [] if instance_variable_get(instance_variable).nil?

            (proto + instance_variable_get(instance_variable)).sort &Base.method(:compare_order)
          else
            instance_variable_set instance_variable, *args
          end
        end

        attr_writer name.to_s.pluralize

        define_method name.to_s.singularize do |*args, &block|
          if options.has_key? :class
            if options[:class].is_a? Base
              args = [options[:class].define(*args, &block)]
            else
              args = [options[:class].new(*args, &block)]
            end
          end
          instance_variable_set(instance_variable, []) if instance_variable_get(instance_variable).nil?
          instance_variable_get(instance_variable).send(:<<, *args)
        end
      end

      def attrs
        if self == Base
          @attrs ||= []
        else
          @attrs ||= [] + superclass.attrs
        end
      end
    end

    attr :name, :title, :description, :prototype
    attr :options, :default => {}

    def initialize name, options = {}, &block
      options = options.with_indifferent_access
      self.prototype = options.delete :prototype
      self.name = name.to_s
      self.title = self.name.titleize
      self.options = options.except(*self.class.attrs)

      options.slice(*self.class.attrs).each do |k, v|
        send :"#{k}=", v
      end

      yld &block
    end

    def options options = nil
      proto = (@prototype.present? && @prototype.respond_to?(:options)) ? @prototype.options : {}
      @options ||= {}
      @options.merge! options if options

      proto.merge(@options).with_indifferent_access
    end

    def to_hash
      {}.with_indifferent_access.merge(options).tap do |opts|
        self.class.attrs.each do |attr|
          opts[attr] = send(attr)
        end
      end
    end

    def yld &block
      if block_given?
        if block.arity < 1
          instance_eval &block
        else
          yield self
        end
      end
    end
  end
end