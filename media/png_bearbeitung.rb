#encoding: utf-8
require 'rubygems'
require 'chunky_png'
include ChunkyPNG

puts "Geben Sie den Pfad an, an dem das Bild gespeichert ist"
path = gets.chomp
until File.exists?(path)
  puts "Das angegebene Bild existiert nicht. Bitte geben Sie einen anderen Pfad ein."
  path = gets.chomp
end
image = Image.from_file(path) 
HEIGHT = image.height
WIDTH = image.width
puts "Welche Farbe soll ersetzt werden? (In RGBA angeben)"
eingabe = gets.chomp.split(", ")
old = Color.rgba(eingabe[0].to_i, eingabe[1].to_i, eingabe[2].to_i, eingabe[3].to_i)
puts "Durch welche Farbe soll der Pixel ersetzt werden? (In RGBA angeben)"
eingabe = gets.chomp.split(", ")
new = Color.rgba(eingabe[0].to_i, eingabe[1].to_i, eingabe[2].to_i, eingabe[3].to_i)

WIDTH.times do |x|
  HEIGHT.times do |y|
    image[x, y] = new if image[x, y] == old
  end
end

image.save('result.png')
puts "Bearbeitung erfolgreich beendet.\nDas neue Bild liegt unter dem Namen 'result.png' im Ordner dieses Programmes."