require 'png'

function printProg(line, totalLine)
	print(line .. " of " .. totalLine)
end

img = pngImage("Example.png", printProg)
print("Width: " .. img.width)
print("Height: " .. img.height)
print("Depth: " .. img.depth)

print("Color of pixel (10, 10): " .. img:getPixel(10,10):format())