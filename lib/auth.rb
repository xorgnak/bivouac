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
      @request, @params, @args = request, params, {}
      Redis.new.publish('Auth', %[#{@request} #{@params}])
      if @params.has_key?(:set)
        Bivouac[request.host][@params[:set]].attr[:pin] = @params[:pin]
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
          @auth.cha[cha.join('')] = @params[:usr]
        end
      end
      if "#{@params[:cha]}".length > 0
        # auth challange response
        if Bivouac[request.host][@auth.cha[@params[:cha]]].attr[:pin] == @params[:pin]
          @args[:entity] = @auth.cha[@params[:cha]]
          @auth.cha.delete(@params[:cha])
        end
      end
    end
    def goto
      args = []; @args.each_pair { |k,v| args << %[#{k}=#{v}] }
      %[https://#{@request.host}/?#{args.join('&')}]
    end
  end
end
