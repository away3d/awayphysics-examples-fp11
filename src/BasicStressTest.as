package {
	import away3d.materials.methods.FilteredShadowMapMethod;
	import away3d.primitives.ConeGeometry;
	import away3d.primitives.CylinderGeometry;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.lights.DirectionalLight;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.PlaneGeometry;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.materials.ColorMaterial;

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

	[SWF(backgroundColor="#ffffff", frameRate="60", width="1024", height="768")]
	public class BasicStressTest extends Sprite {
		private var _view : View3D;
		private var _physicsWorld : AWPDynamicsWorld;
		private var _sphereShape : AWPSphereShape;
		private var _timeStep : Number = 1.0 / 60;
		// light objects
		private var _sunLight : DirectionalLight;
		private var _lightPicker : StaticLightPicker;

		public function BasicStressTest() {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function initLights() : void {
			_sunLight = new DirectionalLight(-300, -300, -500);
			_sunLight.color = 0xfffdc5;
			_sunLight.ambient = 1;
			_view.scene.addChild(_sunLight);

			_lightPicker = new StaticLightPicker([_sunLight]);
		}

		private function init(e : Event = null) : void {
			removeEventListener(Event.ADDED_TO_STAGE, init);

			_view = new View3D();
			_view.antiAlias = 4;
			this.addChild(_view);
			this.addChild(new AwayStats(_view));

			initLights();

			_view.camera.lens.far = 5000;
			_view.camera.x = 1000;
			_view.camera.y = 500;
			_view.camera.z = -3000;
			_view.camera.rotationX = 25;

			// init the physics world
			_physicsWorld = AWPDynamicsWorld.getInstance();
			_physicsWorld.initWithDbvtBroadphase();
			_physicsWorld.gravity = new Vector3D(0, -40, 0);

			// create ground mesh
			var material : ColorMaterial = new ColorMaterial(0x252525);
			material.shadowMethod = new FilteredShadowMapMethod(_sunLight);
			material.lightPicker = _lightPicker;
			var ground : Mesh = new Mesh();
			ground.geometry = new PlaneGeometry(10000, 10000, 1, 1, false);
			ground.castsShadows = true;
			ground.material = material;
			_view.scene.addChild(ground);

			// create ground shape and rigidbody
			var groundShape : AWPStaticPlaneShape = new AWPStaticPlaneShape(new Vector3D(0, 0, -1));
			var groundRigidbody : AWPRigidBody = new AWPRigidBody(groundShape, ground, 0);
			_physicsWorld.addRigidBody(groundRigidbody);

			// set ground rotation
			var rot : Vector3D = new Vector3D(90, 0, 0);
			groundRigidbody.rotation = rot;

			material = new ColorMaterial(0xfc6a11);
			material.lightPicker = _lightPicker;
			material.shadowMethod = new FilteredShadowMapMethod(_sunLight);

			// create rigidbody shapes
			_sphereShape = new AWPSphereShape(100);
			var boxShape : AWPBoxShape = new AWPBoxShape(100, 100, 100);
			var cylinderShape : AWPCylinderShape = new AWPCylinderShape(50, 100);
			var coneShape : AWPConeShape = new AWPConeShape(50, 100);

			// create geometry
			var boxGeometry : CubeGeometry = new CubeGeometry(100, 100, 100);
			var cylinderGeometry : CylinderGeometry = new CylinderGeometry(50, 50, 100);
			var coneGeometry : ConeGeometry = new ConeGeometry(50, 100);

			// create rigidbodies
			var mesh : Mesh;
			var body : AWPRigidBody;
			var numx : int = 10;
			var numy : int = 10;
			var numz : int = 1;
			for (var i : int = 0; i < numx; i++ ) {
				for (var j : int = 0; j < numz; j++ ) {
					for (var k : int = 0; k < numy; k++ ) {
						// create boxes
						mesh = new Mesh();
						mesh.geometry = boxGeometry;
						mesh.material = material;
						_view.scene.addChild(mesh);
						body = new AWPRigidBody(boxShape, mesh, 1);
						body.friction = .9;
						body.position = new Vector3D(-1000 + i * 200, 100 + k * 200, j * 200);
						_physicsWorld.addRigidBody(body);

						// create cylinders
						mesh = new Mesh();
						mesh.geometry = cylinderGeometry;
						mesh.material = material;
						_view.scene.addChild(mesh);
						body = new AWPRigidBody(cylinderShape, mesh, 1);
						body.friction = .9;
						body.position = new Vector3D(1000 + i * 200, 100 + k * 200, j * 200);
						_physicsWorld.addRigidBody(body);

						// create the Cones
						mesh = new Mesh();
						mesh.geometry = coneGeometry;
						mesh.material = material;
						_view.scene.addChild(mesh);
						body = new AWPRigidBody(coneShape, mesh, 1);
						body.friction = .9;
						body.position = new Vector3D(i * 200, 100 + k * 230, j * 200);
						_physicsWorld.addRigidBody(body);
					}
				}
			}

			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}

		private function handleEnterFrame(e : Event) : void {
			_physicsWorld.step(_timeStep, 1, _timeStep);
			_view.render();
		}
	}
}