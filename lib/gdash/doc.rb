module GDash
  class Doc
    DIR = File.expand_path(File.join(File.dirname(__FILE__), %w{.. .. doc}))

    class << self
      def [] file
        Doc.new file
      end

      def all
        Dir[File.join(DIR, "*.md")].map do |f|
          f = $1 if f =~ /.*\/([^\/]+)\.md$/
          Doc.new f
        end
      end

      def each
        all.sort.each do |doc|
          yield doc if block_given?
        end
      end
    end

    attr_accessor :name

    def initialize name
      @name = name
    end

    def path
      File.join DIR, "#{name}.md"
    end

    def title
      name.to_s.titleize
    end

    def to_html
      MARKDOWN.render content
    end

    def <=> other
      name.to_s <=> ((other && other.name) || "").to_s
    end

    def == other
      name == (other && other.name)
    end

    private

    MARKDOWN = Redcarpet::Markdown.new Redcarpet::Render::XHTML.new

    def content
      content = nil
      File.open path, "r" do |f|
        content = f.read
      end
      content
    end
  end
end