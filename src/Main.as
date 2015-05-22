package 
{
	import alternativa.Alternativa3D;
	import alternativa.engine3d.controllers.SimpleObjectController;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Resource;
	import alternativa.engine3d.core.View;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.primitives.GeoSphere;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3DProfile;
	import flash.display3D.Context3DRenderMode;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.system.Security;
	import info.smoche.alternativa.BitmapTextureResourceLoader;
	import info.smoche.alternativa.NonMipmapBitmapTextureResource;
	import info.smoche.alternativa.NonMipmapTextureMaterial;
	import info.smoche.utils.LookAt3D;
	import info.smoche.utils.Utils;
	
	/**
	 * ...
	 * @author 
	 */
	
	public class Main extends Sprite 
	{
		private var _stage3d:Stage3D;
		private var _root:Object3D;
		private var _controller:SimpleObjectController;
		private var _camera:Camera3D;
		private var _mesh:Mesh;
		private var _profiles:Vector.<String> = Vector.<String>([
			//Context3DProfile.STANDARD_EXTENDED,
			//Context3DProfile.STANDARD_CONSTRAINED,
			Context3DProfile.BASELINE_EXTENDED,
			Context3DProfile.BASELINE
		]);
		private var _extended3dEnabled:Boolean = false;
		private var _startClock:Number = 0;
		
		private function lap():String
		{
			return ((new Date()).valueOf() - _startClock).toString();
		}
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			_stage3d = stage.stage3Ds[0];
			_stage3d.addEventListener(Event.CONTEXT3D_CREATE, onContent3DCreate);
			_stage3d.addEventListener(ErrorEvent.ERROR, onContent3DCreateError);
			while (_profiles[0] == null) {
				_profiles.shift();
			}
			_stage3d.requestContext3D(Context3DRenderMode.AUTO, _profiles[0]);
		}
		
		private function onContent3DCreateError(e:ErrorEvent):void
		{
			Utils.Trace("Create failed: " + _profiles[0]);
			_profiles.shift();
			if (_profiles.length > 0) {
				_stage3d.requestContext3D(Context3DRenderMode.AUTO, _profiles[0]);
			}
		}
		
		private function onContent3DCreate(e:Event):void
		{
			_stage3d.removeEventListener(ErrorEvent.ERROR, onContent3DCreateError);
			_extended3dEnabled = (_profiles[0] != Context3DProfile.BASELINE);
			Utils.Trace("Alternativa3D.version: " + Alternativa3D.version);
			Utils.Trace("Using Context3DProfile: " + _profiles[0]);
			
			var htmlParams:Object = LoaderInfo(root.loaderInfo).parameters;
			var imageName:String = htmlParams["source"] || "m20-moire-R721.JPG";
			var onReadyJS:String = htmlParams["onReady"] || "";
			_startClock = Number(htmlParams["startClock"] || "0");
			Utils.Trace("=== Initializing: " + lap());
			Utils.Trace("Source: " + imageName);
			
			_root = new Object3D();
			_camera = new Camera3D(0.01, 100000000);
			_camera.view = new View(stage.stageWidth, stage.stageHeight, false, 0x202020, 0, 4);
			addChild(_camera.view);
			addChild(_camera.diagram);
			
			_mesh = new GeoSphere(2000, 8, true);
			_root.addChild(_mesh);
			
			_root.addChild(_camera);
			_controller = new SimpleObjectController(stage, _camera, 200, 3, -0.1);
			var center:Number = -Math.PI / 2.0;
			_controller.maxPitch = center + Math.PI / 2.0;
			_controller.minPitch = center - Math.PI / 2.0;
			_controller.lookAt(new LookAt3D());
			
			BitmapTextureResourceLoader.flipH = false;
			BitmapTextureResourceLoader.useExtendedProfile = _extended3dEnabled;
			if (imageName != "") {
				loadImageFromDataURL(imageName);
			}
			uploadResouces();
			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			if (!stage.hasEventListener(Event.RESIZE)) {
				stage.addEventListener(Event.RESIZE, onResize);
			}
			
			onReady(onReadyJS);
		}
		
		private function uploadResouces():void
		{
			for each (var resource:Resource in _root.getResources(true)) {
				if (!resource.isUploaded) resource.upload(_stage3d.context3D);
			}
		}
		
		private function onEnterFrame(e:Event):void
		{
			if (_stage3d.context3D == null) {
				Utils.Trace("Context3D is lost.");
				stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
				_stage3d.requestContext3D(Context3DRenderMode.AUTO, _profiles[0]);
			} else {
				_controller.update();
				_camera.render(_stage3d)
			}
		}
		
		private function onResize(e:Event):void
		{
			_camera.view.width = stage.stageWidth;
			_camera.view.height = stage.stageHeight;
		}
		
		private function onReady(js:String):void
		{
			if (ExternalInterface.available) {
				ExternalInterface.addCallback("loadImage", function(r:String):void {
					Utils.Trace("javascript::loadImage: loading: " + lap());
					loadImageFromDataURL(r);
				});
				Utils.Trace("onReady: " + js);
				var r:String = ExternalInterface.call(js);
				var s:String = r.split(":")[0];
				if (s == "data") {
					loadImageFromDataURL(r);
				} else {
					Utils.Trace("onReady: " + js + " => " + r);
				}
			}
		}
		
		private function loadImageFromDataURL(dataURL:String):void
		{
			Utils.Trace("=== Loading Texture: " + dataURL.split(":")[0] + ": " + lap());
			BitmapTextureResourceLoader.loadURL(dataURL, function(tr:NonMipmapBitmapTextureResource):void {
				var t:NonMipmapTextureMaterial = new NonMipmapTextureMaterial(tr, 1, _stage3d.context3D);
				_mesh.setMaterialToAllSurfaces(t);
				uploadResouces();
				Utils.Trace("=== Texture Ready: " + dataURL.split(":")[0] + ": " + lap());
			}, function(se:SecurityError):void {
				Utils.Trace("BitmapTextureResourceLoader.loadURL failed:" + se);
			});
		}
	}
}
