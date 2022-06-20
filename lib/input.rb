
module Bivouac
  def self.form *i, &b
    f = Input.new
    if block_given?
      b.call(f)
    end
    if i[0]
      self.instance_eval %[@b = lambda {|form| #{i[0]} }]
      @b.call(f)
    end
    f.output
  end
class Input
  def initialize
    @out = []
  end
  def datalist n, *a
    o = [%[<datalist id='#{n}'>]]
    a.each { |e| o << %[<option value='#{e}'>] }
    o << %[</datalist>]
    @out << o.join('')
  end
  def select n, h={}
    o = [%[<select name='#{n}'>]]
    h.each_pair { |k,v| o << %[<option value='#{v}'>#{k}</option>] }
    o << %[</select>]
    @out << o.join('')
  end
  def textarea n, &b
    @out << %[<textarea name='#{n}'>#{b.call}</textarea>]
  end
  def input n, h={}
    if h.has_key? :list
      l = "list='#{h.delete(:list)}'"
    end
    v = h.delete(:val)
    if h.has_key? :id
      i = "id='#{h.delete(:id)}'"
    end
    t = h.delete(:type)
    if h.has_key? :placeholder
      p = "placeholder='#{h.delete(:placeholder)}'"
    end
    if h.has_key? :class
      c = h[:class].join(' ')
    end
    @out << %[<input type='#{t}' #{l} #{i} #{c} name='#{n}' value='#{v}'>]
  end
  def output
    @out.join('')
  end
end
end
