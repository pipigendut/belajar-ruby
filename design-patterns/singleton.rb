require 'singleton'

class Ebook
  include Singleton

  attr_accessor :title, :url
end

class RubyObjectModel < Ebook; end

rom = RubyObjectModel.instance # Untuk membuat objek dari class objek 
rom.title = 'Ruby Object Model'
rom.url   = 'https://goo.gl/wq9eXv' # (visit the following link)

ebook = Ebook.instance
p ebook.title # => nil
p ebook.url   # => nil