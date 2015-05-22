package info.smoche.alternativa
{
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Renderer;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.materials.ShaderProgram;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.resources.BitmapTextureResource;
	import alternativa.engine3d.resources.Geometry;
	import alternativa.engine3d.resources.TextureResource;
	import com.adobe.utils.AGALMiniAssembler;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.VertexBuffer3D;
	import flash.utils.Dictionary;
	
	use namespace alternativa3d;
	/**
	 * Mipmapが不要なテクスチャマテリアル
	 * @author Toshiyuki Suzumura / @suzumura_ss
	 */
	public class NonMipmapTextureMaterial extends Material
	{
		private var _texture:NonMipmapBitmapTextureResource;
		private var _mipmapTexture:BitmapTextureResource;
		private var _context3d:Context3D;
		private var _program:ShaderProgram = new ShaderProgram(null, null);
		private var _vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
		private var _fragmentShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
		public var alpha:Number;
		
		/**
		 * 
		 * @param	texture		レンダリングするテクスチャリソース。Mipmapがなくてもよい。あってもよい。
		 * @param	alpha		表示アルファ
		 * @param	context3d
		 */
		public function NonMipmapTextureMaterial(texture:NonMipmapBitmapTextureResource, mipmapTexture:BitmapTextureResource, alpha:Number, context3d:Context3D)
		{
			_texture = texture;
			_mipmapTexture = mipmapTexture;
			this.alpha = alpha;
			_context3d = context3d;
			
			_vertexShaderAssembler.assemble(Context3DProgramType.VERTEX, [
				"m44 op, va0, vc0", 	// op = va0[pos] * vc0[projection]
				"mov v0, va1", 			// v0 = va1[uv]
			].join("\n"));
			
			_fragmentShaderAssembler.assemble(Context3DProgramType.FRAGMENT, [
				"tex ft0, v0, fs0 <2d,linear,repeat,nomip>", // oc = sampler2d(fs0, v0[uv])
				"tex ft1, v0, fs1 <2d,linear,repeat,miplinear>",
				"mul ft1.xyz, ft1.xyz, fc0.z", //　半輝度
				
				"sge ft2.x, v0.y, fc0.z",	//   ft2 = (v0.y >= 0.5) ? 1:0;
				"slt ft3.x, v0.y, fc0.z",	//   ft3 = (v0.y < 0.5) ? 1:0;
				"mul ft0, ft0, ft2.x",
				"mul ft1, ft1, ft3.x",
				"add ft0, ft0, ft1",
				"mov ft0.w, fc0.x",
				"mov oc, ft0",
			].join("\n"));
		}
		
		override alternativa3d function fillResources(resources:Dictionary, resourceType:Class):void
		{
			super.fillResources(resources, resourceType);
			
			if (_texture != null) {
				resources[_texture] = true;
			}
			if (_mipmapTexture != null) {
				resources[_mipmapTexture] = true;
			}
			_program.program = _context3d.createProgram();
			_program.program.upload(_vertexShaderAssembler.agalcode, _fragmentShaderAssembler.agalcode);
		}
		
		override alternativa3d function collectDraws(camera:Camera3D, surface:Surface, geometry:Geometry, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean, objectRenderPriority:int = -1):void
		{
			var object:Object3D = surface.object;
			var posBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.POSITION);
			var uvBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.TEXCOORDS[0]);
			var drawUnit:DrawUnit = camera.renderer.createDrawUnit(object, _program.program, geometry._indexBuffer, surface.indexBegin, surface.numTriangles, _program);
			
			drawUnit.setProjectionConstants(camera, 0, object.localToCameraTransform);	// = vc0
			drawUnit.setVertexBufferAt(0, posBuffer, 0, "float3");						// = va0
			drawUnit.setVertexBufferAt(1, uvBuffer,  3, "float2");						// = va1
			drawUnit.setFragmentConstantsFromNumbers(0, alpha, 0, 0.5, 0);				// = fc0
			drawUnit.setTextureAt(0, _texture._texture);								// = fs0
			drawUnit.setTextureAt(1, _mipmapTexture._texture);							// = fs1
			drawUnit.blendSource = Context3DBlendFactor.SOURCE_ALPHA;
			drawUnit.blendDestination = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
			camera.renderer.addDrawUnit(drawUnit, (objectRenderPriority >= 0)? objectRenderPriority: Renderer.OPAQUE);
		}
	}
}