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
      erb :target
    }
    
    get('/:qri') {
      @entity = @host[@host.qri[params[:qri]]];
      @visitor = visitor(@entity.id);
      @map = @host.map[@entity.id]
      @entity.stat.incr(:xp)
      erb :entity
    }
    get('/:qri/:box') {
      @entity = @host[@host.qri[params[:qri]]];
      @visitor = visitor(@entity.id);
      @box = @host[@host.qri[params[:qri]]][params[:box]];
      @map = @host.map[@entity.id][@box.id]
      @entity.karma.incr(@box.id)
      @box.bank.give user: @entity.id, type: :credits, amt: @box.stat[:click]
      @box.bank.give user: @entity.id, type: :karma
      @box.traffic.incr(@entity.id);
      erb :app
    }

    post('/') { b = Bivouac::Post.new(request, params); redirect b.goto }
    
    post('/auth') { b = Bivouac::Auth.new(request, params); redirect b.goto }

    post('/box') { b = Bivouac::Remote.new(@path, request, params); redirect b.goto }

    post('/:qri') {
      content_type 'application/json'
      b = Bivouac::Post.new(request, params)
      return b.json
    }
  end
end
