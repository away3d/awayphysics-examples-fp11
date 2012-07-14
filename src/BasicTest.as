package {
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.MouseEvent3D;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
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

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Vector3D;

	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class BasicTest extends Sprite {
		private var _view : View3D;
		private var _light : PointLight;
		private var _physicsWorld : AWPDynamicsWorld;
		private var _sphereShape : AWPSphereShape;
		private var _timeStep : Number = 1.0 / 60;
		private var _lightPicker : StaticLightPicker;

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
			_light.y = 1500;
			_light.z = -4000;
			_view.scene.addChild(_light);

			_view.camera.lens.far = 10000;
			_view.camera.y = _light.y;
			_view.camera.z = _light.z;
			_view.camera.rotationX = 25;

			_view.antiAlias = 4;

			// init the physics world
			_physicsWorld = AWPDynamicsWorld.getInstance();
			_physicsWorld.initWithDbvtBroadphase();
			_physicsWorld.gravity = new Vector3D(0, -20, 0);

			_lightPicker = new StaticLightPicker([_light]);

			// create ground mesh
			var material : ColorMaterial = new ColorMaterial(0xff0000);
			material.lightPicker = _lightPicker;

			var groundGeometry : PlaneGeometry = new PlaneGeometry(50000, 50000, 8, 8);
			var ground : Mesh = new Mesh(groundGeometry, material);
			ground.mouseEnabled = true;
			ground.addEventListener(MouseEvent3D.MOUSE_UP, onMouseUp);
			_view.scene.addChild(ground);

			// create ground shape and rigidbody
			var groundShape : AWPStaticPlaneShape = new AWPStaticPlaneShape(new Vector3D(0, 1, 0));
			var groundRigidbody : AWPRigidBody = new AWPRigidBody(groundShape, ground, 0);
			groundRigidbody.friction = 1;
			groundRigidbody.restitution = 0.5;
			_physicsWorld.addRigidBody(groundRigidbody);

			// create a wall
			var wallGeometry : CubeGeometry = new CubeGeometry(20000, 2000, 100);
			var wall : Mesh = new Mesh(wallGeometry, material);
			_view.scene.addChild(wall);

			var wallShape : AWPBoxShape = new AWPBoxShape(20000, 2000, 100);
			var wallRigidbody : AWPRigidBody = new AWPRigidBody(wallShape, wall, 0);
			_physicsWorld.addRigidBody(wallRigidbody);

			wallRigidbody.position = new Vector3D(0, 1000, 2000);

			// create rigidbody shapes
			_sphereShape = new AWPSphereShape(100);
			var boxShape : AWPBoxShape = new AWPBoxShape(200, 200, 200);
			var cylinderShape : AWPCylinderShape = new AWPCylinderShape(100, 200);
			var coneShape : AWPConeShape = new AWPConeShape(100, 200);

			// create rigidbodies
			var mesh : Mesh;
			var body : AWPRigidBody;
			var numx : int = 2;
			var numy : int = 8;
			var numz : int = 1;

			var boxGeometry : CubeGeometry = new CubeGeometry(200, 200, 200);
			var cylinderGeometry : CylinderGeometry = new CylinderGeometry(100, 100, 200);
			var coneGeometry : ConeGeometry = new ConeGeometry(100, 200);

			for (var i : int = 0; i < numx; i++ ) {
				for (var j : int = 0; j < numz; j++ ) {
					for (var k : int = 0; k < numy; k++ ) {
						// create boxes
						mesh = new Mesh(boxGeometry, material);
						_view.scene.addChild(mesh);
						body = new AWPRigidBody(boxShape, mesh, 1);
						body.friction = .9;
						body.ccdSweptSphereRadius = 0.5;
						body.ccdMotionThreshold = 1;
						body.position = new Vector3D(-1000 + i * 200, 100 + k * 200, j * 200);
						_physicsWorld.addRigidBody(body);

						// create cylinders
						mesh = new Mesh(cylinderGeometry, material);
						_view.scene.addChild(mesh);
						body = new AWPRigidBody(cylinderShape, mesh, 1);
						body.friction = .9;
						body.ccdSweptSphereRadius = 0.5;
						body.ccdMotionThreshold = 1;
						body.position = new Vector3D(1000 + i * 200, 100 + k * 200, j * 200);
						_physicsWorld.addRigidBody(body);

						// create the Cones
						mesh = new Mesh(coneGeometry, material);
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
			var mpos : Vector3D = new Vector3D(event.localPosition.x,event.localPosition.y,event.localPosition.z);

			var impulse : Vector3D = mpos.subtract(pos);
			impulse.normalize();
			impulse.scaleBy(300);

			// shoot a sphere
			var material : ColorMaterial = new ColorMaterial(0xffffff);
			material.lightPicker = _lightPicker;
			var sphereGeometry : SphereGeometry = new SphereGeometry(100);
			var sphere : Mesh = new Mesh(sphereGeometry, material);
			_view.scene.addChild(sphere);

			var body : AWPRigidBody = new AWPRigidBody(_sphereShape, sphere, 2);
			body.position = pos;
			body.friction = 0.5;
			body.restitution = 0.5;
			body.ccdSweptSphereRadius = 0.5;
			body.ccdMotionThreshold = 1;
			_physicsWorld.addRigidBody(body);

			body.applyCentralImpulse(impulse);
		}

		private function handleEnterFrame(e : Event) : void {
			_physicsWorld.step(_timeStep, 1, _timeStep);
			_view.render();
		}
	}
}