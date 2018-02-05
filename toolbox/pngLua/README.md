![pngLua logo](/logo.png?raw=true)

A pure lua implementation of a PNG decoder

Usage
-----

To initialize a new png image:

    img = pngImage(<path to image>, newRowCallback)
    
The image will then be decoded. The available data from the image is as follows
```
img.width = 0
img.height = 0
img.depth = 0
img.colorType = 0

img:getPixel(x, y)
```
Decoding the image is synchronous, and will take a long time for large images.

Support
-------

The supported colortypes are as follows:

-    Grayscale
-    Truecolor
-    Indexed
-    Greyscale/alpha
-    Truecolor/alpha

So far the module only supports 256 Colors in png-8, png-24 as well as png-32 files. and no ancillary chunks.

More than 256 colors might be supported (Bit-depths over 8) as long as they align with whole bytes. These have not been tested.

Multiple IDAT chunks of arbitrary lengths are supported, as well as all filters.

Errors
-------
So far no error-checking has been implemented. No crc32 checks are done.
