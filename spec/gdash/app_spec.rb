require "spec_helper"

module GDash
  describe App do
    include Rack::Test::Methods

    let! :data_center do
      GDash::DataCenter.new :ganglia_host => "http://ganglia-host"
    end

    let! :dashboard do
      GDash.dashboard :foo do |foo|
        # foo.data_center = data_center
      end
    end

    describe "Root" do
      subject { get "/" }

      context "when dashboards are defined" do
        it { should be_ok }
        its(:body) { should_not be_empty }
      end

      context "when no dashboards are defined" do
        before { GDash::Dashboard.stub! :all => [] }
        it { should be_redirect }
      end
    end

    describe "Showing a dashboard" do
      describe "when :name is not a defined dashboard" do
        subject { get "/dashboards/foo" }

        it { should be_not_found }
        its(:body) { should =~ /Dashboards/ }
      end

      # describe :window do
      #   let!(:foo) { Window.define :foo }
      #   let!(:bar) { Window.define :bar }

      #   it "looks up the window" do
      #     get "/dashboards/foo?window=foo"
      #     dashboard.window.should == Window[:foo]
      #   end

      #   it "accepts custom time windows" do
      #     get "/dashboards/foo?window=custom&start=#{Rack::Utils.escape("2012-01-01 00:00:00")}&end=#{Rack::Utils.escape("2012-01-01 01:00:00")}"
      #     dashboard.window.start.should == DateTime.parse("2012-01-01 01:00:00")
      #     dashboard.window.length.should == 3600.seconds
      #   end

      #   it "uses the default window if not specified" do
      #     get "/dashboards/foo"
      #     dashboard.window.should == Window.default
      #   end
      # end
    end

    describe "Documentation" do
      subject { get "/doc" }
      it { should be_redirect }
    end

    describe "Showing a help page" do
      describe "when :page exists" do
        before do
          File.open File.expand_path(File.join(File.dirname(__FILE__), %w{.. .. doc foo.md})), "w" do |f|
            f.puts "# Test"
          end
        end
        after { File.unlink File.expand_path(File.join(File.dirname(__FILE__), %w{.. .. doc foo.md})) }

        subject { get "/doc/foo" }

        it { should be_ok }
        its(:body) { should =~ /<h1>\s*Test\s*<\/h1>/m }
      end
    end
  end
end
