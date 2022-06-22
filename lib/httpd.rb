load 'lib/get.rb'
load 'lib/post.rb'
module Bivouac
  
  class Httpd < Sinatra::Base
    helpers do
      def user i
        if i != nil
          @r = i
        else
          x = []; 16.times { x << rand(16).to_s(16) }
          @r = x.join('')
        end
        return @r
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
      @host = Bivouac[request.host]
      if "#{params[:u]}".length > 0
        @user = @host[params[:u]]
      end
      if "#{params[:e]}".length > 0
        @entity = @host[@host.qri[params[:e]]]
      end
      if "#{params[:b]}".length > 0
        @box = @host[params[:e]][params[:b]]
      end
      if request.request_method.upcase == 'GET'
        @app = Bivouac::Get.new(request, params);
      else
        @app = Bivouac::Post.new(request, params);
      end
      @id = user(@user)
      @qr = Bivouac.qr(@host.id)
    end
    get('/') { erb :index }
    get('/favicon.ico') {}
    get('/service-worker.js') {}
    get('/manifest.webmanifest') {}
    get('/robots.txt') {}
    get('/:entity') { @user = @host[params[:entity]]; erb :entity }
    get('/:entity/:app') { @user = @host[params[:entity]]; @zone = @host[params[:entity]][params[:app]]; erb :app }
    post('/') { b = Bivouac::Post.new(request, params); redirect b.goto }
    post('/auth') { @auth = Bivouac::Auth.new(@path, request, params); erb :auth }
    post('/box') { b = Bivouac::Remote.new(@path, request, params); redirect b.goto }
    post('/:entity') {
      if "#{params[:entity]}".length > 0
        # handle file upload
      end
      b = Bivouac::Post.new(request, params)
      redirect "#{@path}/#{b.goto}"
    }
  end
end
