class = require '30log'
deflate = require 'deflate'
require 'stream'

Chunk = class()
Chunk.__name = "Chunk"
Chunk.length = 0
Chunk.name = ""
Chunk.data = ""
Chunk.crc = ""

function Chunk:__init(stream)
	if stream.__name == "Chunk" then
		self.length = stream.length
		self.name = stream.name
		self.data = stream.data
		self.crc = stream.crc
	else
		self.length = stream:readInt()
		self.name = stream:readChars(4)
		self.data = stream:readChars(self.length)
		self.crc = stream:readChars(4)
	end
end

function Chunk:getDataStream()
	return Stream({input = self.data})
end

IHDR = Chunk:extends()
IHDR.__name = "IHDR"
IHDR.width = 0
IHDR.height = 0
IHDR.bitDepth = 0
IHDR.colorType = 0
IHDR.compression = 0
IHDR.filter = 0
IHDR.interlace = 0

function IHDR:__init(chunk)
	self.super.__init(self, chunk)
	local stream = chunk:getDataStream()
	self.width = stream:readInt()
	self.height = stream:readInt()
	self.bitDepth = stream:readByte()
	self.colorType = stream:readByte()
	self.compression = stream:readByte()
	self.filter = stream:readByte()
	self.interlace = stream:readByte()
end

IDAT = Chunk:extends()
IDAT.__name = "IDAT"

function IDAT:__init(chunk)
	self.super.__init(self, chunk)
end

PLTE = Chunk:extends()
PLTE.__name = "PLTE"
PLTE.numColors = 0
PLTE.colors = {}

function PLTE:__init(chunk)
	self.super.__init(self, chunk)
	self.numColors = math.floor(chunk.length/3)
	local stream = chunk:getDataStream()
	for i = 1, self.numColors do
		self.colors[i] = {
			R = stream:readByte(),
			G = stream:readByte(),
			B = stream:readByte(),
		}
	end
end

function PLTE:getColor(index)
	return self.colors[index]
end

Pixel = class()
Pixel.__name = "Pixel"
Pixel.R = 0
Pixel.G = 0
Pixel.B = 0
Pixel.A = 0

function Pixel:__init(stream, depth, colorType, palette)
	local bps = math.floor(depth/8)
	if colorType == 0 then
		local grey = stream:readInt(bps)
		self.R = grey
		self.G = grey
		self.B = grey
		self.A = 255
	end
	if colorType == 2 then
		self.R = stream:readInt(bps)
		self.G = stream:readInt(bps)
		self.B = stream:readInt(bps)
		self.A = 255
	end
	if colorType == 3 then
		local index = stream:readInt(bps)+1
		local color = palette:getColor(index)
		self.R = color.R
		self.G = color.G
		self.B = color.B
		self.A = 255
	end
	if colorType == 4 then
		local grey = stream:readInt(bps)
		self.R = grey
		self.G = grey
		self.B = grey
		self.A = stream:readInt(bps)
	end
	if colorType == 6 then
		self.R = stream:readInt(bps)
		self.G = stream:readInt(bps)
		self.B = stream:readInt(bps)
		self.A = stream:readInt(bps)
	end
end

function Pixel:format()
	return string.format("R: %d, G: %d, B: %d, A: %d", self.R, self.G, self.B, self.A)
end

ScanLine = class()
ScanLine.__name = "ScanLine"
ScanLine.pixels = {}
ScanLine.filterType = 0

function ScanLine:__init(stream, depth, colorType, palette, length)
	bpp = math.floor(depth/8) * self:bitFromColorType(colorType)
	bpl = bpp*length
	self.filterType = stream:readByte()
	stream:seek(-1)
	stream:writeByte(0)
	local startLoc = stream.position
	if self.filterType == 0 then
		for i = 1, length do
			self.pixels[i] = Pixel(stream, depth, colorType, palette)
		end
	end
	if self.filterType == 1 then
		for i = 1, length do
			for j = 1, bpp do
				local curByte = stream:readByte()
				stream:seek(-(bpp+1))
				local lastByte = 0
				if stream.position >= startLoc then lastByte = stream:readByte() or 0 else stream:readByte() end
				stream:seek(bpp-1)
				stream:writeByte((curByte + lastByte) % 256)
			end
			stream:seek(-bpp)
			self.pixels[i] = Pixel(stream, depth, colorType, palette)
		end
	end
	if self.filterType == 2 then
		for i = 1, length do
			for j = 1, bpp do
				local curByte = stream:readByte()
				stream:seek(-(bpl+2))
				local lastByte = stream:readByte() or 0
				stream:seek(bpl)
				stream:writeByte((curByte + lastByte) % 256)
			end
			stream:seek(-bpp)
			self.pixels[i] = Pixel(stream, depth, colorType, palette)
		end
	end
	if self.filterType == 3 then
		for i = 1, length do
			for j = 1, bpp do
				local curByte = stream:readByte()
				stream:seek(-(bpp+1))
				local lastByte = 0
				if stream.position >= startLoc then lastByte = stream:readByte() or 0 else stream:readByte() end
				stream:seek(-(bpl)+bpp-2)
				local priByte = stream:readByte() or 0
				stream:seek(bpl)
				stream:writeByte((curByte + math.floor((lastByte+priByte)/2)) % 256)
			end
			stream:seek(-bpp)
			self.pixels[i] = Pixel(stream, depth, colorType, palette)
		end
	end
	if self.filterType == 4 then
		for i = 1, length do
			for j = 1, bpp do
				local curByte = stream:readByte()
				stream:seek(-(bpp+1))
				local lastByte = 0
				if stream.position >= startLoc then lastByte = stream:readByte() or 0 else stream:readByte() end
				stream:seek(-(bpl + 2 - bpp))
				local priByte = stream:readByte() or 0
				stream:seek(-(bpp+1))
				local lastPriByte = 0
				if stream.position >= startLoc - (length * bpp + 1) then lastPriByte = stream:readByte() or 0 else stream:readByte() end
				stream:seek(bpl + bpp)
				stream:writeByte((curByte + self:_PaethPredict(lastByte, priByte, lastPriByte)) % 256)
			end
			stream:seek(-bpp)
			self.pixels[i] = Pixel(stream, depth, colorType, palette)
		end
	end
end

function ScanLine:bitFromColorType(colorType)
	if colorType == 0 then return 1 end
	if colorType == 2 then return 3 end
	if colorType == 3 then return 1 end
	if colorType == 4 then return 2 end
	if colorType == 6 then return 4 end
	error 'Invalid colortype'
end

function ScanLine:getPixel(pixel)
	return self.pixels[pixel]
end

--Stolen right from w3.
function ScanLine:_PaethPredict(a, b, c)
	local p = a + b - c
	local varA = math.abs(p - a)
	local varB = math.abs(p - b)
	local varC = math.abs(p - c)
	if varA <= varB and varA <= varC then return a end
	if varB <= varC then return b end
	return c
end

pngImage = class()
pngImage.__name = "PNG"
pngImage.width = 0
pngImage.height = 0
pngImage.depth = 0
pngImage.colorType = 0
pngImage.scanLines = {}

function pngImage:__init(path, progCallback)
	local str = Stream({inputF = path})
	if str:readChars(8) ~= "\137\080\078\071\013\010\026\010" then error 'Not a PNG' end
	local ihdr = {}
	local plte = {}
	local idat = {}
	local num = 1
	while true do
		ch = Chunk(str)
		if ch.name == "IHDR" then ihdr = IHDR(ch) end
		if ch.name == "PLTE" then plte = PLTE(ch) end
		if ch.name == "IDAT" then idat[num] = IDAT(ch) num = num+1 end
		if ch.name == "IEND" then break end
	end
	self.width = ihdr.width
	self.height = ihdr.height
	self.depth = ihdr.bitDepth
	self.colorType = ihdr.colorType

	local dataStr = ""
	for k,v in pairs(idat) do dataStr = dataStr .. v.data end
	local output = {}
	deflate.inflate_zlib {input = dataStr, output = function(byte) output[#output+1] = string.char(byte) end, disable_crc = true}
	imStr = Stream({input = table.concat(output)})

	for i = 1, self.height do
		self.scanLines[i] = ScanLine(imStr, self.depth, self.colorType, plte, self.width)
		if progCallback ~= nil then progCallback(i, self.height) end
	end
end

function pngImage:getPixel(x, y)
	local pixel = self.scanLines[y].pixels[x]
	return pixel
end