package  
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Vector3D;
	import flash.geom.Matrix3D;
	import flash.ui.Keyboard;
	 
	import away3d.debug.AwayStats;
	import away3d.containers.View3D;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.entities.Mesh;
	import away3d.primitives.Plane;
	import away3d.primitives.Cube;
	import away3d.primitives.Sphere;
	 
	import awayphysics.collision.shapes.*;
	import awayphysics.dynamics.*;
	import awayphysics.events.AWPCollisionEvent;
	import awayphysics.plugin.away3d.Away3DMesh;
	 
	/**
	 * ...
	 * @author Muzer
	 */
	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class CollisionEventTest extends Sprite
	{
		private var _view:View3D;
		private var _light:PointLight;
		private var orginalMaterial:ColorMaterial;
		private var bodiesMaterial:Vector.<ColorMaterial>;
		
		private var physicsWorld:AWPDynamicsWorld;
		private var sphereBody:AWPRigidBody;
		private var boxes:Vector.<AWPRigidBody>;
		
		private var timeStep:Number = 1.0 / 60;
		
		private var keyRight   :Boolean = false;
		private var keyLeft    :Boolean = false;
		private var keyForward :Boolean = false;
		private var keyReverse :Boolean = false;
		
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
			
			_view.camera.lens.far = 10000;
			_view.camera.y = _light.y;
			_view.camera.z = _light.z;
			_view.camera.rotationX = 25;
			
			//init the physics world
			physicsWorld = AWPDynamicsWorld.getInstance();
			physicsWorld.initWithDbvtBroadphase();
			physicsWorld.collisionCallbackOn = true;
			
			//create ground mesh
			var material:ColorMaterial = new ColorMaterial(0x00ff00);
			material.lights = [_light];
			var ground:Plane = new Plane(material, 50000, 50000);
			_view.scene.addChild(ground);
			
			//create ground shape and rigidbody
			var groundShape:AWPStaticPlaneShape = new AWPStaticPlaneShape(new Vector3D(0, 0, -1));
			var groundRigidbody:AWPRigidBody = new AWPRigidBody(groundShape, new Away3DMesh(ground), 0);
			groundRigidbody.friction = .9;
			physicsWorld.addRigidBody(groundRigidbody);
			
			//set ground rotation
			var rot:Matrix3D = new Matrix3D();
			rot.appendRotation( 90, new Vector3D(1, 0, 0));
			groundRigidbody.rotation = rot;
			
			orginalMaterial = new ColorMaterial(0xffff00);
			orginalMaterial.lights = [_light];
			bodiesMaterial = new Vector.<ColorMaterial>();
			bodiesMaterial[0] = new ColorMaterial(0x0000ff);
			bodiesMaterial[0].lights = [_light];
			bodiesMaterial[1] = new ColorMaterial(0x00ffff);
			bodiesMaterial[1].lights = [_light];
			bodiesMaterial[2] = new ColorMaterial(0xff00ff);
			bodiesMaterial[2].lights = [_light];
			
			var mesh:Mesh;
			var shape:AWPShape;
			var body:AWPRigidBody;
			
			boxes = new Vector.<AWPRigidBody>();
			for (var i:int = 0; i < 3; i++ ) {
				mesh = new Cube(orginalMaterial, 600, 600, 600);
				_view.scene.addChild(mesh);
				shape = new AWPBoxShape(600, 600, 600);
				body = new AWPRigidBody(shape, new Away3DMesh(mesh), 1);
				body.friction = .9;
				body.position = new Vector3D( -1000 + (i * 800), 800, 0);
				physicsWorld.addRigidBody(body);
				boxes.push(body);
			}
			
			material = new ColorMaterial(0xff0000);
			material.lights = [_light];
			
			//create the Sphere
			mesh = new Sphere(material, 200);
			_view.scene.addChild(mesh);
			shape = new AWPSphereShape(200);
			sphereBody = new AWPRigidBody(shape, new Away3DMesh(mesh), 1);
			sphereBody.position = new Vector3D( 0, 800, -1000);
			physicsWorld.addRigidBody(sphereBody);
			
			//add collision listener to sphere body
			sphereBody.addEventListener(AWPCollisionEvent.COLLISION_ADDED, sphereCollisionAdded);
			
			stage.addEventListener( KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener( KeyboardEvent.KEY_UP, keyUpHandler);
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}
		
		private function sphereCollisionAdded(event:AWPCollisionEvent):void {
			
			for (var i:int = 0; i < boxes.length; i++ ) {
				var mesh:Mesh = Away3DMesh(boxes[i].skin).mesh;
				if (event.collisionObject == boxes[i]) {
					mesh.material = bodiesMaterial[i];
				}
			}
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
				sphereBody.applyCentralForce(new Vector3D( -50, 0, 0));
			}
			if(keyRight)
			{
				sphereBody.applyCentralForce(new Vector3D( 50, 0, 0));
			}
			if(keyForward)
			{
				sphereBody.applyCentralForce(new Vector3D( 0, 0, 50));
			}
			if(keyReverse)
			{
				sphereBody.applyCentralForce(new Vector3D( 0, 0, -50));
			}
			
			for each(var body:AWPRigidBody in boxes) {
				var mesh:Mesh = Away3DMesh(body.skin).mesh;
				mesh.material = orginalMaterial;
			}
			
			physicsWorld.step(timeStep);
			_view.render();
		}
	}

}