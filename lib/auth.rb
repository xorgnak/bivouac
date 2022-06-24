module Bivouac
  class Auths
    include Redis::Objects
    hash_key :cha
    hash_key :ids
    hash_key :ent
    def initialize i
      @id = i
    end
    def id; @id; end
  end
  class Auth
    def initialize request, params
      @auth = Auths.new(request.host)
      @host = Bivouac[request.host]
      @request, @params, @args = request, params, {}
      Redis.new.publish('Auth', %[#{@params}])
      if @params.has_key?(:set)
        @host[@params[:set]].attr[:pin] = @params[:pin]
        @args[:entity] = @params[:set]
      end
      
      if "#{@params[:usr]}".length > 0
        if !@auth.ids.has_key? @params[:usr]
          # auth register
          @auth.ids[@params[:usr]] = @params[:entity]
          @auth.ent[@params[:entity]] = @params[:usr]
          @args[:set] = @params[:entity]
        else
          # auth challange ask
          cha = []; 16.times { cha << rand(16).to_s(16) }
          @args[:cha] = cha.join('')
          @auth.cha[cha.join('')] = @auth.ids[@params[:usr]]
        end
      end
      if @params.has_key? :cha
        # auth challange response
        if @host[@auth.cha[@params[:cha]]].attr[:pin] == @params[:pin]
          @args[:entity] = @auth.cha[@params[:cha]]
          @auth.cha.delete(@params[:cha])
        end
      end
    end
    def goto
      if @args.keys.length > 0
        args = []; @args.each_pair { |k,v| args << %[#{k}=#{v}] }
        %[https://#{@request.host}/?#{args.join('&')}]
      else
        %[https://#{@request.host}]
      end
    end
  end
end
