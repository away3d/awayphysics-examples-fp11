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
	import away3d.primitives.SphereGeometry;

	import awayphysics.collision.shapes.AWPBoxShape;
	import awayphysics.collision.shapes.AWPConeShape;
	import awayphysics.collision.shapes.AWPCylinderShape;
	import awayphysics.collision.shapes.AWPSphereShape;
	import awayphysics.collision.shapes.AWPStaticPlaneShape;
	import awayphysics.dynamics.AWPDynamicsWorld;
	import awayphysics.dynamics.AWPRigidBody;
	import awayphysics.debug.AWPDebugDraw;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Vector3D;

	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class BasicTest extends Sprite {
		private var _view : View3D;
		private var _light : PointLight;
		private var lightPicker:StaticLightPicker;
		private var _physicsWorld : AWPDynamicsWorld;
		private var _sphereShape : AWPSphereShape;
		private var _timeStep : Number = 1.0 / 60;
		
		private var debugDraw:AWPDebugDraw;

		public function BasicTest() {
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
			
			lightPicker = new StaticLightPicker([_light]);

			_view.camera.lens.far = 10000;
			_view.camera.y = _light.y;
			_view.camera.z = _light.z;
			_view.camera.rotationX = 25;

			// init the physics world
			_physicsWorld = AWPDynamicsWorld.getInstance();
			_physicsWorld.initWithDbvtBroadphase();
			
			debugDraw = new AWPDebugDraw(_view, _physicsWorld);
			debugDraw.debugMode |= AWPDebugDraw.DBG_DrawTransform;

			// create ground mesh
			var material : ColorMaterial = new ColorMaterial(0x252525);
			material.lightPicker = lightPicker;
			var mesh:Mesh=new Mesh(new PlaneGeometry(50000, 50000),material);
			mesh.mouseEnabled = true;
			mesh.addEventListener(MouseEvent3D.MOUSE_UP, onMouseUp);
			_view.scene.addChild(mesh);

			// create ground shape and rigidbody
			var groundShape : AWPStaticPlaneShape = new AWPStaticPlaneShape(new Vector3D(0, 1, 0));
			var groundRigidbody : AWPRigidBody = new AWPRigidBody(groundShape, mesh, 0);
			_physicsWorld.addRigidBody(groundRigidbody);

			// create a wall
			mesh = new Mesh(new CubeGeometry(20000, 2000, 100),material);
			_view.scene.addChild(mesh);

			var wallShape : AWPBoxShape = new AWPBoxShape(20000, 2000, 100);
			var wallRigidbody : AWPRigidBody = new AWPRigidBody(wallShape, mesh, 0);
			_physicsWorld.addRigidBody(wallRigidbody);			
			
			wallRigidbody.position = new Vector3D(0, 1000, 2000);
			
			material = new ColorMaterial(0xfc6a11);
			material.lightPicker = lightPicker;
			
			// create rigidbody shapes
			_sphereShape = new AWPSphereShape(100);
			var boxShape : AWPBoxShape = new AWPBoxShape(200, 200, 200);
			var cylinderShape : AWPCylinderShape = new AWPCylinderShape(100, 200);
			var coneShape : AWPConeShape = new AWPConeShape(100, 200);

			// create rigidbodies
			var body : AWPRigidBody;
			var numx : int = 2;
			var numy : int = 8;
			var numz : int = 1;
			for (var i : int = 0; i < numx; i++ ) {
				for (var j : int = 0; j < numz; j++ ) {
					for (var k : int = 0; k < numy; k++ ) {
						// create boxes
						mesh = new Mesh(new CubeGeometry(200, 200, 200),material);
						_view.scene.addChild(mesh);
						body = new AWPRigidBody(boxShape, mesh, 1);
						body.friction = .9;
						body.ccdSweptSphereRadius = 0.5;
						body.ccdMotionThreshold = 1;
						body.position = new Vector3D(-1000 + i * 200, 100 + k * 200, j * 200);
						_physicsWorld.addRigidBody(body);

						// create cylinders
						mesh = new Mesh(new CylinderGeometry(100, 100, 200),material);
						_view.scene.addChild(mesh);
						body = new AWPRigidBody(cylinderShape, mesh, 1);
						body.friction = .9;
						body.ccdSweptSphereRadius = 0.5;
						body.ccdMotionThreshold = 1;
						body.position = new Vector3D(1000 + i * 200, 100 + k * 200, j * 200);
						_physicsWorld.addRigidBody(body);

						// create the Cones
						mesh = new Mesh(new ConeGeometry(100, 200),material);
						_view.scene.addChild(mesh);
						body = new AWPRigidBody(coneShape, mesh, 1);
						body.friction = .9;
						body.ccdSweptSphereRadius = 0.5;
						body.ccdMotionThreshold = 1;
						body.position = new Vector3D(i * 200, 100 + k * 230, j * 200);
						_physicsWorld.addRigidBody(body);
					}
				}
			}
			
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}

		private function onMouseUp(event : MouseEvent3D) : void {
			var pos : Vector3D = _view.camera.position;
			var mpos : Vector3D = new Vector3D(event.localPosition.x, event.localPosition.y, event.localPosition.z);

			var impulse : Vector3D = mpos.subtract(pos);
			impulse.normalize();
			impulse.scaleBy(2000);

			// shoot a sphere
			var material : ColorMaterial = new ColorMaterial(0xb35b11);
			material.lightPicker = lightPicker;

			var sphere : Mesh = new Mesh(new SphereGeometry(100),material);
			_view.scene.addChild(sphere);

			var body : AWPRigidBody = new AWPRigidBody(_sphereShape, sphere, 2);
			body.position = pos;
			body.ccdSweptSphereRadius = 0.5;
			body.ccdMotionThreshold = 1;
			_physicsWorld.addRigidBody(body);
			
			body.applyCentralImpulse(impulse);
		}

		private function handleEnterFrame(e : Event) : void {
			_physicsWorld.step(_timeStep, 1, _timeStep);
			
			//debugDraw.debugDrawWorld();
			_view.render();
		}
	}
}