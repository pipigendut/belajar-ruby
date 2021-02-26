class Person
  attr_accessor :name, :age, :sex, :email
  def initialize(name)
    @name = name
  end
end

# init
person = Person.new("Akbar")

# get value an property
person.name
person.instance_variable_get("@name")

# set value an property/
person.name = "another name"
person.instance_variable_set("@name", "another name")

# check property in class
person.instance_variables
person.public_methods
Person.instance_methods


class Person
  def initialize(name)
    @name = name
  end
  def self.define_attr(attr)
    define_method(attr) do
      instance_variable_get("@#{attr}")
    end
    define_method("#{attr}=") do |val|
      instance_variable_set("@#{attr}", val)
    end
  end
end
