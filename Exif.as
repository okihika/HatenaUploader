package {
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.net.URLLoaderDataFormat;
	import flash.utils.*;
	import flash.utils.ByteArray;
	
	public class Exif extends Sprite {
		private var image:URLLoader = null;
				
		public function Exif( path:String = "YOUR_DEFAULT_TEST_FILE" ) {						
			var request:URLRequest = new URLRequest( path );
			
			image = new URLLoader();
			//image.dataFormat =    DataFormat.BINARY;
			image.addEventListener( Event.COMPLETE, parse );
			image.load( request );
		}		
		
		public function parse( event:Event ):void {
			var contents:Array = null;
			var dump:Array = null;
			var ifd:Array = null;
			var data:ByteArray = new ByteArray();
			var exif:uint = 0;
			var interop:uint = 0;
			var length:uint = 0;
			var tiff:TIFF = null;
			
			image.data.readBytes( data, 0, 12 );

			
			if( !isJpeg( data ) || !hasExif( data ) ) {
				trace( "Not a JPEG containing EXIF data." );
				return;	
			}
			
			data.position = 4;
			length = data.readUnsignedShort();
			trace( "EXIF header length: " + length + " bytes" );
			
			image.data.readBytes( data, 0, length - 8 );
			
			if( data[0] == 73 ) {
				trace( "Intel format" );	
			} else {
				trace( "Motorola format" );
			}
			
			tiff = new TIFF( data );
			ifd = tiff.list();
			
			for( var i:int = 0; i < ifd.length; i++ ) {
				trace( "IFD " + i );
				
				if( i == 0 ) {
					trace( "Main image" );	
				} else if( i == 1 ) {
					trace( "Thumbnail image" );	
				}
				
				trace( "At offset: " + ifd[i] );
				
				contents = tiff.dump( ifd[i] );
				tiff.print( contents, TIFF.EXIF_TAGS );
				
				exif = 0;
				
				for( var t:int = 0; t < contents.length; t++ ) {
					if( contents[t].getTag() == 34665 ) {
						exif = contents[t].getValues()[0];
					}
				}
				
				if( exif != 0 ) {
					trace( "Exif SubIFD at offset " + exif );	
					contents = tiff.dump( exif );
					tiff.print( contents, TIFF.EXIF_TAGS );
					
					interop = 0;
					
					for( var s:int = 0; s < contents.length; s++ ) {
						if( contents[s].getTag() == 40965 ) {
							interop = contents[s].getValues()[0];
						}	
					}

					if( interop != 0 ) {
						trace( "Exif Interoperability SubSubIFD at offset " + interop );
						contents = tiff.dump( interop );
						tiff.print( contents, TIFF.INTEROP_TAGS );	
					}					
				}
			}
		}
		
		public function isJpeg( data:ByteArray ):Boolean {
			var jpeg:Boolean = false;
			
			if( data[0] == 255 && data[1] == 216 &&
				data[2] == 255 && data[3] == 225 ) {
				jpeg = true;	
			}
			
			return jpeg;
		}
		
		public function hasExif( data:ByteArray ):Boolean {
			var exif:Boolean = false;

			if( data[6] == 69 && data[7] == 120 &&
				data[8] == 105 && data[9] == 102 ) {
				exif = true;		
			}
			
			return exif;	
		}
	}
}
