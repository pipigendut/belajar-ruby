# include => instance method
# extend => class method

require 'pry'

class Mobil
  attr_accessor :roda, :kaca, :pintu

  def initialize(x: , y:)
    @x, @y = x, y
    puts @x
    puts @y
  end

  def self.jalan_mundur #class method
    puts 'jalan mundur'
  end

  def jalan_kedepan #instance method
    puts 'jalan kedepan'
  end
end

class Motor
  include Mobil
  attr_accessor :roda, :kaca, :pintu

  def initialize(args)
    x, y = args
    puts x
    puts y
    puts @args
  end
end

class Becak
  attr_accessor :roda, :kaca, :pintu

  def initialize(*args)
    puts args
  end
end

class Food
  def nutrition(vitamin, staff)
    puts vitamin
  end
end
class Bacon < Food
  def nutrition(*args)
    super
  end

  def asa(*args)
    super
  end
end

bacon = Bacon.new
bacon.nutrition("B6", "Iron")

def testing(a, b = 1, *c, d: 1, **x)
  p a,b,c,d,x
end

testing('a', 'b', 'c', 'd', 'e', d: 2, x: 1)

mobil = Mobil.new(x: 10, y: 20)
motor = Motor.new(x: 10, y: 20)
becak = Becak.new(x: 10, y: 20)


# puts mobil:Class
#
# puts 'METHODS MOBIL'
# puts Mobil.methods
#
# puts 'INSTANCE METHODS'
# puts Mobil.instance_methods

Mobil.jalan_mundur
mobil.jalan_kedepan
