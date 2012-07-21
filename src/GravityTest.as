package {
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.MouseEvent3D;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.*;
	import away3d.primitives.ConeGeometry;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.CylinderGeometry;
	import away3d.primitives.PlaneGeometry;
	
	import awayphysics.collision.shapes.AWPBoxShape;
	import awayphysics.collision.shapes.AWPConeShape;
	import awayphysics.collision.shapes.AWPCylinderShape;
	import awayphysics.collision.shapes.AWPStaticPlaneShape;
	import awayphysics.debug.AWPDebugDraw;
	import awayphysics.dynamics.AWPDynamicsWorld;
	import awayphysics.dynamics.AWPRigidBody;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Vector3D;

	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class GravityTest extends Sprite {
		private var _view : View3D;
		private var _light : PointLight;
		private var lightPicker:StaticLightPicker;
		private var physicsWorld : AWPDynamicsWorld;
		private var timeStep : Number = 1.0 / 60;
		private var isMouseDown : Boolean;
		private var currMousePos : Vector3D;
		
		private var debugDraw:AWPDebugDraw;

		public function GravityTest() {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e : Event = null) : void {
			removeEventListener(Event.ADDED_TO_STAGE, init);

			_view = new View3D();
			this.addChild(_view);
			this.addChild(new AwayStats(_view));

			_light = new PointLight();
			_light.y = 0;
			_light.z = -3000;
			_view.scene.addChild(_light);
			
			lightPicker = new StaticLightPicker([_light]);

			_view.camera.lens.far = 10000;
			_view.camera.y = _light.y;
			_view.camera.z = _light.z;

			// init the physics world
			physicsWorld = AWPDynamicsWorld.getInstance();
			physicsWorld.initWithDbvtBroadphase();
			physicsWorld.gravity = new Vector3D(0, 0, 20);
			
			debugDraw = new AWPDebugDraw(_view, physicsWorld);
			debugDraw.debugMode = AWPDebugDraw.DBG_NoDebug;

			// create ground mesh
			var material : ColorMaterial = new ColorMaterial(0x252525);
			material.lightPicker = lightPicker;
			var ground :Mesh = new Mesh(new PlaneGeometry(50000, 50000), material);
			ground.mouseEnabled = true;
			ground.addEventListener(MouseEvent3D.MOUSE_DOWN, onMouseDown);
			ground.addEventListener(MouseEvent3D.MOUSE_UP, onMouseUp);
			ground.addEventListener(MouseEvent3D.MOUSE_MOVE, onMouseMove);
			_view.scene.addChild(ground);

			// create ground shape and rigidbody
			var groundShape : AWPStaticPlaneShape = new AWPStaticPlaneShape(new Vector3D(0, 1, 0));
			var groundRigidbody : AWPRigidBody = new AWPRigidBody(groundShape, ground, 0);
			physicsWorld.addRigidBody(groundRigidbody);
			
			groundRigidbody.rotation = new Vector3D( -90, 0, 0);

			material = new ColorMaterial(0xe28313);
			material.lightPicker = lightPicker;

			// create rigidbody shapes
			var boxShape : AWPBoxShape = new AWPBoxShape(100, 100, 100);
			var cylinderShape : AWPCylinderShape = new AWPCylinderShape(50, 100);
			var coneShape : AWPConeShape = new AWPConeShape(50, 100);

			// create rigidbodies
			var mesh : Mesh;
			var body : AWPRigidBody;
			for (var i : int; i < 20; i++ ) {
				// create boxes
				mesh = new Mesh(new CubeGeometry(100, 100, 100), material);
				_view.scene.addChild(mesh);
				body = new AWPRigidBody(boxShape, mesh, 1);
				body.friction = .9;
				body.linearDamping = .5;
				body.position = new Vector3D(-1000 + 2000 * Math.random(), -1000 + 2000 * Math.random(), -1000 - 2000 * Math.random());
				physicsWorld.addRigidBody(body);

				// create cylinders
				mesh = new Mesh(new CylinderGeometry(50, 50, 100) ,material);
				_view.scene.addChild(mesh);
				body = new AWPRigidBody(cylinderShape, mesh, 1);
				body.friction = .9;
				body.linearDamping = .5;
				body.position = new Vector3D(-1000 + 2000 * Math.random(), -1000 + 2000 * Math.random(), -1000 - 2000 * Math.random());
				physicsWorld.addRigidBody(body);

				// create the Cones
				mesh = new Mesh(new ConeGeometry(50, 100),material);
				_view.scene.addChild(mesh);
				body = new AWPRigidBody(coneShape, mesh, 1);
				body.friction = .9;
				body.linearDamping = .5;
				body.position = new Vector3D(-1000 + 2000 * Math.random(), -1000 + 2000 * Math.random(), -1000 - 2000 * Math.random());
				physicsWorld.addRigidBody(body);
			}
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}

		private function onMouseDown(event : MouseEvent3D) : void {
			isMouseDown = true;
			currMousePos = new Vector3D(event.localPosition.x, event.localPosition.z, -600);
			this.addEventListener(Event.ENTER_FRAME, handleGravity);
		}

		private function onMouseUp(event : MouseEvent3D) : void {
			isMouseDown = false;

			var pos : Vector3D = new Vector3D();
			for each (var body:AWPRigidBody in physicsWorld.nonStaticRigidBodies) {
				pos = pos.add(body.position);
			}
			pos.scaleBy(1 / physicsWorld.nonStaticRigidBodies.length);

			var impulse : Vector3D;
			for each (body in physicsWorld.nonStaticRigidBodies) {
				impulse = body.position.subtract(pos);
				impulse.scaleBy(5000 / impulse.lengthSquared);
				body.applyCentralImpulse(impulse);
			}

			physicsWorld.gravity = new Vector3D(0, 0, 20);
			this.removeEventListener(Event.ENTER_FRAME, handleGravity);
		}

		private function onMouseMove(event : MouseEvent3D) : void {
			if (isMouseDown) {
				currMousePos = new Vector3D(event.localPosition.x, event.localPosition.z, -600);
			}
		}

		private function handleGravity(e : Event) : void {
			var gravity : Vector3D;
			for each (var body:AWPRigidBody in physicsWorld.nonStaticRigidBodies) {
				gravity = currMousePos.subtract(body.position);
				gravity.normalize();
				gravity.scaleBy(100);

				body.gravity = gravity;
			}
		}

		private function handleEnterFrame(e : Event) : void {
			physicsWorld.step(timeStep);
			debugDraw.debugDrawWorld();
			_view.render();
		}
	}
}