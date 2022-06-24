load 'lib/get.rb'
load 'lib/post.rb'
load 'lib/auth.rb'
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
    end
    get('/') {
      @id = user(params[:entity])
      @entity = @host[@id]
      @qr = Bivouac.qr(@host.id)
      erb :index
    }
    get('/favicon.ico') {}
    get('/service-worker.js') {}
    get('/manifest.webmanifest') {}
    get('/robots.txt') {}
    get('/info') { erb :info }
    get('/:qri') { @entity = @host[@host.qri[params[:entity]]]; erb :entity }
    get('/:qri/:box') { @entity = @host[@host.qri[params[:qri]]]; @box = @host[@host.qri[params[:qri]]][params[:box]]; erb :app }
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
