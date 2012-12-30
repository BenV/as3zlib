as3zlib
=======

AS3 Port of Zlib, originally from http://code.google.com/p/as3zlib/

I have made a couple modifications here to fix some issues I ran into which 
resolve compiler warnings with Flex, and caused data deflated with Z_SYNC_FLUSH
to become corrupted

---------------------------------------------------------------------------------

This is a port of JZlib to as3.  

JZlib is a re-implementation of zlib  in pure Java.

This should support all the features of JZlib:
- deflate and inflate data
- support all compression levels
- support all zlib flushing modes

I did this port because as3 in Flash9 does not support deflate in ByteArray.  AIR does support deflate and doesn't need this code.

Full example of using this package with FZip can be found [here](http://www.wirelust.com/2009/06/08/as3-port-of-jzlib/).

----
Usage example:

```as3
var compressed:ByteArray = new ByteArray();
// set the compressed content


// if using Adobe AIR, you can inflate the byteArray like:  				
compressed.uncompress.apply(compressed, ["deflate"]);

// otherwise, you can use this library as such:

var uncompressed:ByteArray = new ByteArray();
var d_stream:ZStream=new ZStream();
d_stream.next_in = compressed;
d_stream.next_in_index = 0;
d_stream.next_out = uncompressed;
d_stream.next_out_index = 0;

var err:int = d_stream.inflateInitWithNoWrap(true);

while(d_stream.total_out != 1 && d_stream.total_in < compressed.length && i<=compressed.length*4) {
	d_stream.avail_in=d_stream.avail_out=10;

	err=d_stream.inflate(JZlib.Z_NO_FLUSH);
	if(err == JZlib.Z_STREAM_END) {
		trace("decompress success.");
		break;
	} else if (err == JZlib.Z_STREAM_ERROR) {
		trace("stream error:" + " " + d_stream.msg);
		break;
	} else if (err == JZlib.Z_DATA_ERROR) {
		trace("data error:" + " " + d_stream.msg);
		break;
	}

}
err=d_stream.inflateEnd();

// uncompressed now contains the inflated data
```
