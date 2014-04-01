module GDash
  class App < Sinatra::Base
    use Rack::Session::Cookie, :key => "gdash.session", :secret => Digest::SHA1.hexdigest("gdash.session")
    set :views, File.expand_path(File.join(File.dirname(__FILE__), "views"))
    set :public_folder, File.expand_path(File.join(File.dirname(__FILE__), "public"))

    helpers Helper

    before "/dashboards/*" do
      if params.has_key? "window"
        if params["window"] == "custom" and params.has_key?("start") and params.has_key?("end")
          start = DateTime.parse params["start"]
          stop = DateTime.parse params["end"]
          length = stop.to_i - start.to_i
          @window = Window.new :custom, :start => stop, :length => length.seconds, :title => "Custom"
        else
          @window = Window[params["window"]]
        end
      elsif session.has_key? :window
        @window = session[:window]
      else
        @window = Window.default
      end

      session[:window] = @window
    end

    get "/" do
      if Dashboard.all.empty?
        redirect doc_path(Doc.new(:getting_started))
      else
        haml :index, :layout => false
      end
    end

    not_found do
      haml :index, :layout => false
    end

    get "/doc/:filename" do
      @doc = Doc.new(params["filename"])
      erb @doc.to_html, :layout => :doc, :layout_engine => :haml
    end

    get "/doc" do
      redirect doc_path(Doc.new(:getting_started))
    end

    get "/dashboards/?*" do
      args = (params[:splat] || [""]).first.split(/\//).reject { |x| x.empty? }

      redirect "/dashboards/#{Dashboard.all.first.name}" if args.empty?

      @dashboard = Dashboard[args.shift]
      halt 404 unless @dashboard

      page = args.empty? ? @dashboard.pages.first : @dashboard.find(args.shift)
      halt 404 unless page

      tab_path = args

      haml View.new(@dashboard, :window => @window, :page => page, :tab_path => tab_path).to_html
    end

    get "/snapshot" do
      timestamp = DateTime.now.strftime("%Y%m%d%H%M%S")
      attachment "gdash-snapshot-#{timestamp}.tar.gz"
      stream do |out|
        Snapshot.generate! out
      end
    end
  end
end
