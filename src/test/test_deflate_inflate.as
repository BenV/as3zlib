package test {
	import com.wirelust.as3zlib.Deflate;
	import com.wirelust.as3zlib.JZlib;
	import com.wirelust.as3zlib.System;
	import com.wirelust.as3zlib.ZInputStream;
	import com.wirelust.as3zlib.ZOutputStream;
	import com.wirelust.as3zlib.ZStream;
	import com.wirelust.as3zlib.ZStreamException;
	
	import flash.display.Sprite;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	
	public class test_deflate_inflate extends Sprite {
		
		internal var fileRequest:URLRequest;
		internal var fileStream:URLStream;

		internal var err:int;
		internal var comprLen:int=40000;
		internal var uncomprLen:int=comprLen;
		internal var uncompr:ByteArray = new ByteArray();
		
		public function test_deflate_inflate() {
			System.println("loading hello.txt");
			fileRequest = new URLRequest("hello.txt");
			fileStream = new URLStream();
			fileStream.addEventListener(Event.COMPLETE, onFileLoaded);
			fileStream.load(fileRequest);
		}
	
		private function onFileLoaded(event:Event):void {
			var file:URLStream = URLStream(event.target);
	
			var fileBytes:ByteArray = new ByteArray();
			file.readBytes(fileBytes, 0, file.bytesAvailable);

			System.println("decompressed bytes:" + fileBytes.length);
			
			var c_stream:ZStream=new ZStream();

			err=c_stream.deflateInit(JZlib.Z_DEFAULT_COMPRESSION);
			CHECK_ERR(c_stream, err, "deflateInit");
			
			var compressed:ByteArray = new ByteArray();
			
			c_stream.next_in=fileBytes;
			c_stream.next_in_index=0;
			
			c_stream.next_out=compressed;
			c_stream.next_out_index=0;
			
			var j:int = 0;
			while(c_stream.total_in!=fileBytes.length && c_stream.total_out<comprLen) {
				
				c_stream.avail_in=c_stream.avail_out=1; // force small buffers
				err=c_stream.deflate(JZlib.Z_NO_FLUSH);
				CHECK_ERR(c_stream, err, "deflate");
			}
			
			while(true){
				c_stream.avail_out=1;
				err = c_stream.deflate(JZlib.Z_FINISH);
				if (err==JZlib.Z_STREAM_END) {
					break;
				}

				compressed.position = 0;
				
				CHECK_ERR(c_stream, err, "deflate");
			}
			
			var i:uint;
			//compressed.position = 0;
			// look at the compressed array
			//for (i=0; i<compressed.length; i++) {
			//	System.println("" + i + "::" + compressed.readByte());
			//}
			
			err=c_stream.deflateEnd();      
			CHECK_ERR(c_stream, err, "deflateEnd");
	
			System.println("compressed bytes:" + compressed.length);
			
			var d_stream:ZStream=new ZStream();
			
			d_stream.next_in = compressed;
			d_stream.next_in_index = 0;
			d_stream.next_out = uncompr;
			d_stream.next_out_index = 0;
			
			err=d_stream.inflateInit();
			CHECK_ERR(d_stream, err, "inflateInit");

			var outcount:int = 0;
			while(d_stream.total_out < fileBytes.length && d_stream.total_in < compressed.length) {
				d_stream.avail_in=d_stream.avail_out=1; /* force small buffers */
				err=d_stream.inflate(JZlib.Z_NO_FLUSH);
				if(err == JZlib.Z_STREAM_END) {
					break;
				}
				
				outcount++;
				System.println(outcount + ":" + d_stream.total_out);

				if (!CHECK_ERR(d_stream, err, "inflate")) {
					break;
				}
			}

			err=d_stream.inflateEnd();
			CHECK_ERR(d_stream, err, "inflateEnd");
			
			fileBytes.position = 0;
			for(i=0; i<fileBytes.length; i++) {
				if(fileBytes.readByte() == 0) {
					break;
				}
			}
			
			uncompr.position = 0;
			for(j=0; j<uncompr.length; j++) {
				if(uncompr.readByte() == 0) {
					break;
				}
			}
			
			if(i==j) {
				uncompr.position = 0;
				fileBytes.position = 0;
				for(i=0; i<j; i++) {
					if(fileBytes.readByte() != uncompr.readByte()) {
						break;
					}
				}
				if(i==j) {
					System.println("inflate(): " + String(uncompr));
					return;
				}
			} else {
				System.println("bad inflate");
			}
			
		}

		public static function CHECK_ERR(z:ZStream, err:int, msg:String):Boolean {
			if (err!=JZlib.Z_OK) {
				if (z.msg!=null) {
					System.println(z.msg + " ");
				} 
				System.println(msg+" error: "+err);
				return false;
			}
			return true;
		}
		
	}
}
