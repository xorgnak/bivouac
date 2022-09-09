load 'lib/get.rb'
load 'lib/post.rb'
load 'lib/auth.rb'
module Bivouac
  
  class Httpd < Sinatra::Base
    helpers do
      def user i
        if i != nil
          @r = i
        elsif /.+@.+/.match(i)
          @r = i.split('@')[0]
        else
          x = []; 16.times { x << rand(16).to_s(16) }
          @r = x.join('')
        end
        return @r
      end
      def visitor e
        v = "#{e}-#{@mark}-#{@now}"
        @host[e].visitors << v
        return @host[v]
      end
    end
    configure do
      set :sockets, []
      set :server, 'thin'
      set :views, %[#{Dir.pwd}/views]
      set :public_folder, %[#{Dir.pwd}/public]
      set :bind, '0.0.0.0'
      set :port, 4567
    end
    before do
      @now = "#{Time.now.utc.to_f}"
      @host = Bivouac[request.host]
      @qr = Bivouac.qr(@host.id)
      if params.has_key? :mark
        @mark = params[:mark]
      else
        m = ['Dx']; 14.times {m << rand(16).to_s(16)} 
        @mark = m.join('')
      end
      @host.at[@now] = @mark
      @host.dx[@mark] = @now
    end
    
    get('/') {
      @id = user(params[:entity])
      @map = @host.map[@id]
      @entity = @host[@id]
      if @host.is[:remote] == true 
        erb :index
      else
        erb :local
      end
    }
    get('/favicon.ico') {}
    get('/service-worker.js') { @entity = @host[params[:entity]]; erb :service_worker, layout: false }
    get('/manifest.webmanifest') { erb :manifest, layout: false }
    get('/robots.txt') {}
    get('/info') { erb :info }
    get('/box') { @entity = @host[@host.qri[params[:qri]]]; erb :box }
    post('/poll') {
      content_type 'application/json'
      Redis.new.publish('/poll', "#{params}")
      return params
    }
    post('/chan') {
      content_type 'application/json'
      ret = Bivouac.broker.publish({
                                      topic: params[:topic],
                                      payload: params[:payload]
                                    })
      return JSON.generate({ status: ret })
    }
    get('/t') {
      if params.has_key?(:target);
        @target = Bivouac.target(params[:target]);
      end;
      @id = user(params[:entity])
      @entity = @host[@id]
      erb :target
    }
    get('/q') {
      @tgt = Bivouac.target(@params[:t])
      redirect %[#{@host.pre}://#{@host.host}/#{@tgt.attr[:goto]}]
    }
    get('/:qri') {
#      @browser = Browser.new(:ua => request.user_agent, :accept_language => "en-us")
      @entity = @host[@host.qri[params[:qri]]];
      @entity.browser.incr(request.user_agent)
      @visitor = visitor(@entity.id);
      @map = @host.map[@entity.id]
      @entity.stat.incr(:xp)
      erb :entity
    }
    get('/:qri/:box') {
#      @browser = Browser.new(:ua => request.user_agent, :accept_language => "en-us")
      @entity = @host[@host.qri[params[:qri]]];
      @entity.browser.incr(request.user_agent)
      @visitor = visitor(@entity.id);
      @box = @host[@host.qri[params[:qri]]][params[:box]];
      @box.browser.incr(request.user_agent)
      @map = @host.map[@entity.id][@box.id]
      @entity.karma.incr(@box.id)
      @box.bank.give user: @entity.id, type: :credits, amt: @box.stat[:click]
      @box.bank.give user: @entity.id, type: :karma
      @box.traffic.incr(@entity.id);
      erb :app
    }

    post('/') { b = Bivouac::Post.new(request, params); redirect b.goto }

    post('/tgt') {
      content_type 'application/json'
      b = Bivouac::Post.new(request, params);
      return b.json
    }
    
    post('/auth') { b = Bivouac::Auth.new(request, params); redirect b.goto }

    post('/box') {
      content_type "application/json"
      b = Bivouac::Post.new(request, params);
      #Redis.new.publish "POST", "#{b}" 
      return b.json
    }

    post('/:qri') {
      content_type 'application/json'
      b = Bivouac::Post.new(request, params)
      return b.json
    }
  end
end
