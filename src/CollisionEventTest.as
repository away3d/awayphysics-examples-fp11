package  
{
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.*;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.SphereGeometry;
	
	import awayphysics.collision.dispatch.AWPCollisionObject;
	import awayphysics.collision.shapes.*;
	import awayphysics.debug.AWPDebugDraw;
	import awayphysics.dynamics.*;
	import awayphysics.events.AWPEvent;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;
	 
	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class CollisionEventTest extends Sprite
	{
		private var _view:View3D;
		private var _light:PointLight;
		private var lightPicker:StaticLightPicker;
		private var orginalMaterial:ColorMaterial;
		private var bodiesMaterial:Vector.<ColorMaterial>;
		
		private var physicsWorld:AWPDynamicsWorld;
		private var sphereBody:AWPCollisionObject;
		private var boxes:Vector.<AWPCollisionObject>;
		
		private var sRotation : Number = 0;
		private var sDirection : Vector3D = new Vector3D(0, 0, 10);
		
		private var timeStep:Number = 1.0 / 60;
		
		private var keyRight   :Boolean = false;
		private var keyLeft    :Boolean = false;
		private var keyForward :Boolean = false;
		private var keyReverse :Boolean = false;
		
		private var debugDraw:AWPDebugDraw;
		
		public function CollisionEventTest() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			_view = new View3D();
			this.addChild(_view);
			this.addChild(new AwayStats(_view));
			
			_light = new PointLight();
			_light.y = 2500;
			_light.z = -4000;
			_view.scene.addChild(_light);
			
			lightPicker = new StaticLightPicker([_light]);
			
			_view.camera.lens.far = 10000;
			_view.camera.y = _light.y;
			_view.camera.z = _light.z;
			_view.camera.rotationX = 25;
			
			//init the physics world
			physicsWorld = AWPDynamicsWorld.getInstance();
			physicsWorld.initWithDbvtBroadphase();
			physicsWorld.collisionCallbackOn = true;
			
			debugDraw = new AWPDebugDraw(_view, physicsWorld); 
			debugDraw.debugMode |= AWPDebugDraw.DBG_DrawRay;
			
			orginalMaterial = new ColorMaterial(0xffff00, 0.6);
			orginalMaterial.lightPicker = lightPicker;
			bodiesMaterial = new Vector.<ColorMaterial>();
			bodiesMaterial[0] = new ColorMaterial(0x0000ff, 0.6);
			bodiesMaterial[0].lightPicker = lightPicker;
			bodiesMaterial[1] = new ColorMaterial(0x00ffff, 0.6);
			bodiesMaterial[1].lightPicker = lightPicker;
			bodiesMaterial[2] = new ColorMaterial(0xff00ff, 0.6);
			bodiesMaterial[2].lightPicker = lightPicker;
			
			var mesh:Mesh;
			var shape:AWPCollisionShape;
			var body:AWPCollisionObject;
			boxes = new Vector.<AWPCollisionObject>();
			for (var i:int = 0; i < 3; i++ ) {
				mesh = new Mesh(new CubeGeometry(600, 600, 600),orginalMaterial);
				_view.scene.addChild(mesh);
				shape = new AWPBoxShape(600, 600, 600);
				body = new AWPCollisionObject(shape, mesh);
				body.position = new Vector3D( -1200 + (i * 1000), 500, 0);
				physicsWorld.addCollisionObject(body);
				boxes.push(body);
			}
			
			//create the Sphere
			var material:ColorMaterial = new ColorMaterial(0xff0000, 0.6);
			material.lightPicker = lightPicker;
			mesh = new Mesh(new SphereGeometry(200),material);
			_view.scene.addChild(mesh);
			shape = new AWPSphereShape(200);
			sphereBody = new AWPCollisionObject(shape, mesh);
			sphereBody.position = new Vector3D( 0, 500, -1200);
			sphereBody.rotationY = -10;
			physicsWorld.addCollisionObject(sphereBody);
			
			//add rays to sphere
			sphereBody.addRay(new Vector3D(), new Vector3D(500,0,0));
			sphereBody.addRay(new Vector3D(), new Vector3D(-500,0,0));
			sphereBody.addRay(new Vector3D(), new Vector3D(0,0,800));
			
			//add collision listener to sphere
			sphereBody.addEventListener(AWPEvent.COLLISION_ADDED, sphereCollisionAdded);
			//add raycast listener to sphere
			sphereBody.addEventListener(AWPEvent.RAY_CAST, sphereRayCast);
			
			stage.addEventListener( KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener( KeyboardEvent.KEY_UP, keyUpHandler);
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}
		
		private function sphereCollisionAdded(event:AWPEvent):void {
			for (var i:int = 0; i < boxes.length; i++ ) {
				var mesh:Mesh = Mesh(boxes[i].skin);
				if (event.collisionObject == boxes[i]) {
					mesh.material = bodiesMaterial[i];
				}
			}
		}
		private function sphereRayCast(event:AWPEvent):void {
			//trace("collision point in world space: "+event.collisionObject.worldTransform.transform.transformVector(event.manifoldPoint.localPointB));
			//trace("collision normal in world space: "+event.manifoldPoint.normalWorldOnB);
			var mesh:Mesh = Mesh(event.collisionObject.skin);
			mesh.material = Mesh(sphereBody.skin).material;
		}
		
		private function keyDownHandler(event:KeyboardEvent):void
		{
			switch(event.keyCode)
			{
				case Keyboard.UP:
					keyForward = true;
					keyReverse = false;
					break;
				
				case Keyboard.DOWN:
					keyReverse = true;
					keyForward = false;
					break;
				
				case Keyboard.LEFT:
					keyLeft = true;
					keyRight = false;
					break;
				
				case Keyboard.RIGHT:
					keyRight = true;
					keyLeft = false;
					break;
			}
		}
		
		private function keyUpHandler(event:KeyboardEvent):void
		{
			switch(event.keyCode)
			{
				case Keyboard.UP:
					keyForward = false;
					break;
				
				case Keyboard.DOWN:
					keyReverse = false;
					break;
				
				case Keyboard.LEFT:
					keyLeft = false;
					break;
				
				case Keyboard.RIGHT:
					keyRight = false;
					break;
			}
		}
		
		private function handleEnterFrame(e:Event) : void
		{
			if(keyLeft)
			{
				sRotation -= 3;
				sphereBody.rotation = new Vector3D(0, sRotation, 0);
			}
			if(keyRight)
			{
				sRotation += 3;
				sphereBody.rotation = new Vector3D(0, sRotation, 0);
			}
			if(keyForward)
			{
				sphereBody.position = sphereBody.position.add(sphereBody.worldTransform.rotationWithMatrix.transformVector(sDirection));
			}
			if(keyReverse)
			{
				sphereBody.position = sphereBody.position.subtract(sphereBody.worldTransform.rotationWithMatrix.transformVector(sDirection));
			}
			
			for each(var body:AWPCollisionObject in boxes) {
				var mesh:Mesh = Mesh(body.skin);
				mesh.material = orginalMaterial;
			}
			
			physicsWorld.step(timeStep);
			debugDraw.debugDrawWorld();
			_view.render();
		}
	}

}