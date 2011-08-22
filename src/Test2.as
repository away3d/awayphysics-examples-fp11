package  
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Vector3D;
	import flash.geom.Matrix3D;
	
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
	public class Test2 extends Sprite
	{
		private var _view:View3D;
		private var _light:PointLight;
		
		private var physicsWorld:AWPDynamicsWorld;
		
		private var timeStep:Number = 1.0 / 60;
		
		private var isMouseDown:Boolean;
		
		private var currMousePos:Vector3D;
		
		public function Test2() 
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
			_light.y = 0;
			_light.z = -3000;
			_view.scene.addChild(_light);
			
			_view.camera.lens.far = 10000;
			_view.camera.y = _light.y;
			_view.camera.z = _light.z;
			
			//init the physics world
			physicsWorld = AWPDynamicsWorld.getInstance();
			physicsWorld.initWithDbvtBroadphase();
			physicsWorld.gravity = new Vector3D(0, 0, 20);
			
			//create ground mesh
			var material:ColorMaterial = new ColorMaterial(0x00ff00);
			material.lights = [_light];
			var ground:Plane = new Plane(material, 50000, 50000);
			ground.mouseEnabled = true;
			ground.mouseDetails = true;
			ground.addEventListener(MouseEvent3D.MOUSE_DOWN, onMouseDown);
			ground.addEventListener(MouseEvent3D.MOUSE_UP, onMouseUp);
			ground.addEventListener(MouseEvent3D.MOUSE_MOVE, onMouseMove);
			_view.scene.addChild(ground);
			
			//create ground shape and rigidbody
			var groundShape:AWPStaticPlaneShape = new AWPStaticPlaneShape( new Vector3D(0, 0, -1));
			var groundRigidbody:AWPRigidBody = new AWPRigidBody(groundShape, new Away3DMesh(ground), 0);
			physicsWorld.addRigidBody(groundRigidbody);
			
			material = new ColorMaterial(0xffff00);
			material.lights = [_light];
			
			//create rigidbody shapes
			var boxShape:AWPBoxShape = new AWPBoxShape(100, 100, 100);
			var cylinderShape:AWPCylinderShape = new AWPCylinderShape(50, 100);
			var coneShape:AWPConeShape = new AWPConeShape(50, 100);
			
			//create rigidbodies
			var mesh:Mesh;
			var shape:AWPShape;
			var body:AWPRigidBody;
			for (var i:int; i < 20; i++ ) {
				//create boxes
				mesh = new Cube(material, 100, 100, 100);
				_view.scene.addChild(mesh);
				body = new AWPRigidBody(boxShape, new Away3DMesh(mesh), 1);
				body.friction = .9;
				body.linearDamping = .5;
				body.position = new Vector3D( -1000 + 2000 * Math.random(), -1000 + 2000 * Math.random(), -1000 - 2000 * Math.random());
				physicsWorld.addRigidBody(body);
				
				//create cylinders
				mesh = new Cylinder(material, 50, 50, 100);
				_view.scene.addChild(mesh);
				body = new AWPRigidBody(cylinderShape, new Away3DMesh(mesh), 1);
				body.friction = .9;
				body.linearDamping = .5;
				body.position = new Vector3D( -1000 + 2000 * Math.random(), -1000 + 2000 * Math.random(), -1000 - 2000 * Math.random());
				physicsWorld.addRigidBody(body);
				
				//create the Cones
				mesh = new Cone(material, 50, 100);
				_view.scene.addChild(mesh);
				body = new AWPRigidBody(coneShape, new Away3DMesh(mesh), 1);
				body.friction = .9;
				body.linearDamping = .5;
				body.position = new Vector3D( -1000 + 2000 * Math.random(), -1000 + 2000 * Math.random(), -1000 - 2000 * Math.random());
				physicsWorld.addRigidBody(body);
			}
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}
		
		private function onMouseDown(event:MouseEvent3D):void {
			isMouseDown = true;
			currMousePos = new Vector3D(event.localX, event.localY, -600);
			this.addEventListener(Event.ENTER_FRAME, handleGravity);
		}
		
		private function onMouseUp(event:MouseEvent3D) : void {
			isMouseDown = false;
			
			var pos:Vector3D = new Vector3D();
			for each(var body:AWPRigidBody in physicsWorld.nonStaticRigidBodies) {
				pos = pos.add(body.position);
				
			}
			pos.scaleBy(1 / physicsWorld.nonStaticRigidBodies.length);
			
			var impulse:Vector3D;
			for each(body in physicsWorld.nonStaticRigidBodies) {
				impulse = body.position.subtract(pos);
				impulse.scaleBy(500000 / impulse.lengthSquared);
				body.applyCentralImpulse(impulse);
			}
			
			physicsWorld.gravity = new Vector3D(0, 0, 20);
			this.removeEventListener(Event.ENTER_FRAME, handleGravity);
		}
		
		private function onMouseMove(event:MouseEvent3D):void {
			if (isMouseDown) {
				currMousePos = new Vector3D(event.localX, event.localY, -600);
			}
		}
		
		private function handleGravity(e:Event):void {
			var gravity:Vector3D;
			for each(var body:AWPRigidBody in physicsWorld.nonStaticRigidBodies) {
				gravity = currMousePos.subtract(body.position);
				gravity.normalize();
				gravity.scaleBy(100);
				
				body.gravity = gravity;
			}
		}
		
		private function handleEnterFrame(e:Event) : void
		{
			physicsWorld.step(timeStep);
			_view.render();
		}
	}
}