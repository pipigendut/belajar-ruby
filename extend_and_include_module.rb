# include => instance method
# extend => class method

require 'pry'

module ModuleExample
  attr_accessor :foo

  def foo
    'foo'
  end
end

# Including modules binds the methods to the object instance
class Person
  include ModuleExample

  def initialize()
    puts foo
  end

  def baba

  end

  def foo
    puts method(:foo).super_method.call
    puts 'fooo'
  end
end

# Extending modules binds the methods to the class itself
class Book
  extend ModuleExample

  def initialize()
    puts foo
  end
end


# Extending modules binds the methods to the class itself
class Book
  extend ModuleExample

  def initialize
  end

  def self.sasa
    puts foo
  end
end

class Book extend ModuleExample
  def sasa
    puts foo
  end
end


class YourClass
  # Include the methods within the class
  # as instance methods
  include SomeModule

  # Tell the class to extend the module, which
  # treats its methods as class methods
  extend SomeOtherModule
end
