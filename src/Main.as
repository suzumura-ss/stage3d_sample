package 
{
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
		private var _extended3dEnabled:Boolean = true;
		
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
			_stage3d.addEventListener(ErrorEvent.ERROR, onContent3DExtendCreateError);
			_stage3d.requestContext3D(Context3DRenderMode.AUTO, Context3DProfile.BASELINE_EXTENDED);
		}
		
		private function onContent3DExtendCreateError(e:ErrorEvent):void
		{
			Utils.Trace("Create Context3DProfile.BASELINE_EXTENDED failed.");
			_extended3dEnabled = false;
			_stage3d.removeEventListener(ErrorEvent.ERROR, onContent3DExtendCreateError);
			_stage3d.addEventListener(ErrorEvent.ERROR, onContent3DCreateError);
			_stage3d.requestContext3D(Context3DRenderMode.AUTO, Context3DProfile.BASELINE);
		}
		
		private function onContent3DCreateError(e:ErrorEvent):void
		{
			Utils.Trace("Create Context3DProfile.BASELINE failed.");
			_stage3d.removeEventListener(ErrorEvent.ERROR, onContent3DCreateError);
		}
		
		private function onContent3DCreate(e:Event):void
		{
			_stage3d.removeEventListener(Event.CONTEXT3D_CREATE, onContent3DCreate);
			_stage3d.removeEventListener(ErrorEvent.ERROR, onContent3DExtendCreateError);
			_stage3d.removeEventListener(ErrorEvent.ERROR, onContent3DCreateError);
			
			var htmlParams:Object = LoaderInfo(root.loaderInfo).parameters;
			var imageName:String = htmlParams["source"] || "forest.jpg";
			Utils.Trace(["source", imageName]);
			
			_root = new Object3D();
			_camera = new Camera3D(0.01, 100000000);
			_camera.view = new View(stage.stageWidth, stage.stageHeight, false, 0x202020, 0, 4);
			addChild(_camera.view);
			addChild(_camera.diagram);
			
			_root.addChild(_camera);
			_controller = new SimpleObjectController(stage, _camera, 200, 3, -0.1);
			var center:Number = -Math.PI / 2.0;
			_controller.maxPitch = center + Math.PI / 2.0;
			_controller.minPitch = center - Math.PI / 2.0;
			_controller.lookAt(new LookAt3D());
			
			BitmapTextureResourceLoader.flipH = false;
			BitmapTextureResourceLoader.loadURL(imageName, function(tr:NonMipmapBitmapTextureResource):void {
				var m:Mesh = new GeoSphere(2000, 4, true);
				var t:NonMipmapTextureMaterial = new NonMipmapTextureMaterial(tr, 1, _stage3d.context3D);
				m.setMaterialToAllSurfaces(t);
				_root.addChild(m);
				uploadResouces();
			}, function(e:Error):void {
				Utils.Trace(e);
			});
			
			uploadResouces();
			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(Event.RESIZE, onResize);
		}
		
		private function uploadResouces():void
		{
			for each (var resource:Resource in _root.getResources(true)) {
				if (!resource.isUploaded) resource.upload(_stage3d.context3D);
			}
		}
		
		private function onEnterFrame(e:Event):void
		{
			_controller.update();
			_camera.render(_stage3d)
		}
		
		private function onResize(e:Event):void
		{
			_camera.view.width = stage.stageWidth;
			_camera.view.height = stage.stageHeight;
		}
	}
}
