<<<<<<< OURS
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
	import away3d.events.MouseEvent3D;
	import away3d.materials.ColorMaterial;
	import away3d.entities.Mesh;
	import away3d.primitives.Plane;
	import away3d.primitives.Cube;
	import away3d.primitives.Cone;
	import away3d.primitives.Sphere;
	import away3d.primitives.Cylinder;
	
	import awayphysics.collision.shapes.*;
	import awayphysics.dynamics.*;
	import awayphysics.plugin.away3d.Away3DMesh;
	
	/**
	 * ...
	 * @author Muzer
	 */
	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class CollisionFilterTest extends Sprite
	{
		private var _view:View3D;
		private var _light:PointLight;
		
		private var physicsWorld:AWPDynamicsWorld;
		private var sphereBody:AWPRigidBody;
		private var timeStep:Number = 1.0 / 60;
		
		//defined collison group
		private const collsionGround:int = 1;
		private const collsionBox:int = 2;
		private const collsionCylinder:int = 4;
		private const collsionCone:int = 8;
		private const collsionSphere:int = 16;
		private const collisionAll:int = -1;
		
		private var keyRight   :Boolean = false;
		private var keyLeft    :Boolean = false;
		private var keyForward :Boolean = false;
		private var keyReverse :Boolean = false;
		
		public function CollisionFilterTest() 
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
			
			//create ground mesh
			var material:ColorMaterial = new ColorMaterial(0x00ff00);
			material.lights = [_light];
			var ground:Plane = new Plane(material, 50000, 50000);
			_view.scene.addChild(ground);
			
			//create ground shape and rigidbody
			var groundShape:AWPStaticPlaneShape = new AWPStaticPlaneShape(new Vector3D(0, 0, -1));
			var groundRigidbody:AWPRigidBody = new AWPRigidBody(groundShape, new Away3DMesh(ground), 0);
			//make ground collision enabled with other all rigidbodies
			physicsWorld.addRigidBodyWithGroup(groundRigidbody, collsionGround, collisionAll);
			
			//set ground rotation
			var rot:Matrix3D = new Matrix3D();
			rot.appendRotation( 90, new Vector3D(1, 0, 0));
			groundRigidbody.rotation = rot;
			
			material = new ColorMaterial(0xffff00);
			material.lights = [_light];
			
			var mesh:Mesh;
			var shape:AWPShape;
			var body:AWPRigidBody;
			
			//create boxe
			mesh = new Cube(material, 600, 600, 600);
			_view.scene.addChild(mesh);
			shape = new AWPBoxShape(600, 600, 600);
			body = new AWPRigidBody(shape, new Away3DMesh(mesh), 1);
			body.friction = .9;
			body.position = new Vector3D( -1000, 300, 0);
			//make box collision enabled with other all rigidbodies
			physicsWorld.addRigidBodyWithGroup(body, collsionBox, collisionAll);
			
			//create cylinder
			mesh = new Cylinder(material, 400, 400, 600);
			_view.scene.addChild(mesh);
			shape = new AWPCylinderShape(400, 600);
			body = new AWPRigidBody(shape, new Away3DMesh(mesh), 1);
			body.friction = .9;
			body.position = new Vector3D( 0, 300, 0);
			//make cylinder collision enabled with ground and box
			physicsWorld.addRigidBodyWithGroup(body, collsionCylinder, collsionGround | collsionBox);
			
			//create the Cone
			mesh = new Cone(material, 400, 600);
			_view.scene.addChild(mesh);
			shape = new AWPConeShape(400, 600);
			body = new AWPRigidBody(shape, new Away3DMesh(mesh), 1);
			body.friction = .9;
			body.position = new Vector3D( 1000, 300, 0);
			//make Cone collision enabled with ground and box
			physicsWorld.addRigidBodyWithGroup(body, collsionCone, collsionGround | collsionBox);
			
			
			material = new ColorMaterial(0xff0000);
			material.lights = [_light];
			
			//create the Sphere
			mesh = new Sphere(material, 200);
			_view.scene.addChild(mesh);
			shape = new AWPSphereShape(200);
			sphereBody = new AWPRigidBody(shape, new Away3DMesh(mesh), 1);
			sphereBody.position = new Vector3D( 0, 300, -1000);
			//make sphere collision enabled with ground and box
			physicsWorld.addRigidBodyWithGroup(sphereBody, collsionSphere, collsionGround | collsionBox);
			
			stage.addEventListener( KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener( KeyboardEvent.KEY_UP, keyUpHandler);
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
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
			
			physicsWorld.step(timeStep);
			_view.render();
		}
	}

=======
package {
	import awayphysics.collision.shapes.AWPConeShape;
	import awayphysics.collision.shapes.AWPShape;
	import awayphysics.collision.shapes.AWPBoxShape;
	import awayphysics.collision.shapes.AWPCylinderShape;
	import awayphysics.collision.shapes.AWPStaticPlaneShape;
	import awayphysics.dynamics.AWPDynamicsWorld;
	import awayphysics.collision.shapes.AWPSphereShape;
	import awayphysics.dynamics.AWPRigidBody;
	import awayphysics.plugin.away3d.Away3DMesh;

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
	import away3d.primitives.Cone;
	import away3d.primitives.Sphere;
	import away3d.primitives.Cylinder;

	public class CollisionFilterTest extends Sprite {
		private var _view : View3D;
		private var _light : PointLight;
		private var physicsWorld : AWPDynamicsWorld;
		private var sphereBody : AWPRigidBody;
		private var timeStep : Number = 1.0 / 60;
		// defined collison group
		private const collsionGround : int = 1;
		private const collsionBox : int = 2;
		private const collsionCylinder : int = 4;
		private const collsionCone : int = 8;
		private const collsionSphere : int = 16;
		private const collisionAll : int = -1;
		private var keyRight : Boolean = false;
		private var keyLeft : Boolean = false;
		private var keyForward : Boolean = false;
		private var keyReverse : Boolean = false;

		public function CollisionFilterTest() {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e : Event = null) : void {
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

			// init the physics world
			physicsWorld = AWPDynamicsWorld.getInstance();
			physicsWorld.initWithDbvtBroadphase();

			// create ground mesh
			var material : ColorMaterial = new ColorMaterial(0x252525);
			material.lights = [_light];
			var ground : Plane = new Plane(material, 50000, 50000);
			_view.scene.addChild(ground);

			// create ground shape and rigidbody
			var groundShape : AWPStaticPlaneShape = new AWPStaticPlaneShape(new Vector3D(0, 0, -1));
			var groundRigidbody : AWPRigidBody = new AWPRigidBody(groundShape, new Away3DMesh(ground), 0);
			// make ground collision enabled with other all rigidbodies
			physicsWorld.addRigidBodyWithGroup(groundRigidbody, collsionGround, collisionAll);

			// set ground rotation
			var rot : Matrix3D = new Matrix3D();
			rot.appendRotation(90, new Vector3D(1, 0, 0));
			groundRigidbody.rotation = rot;

			material = new ColorMaterial(0xfc6a11);
			material.lights = [_light];

			var mesh : Mesh;
			var shape : AWPShape;
			var body : AWPRigidBody;

			// create boxe
			mesh = new Cube(material, 600, 600, 600);
			_view.scene.addChild(mesh);
			shape = new AWPBoxShape(600, 600, 600);
			body = new AWPRigidBody(shape, new Away3DMesh(mesh), 1);
			body.friction = .9;
			body.position = new Vector3D(-1000, 300, 0);
			// make box collision enabled with other all rigidbodies
			physicsWorld.addRigidBodyWithGroup(body, collsionBox, collisionAll);

			// create cylinder
			mesh = new Cylinder(material, 400, 400, 600);
			_view.scene.addChild(mesh);
			shape = new AWPCylinderShape(400, 600);
			body = new AWPRigidBody(shape, new Away3DMesh(mesh), 1);
			body.friction = .9;
			body.position = new Vector3D(0, 300, 0);
			// make cylinder collision enabled with ground and box
			physicsWorld.addRigidBodyWithGroup(body, collsionCylinder, collsionGround | collsionBox);

			// create the Cone
			mesh = new Cone(material, 400, 600);
			_view.scene.addChild(mesh);
			shape = new AWPConeShape(400, 600);
			body = new AWPRigidBody(shape, new Away3DMesh(mesh), 1);
			body.friction = .9;
			body.position = new Vector3D(1000, 300, 0);
			// make Cone collision enabled with ground and box
			physicsWorld.addRigidBodyWithGroup(body, collsionCone, collsionGround | collsionBox);

			material = new ColorMaterial(0xb35b11);
			material.lights = [_light];

			// create the Sphere
			mesh = new Sphere(material, 200);
			_view.scene.addChild(mesh);
			shape = new AWPSphereShape(200);
			sphereBody = new AWPRigidBody(shape, new Away3DMesh(mesh), 1);
			sphereBody.position = new Vector3D(0, 300, -1000);
			// make sphere collision enabled with ground and box
			physicsWorld.addRigidBodyWithGroup(sphereBody, collsionSphere, collsionGround | collsionBox);

			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}

		private function keyDownHandler(event : KeyboardEvent) : void {
			switch(event.keyCode) {
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

		private function keyUpHandler(event : KeyboardEvent) : void {
			switch(event.keyCode) {
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

		private function handleEnterFrame(e : Event) : void {
			if (keyLeft) {
				sphereBody.applyCentralForce(new Vector3D(-50, 0, 0));
			}
			if (keyRight) {
				sphereBody.applyCentralForce(new Vector3D(50, 0, 0));
			}
			if (keyForward) {
				sphereBody.applyCentralForce(new Vector3D(0, 0, 50));
			}
			if (keyReverse) {
				sphereBody.applyCentralForce(new Vector3D(0, 0, -50));
			}

			physicsWorld.step(timeStep);
			_view.render();
		}
	}
>>>>>>> THEIRS
}
