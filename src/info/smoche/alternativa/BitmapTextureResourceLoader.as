package info.smoche.alternativa
{
	import alternativa.engine3d.resources.BitmapTextureResource;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import mx.utils.Base64Decoder;
	/**
	 * BitmapTextureResourceローダー
	 * 		URLで指定したファイルをロードします
	 * @author Toshiyuki Suzumura / @suzumura_ss
	 */
	
	public class BitmapTextureResourceLoader 
	{
		static public var flipH:Boolean = false;		// 水平反転させる場合は true
		static public var useExtendedProfile:Boolean = false; // Context3DProfile.BASELINE_EXTENDED なら true
		
		public function BitmapTextureResourceLoader()
		{
		}
		
		/**
		 * URLから画像をロードしてテクスチャを生成します
		 * @param	url
		 * 		"javascript:method_name" の場合、method_name() をコールバックしてその文字列を利用します。
		 * 		"data:..." の場合、"data:image/png;base64,"の後ろをBase64エンコードされたPNG画像とみなしてロードします。
		 * 		それ以外の場合はHTTPリクエストで画像を取得します。
		 * @param	result
		 * 		画像を取得してテクスチャリソースを生成できたらコールバックします。
		 * 		NonMipmapBitmapTextureResource を引数にとります。
		 * @param	onerror
		 * 		エラーが起きた場合にコールバックします。
		 * 		文字列か Errorクラスを引数にとります。
		 */
		static public function loadURL(url:String, result:Function, onerror:Function):void
		{
			var loaderContext:LoaderContext = null;
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
				try {
					var bmp:BitmapData = (e.target.content as Bitmap).bitmapData;
				} catch (se:SecurityError) {
					onerror(se);
                    return;
				}
				if (flipH) {
					bmp = NonMipmapBitmapTextureResource.flipImage(bmp);
				}
				var bmp2:BitmapData = bmp.clone();
				result(new NonMipmapBitmapTextureResource(bmp2, false, true, useExtendedProfile), new BitmapTextureResource(bmp, true));
			});
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {
				onerror(e);
			});
			
			var v:Array = url.split(":");
			if (v[0] == "javascript") {
				var method:String = v[1];
				try {
					url = ExternalInterface.call(method);
				} catch (e:Error) {
					onerror(e);
					return;
				}
				if (url) {
					v = url.split(":");
				} else {
					onerror("method '" + method + "' returned empty string.");
					return;
				}
			}
			if (v[0] == "data") {
				try {
					var decoder:Base64Decoder = new Base64Decoder();
					decoder.decode(url.split(",")[1]);
					var png:ByteArray = decoder.flush();
					loader.loadBytes(png);
				} catch (e:Error) {
					onerror(e);
				}
			} else if (url.length > 0) {
				loaderContext = new LoaderContext(true);
				loader.load(new URLRequest(url), loaderContext);
			} else {
				onerror("Empty data.");
			}
		}
	}
}