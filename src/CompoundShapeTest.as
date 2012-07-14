package {
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.MouseEvent3D;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.PlaneGeometry;
	import away3d.primitives.SphereGeometry;

	import awayphysics.collision.shapes.AWPBoxShape;
	import awayphysics.collision.shapes.AWPCompoundShape;
	import awayphysics.collision.shapes.AWPSphereShape;
	import awayphysics.collision.shapes.AWPStaticPlaneShape;
	import awayphysics.debug.AWPDebugDraw;
	import awayphysics.dynamics.AWPDynamicsWorld;
	import awayphysics.dynamics.AWPRigidBody;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Vector3D;

	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class CompoundShapeTest extends Sprite {
		private var _view : View3D;
		private var _light : PointLight;
		private var _physicsWorld : AWPDynamicsWorld;
		private var _sphereShape : AWPSphereShape;
		private var timeStep : Number = 1.0 / 60;
		private var debugDraw : AWPDebugDraw;
		private var _lightPicker : StaticLightPicker;

		public function CompoundShapeTest() {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e : Event = null) : void {
			removeEventListener(Event.ADDED_TO_STAGE, init);

			_view = new View3D();
			this.addChild(_view);
			this.addChild(new AwayStats(_view));

			_light = new PointLight();
			_light.y = 3000;
			_light.z = -5000;
			_view.scene.addChild(_light);

			_view.camera.lens.far = 10000;
			_view.camera.y = _light.y;
			_view.camera.z = _light.z;
			_view.camera.rotationX = 25;

			// init the physics world
			_physicsWorld = AWPDynamicsWorld.getInstance();
			_physicsWorld.initWithDbvtBroadphase();
			_physicsWorld.gravity = new Vector3D(0, -20, 0);

			_lightPicker = new StaticLightPicker([_light]);

			debugDraw = new AWPDebugDraw(_view, _physicsWorld);
			debugDraw.debugMode = AWPDebugDraw.DBG_NoDebug;

			// create ground mesh
			var material : ColorMaterial = new ColorMaterial(0x252525);
			material.lightPicker = _lightPicker;
			var ground : Mesh = new Mesh();
			ground.geometry = new PlaneGeometry(50000, 50000, 4, 4);
			ground.material = material;
			ground.mouseEnabled = true;
			ground.addEventListener(MouseEvent3D.MOUSE_UP, onMouseUp);
			_view.scene.addChild(ground);

			// create ground shape and rigidbody
			var groundShape : AWPStaticPlaneShape = new AWPStaticPlaneShape(new Vector3D(0, 1, 0));
			var groundRigidbody : AWPRigidBody = new AWPRigidBody(groundShape, ground, 0);
			_physicsWorld.addRigidBody(groundRigidbody);

			// create a wall
			var wallGeometry : CubeGeometry = new CubeGeometry(20000, 5000, 100);
			var wall : Mesh = new Mesh(wallGeometry, material);
			_view.scene.addChild(wall);

			var wallShape : AWPBoxShape = new AWPBoxShape(20000, 5000, 100);
			var wallRigidbody : AWPRigidBody = new AWPRigidBody(wallShape, wall, 0);
			_physicsWorld.addRigidBody(wallRigidbody);

			wallRigidbody.position = new Vector3D(0, 2500, 2000);

			// create sphere shape
			_sphereShape = new AWPSphereShape(100);

			// create chair shape
			var chairShape : AWPCompoundShape = createChairShape();
			material = new ColorMaterial(0xe28313);
			material.lightPicker = _lightPicker;

			// create chair rigidbodies
			var mesh : Mesh;
			var body : AWPRigidBody;
			for (var i : int; i < 10; i++ ) {
				mesh = createChairMesh(material);
				_view.scene.addChild(mesh);
				body = new AWPRigidBody(chairShape, mesh, 1);
				body.friction = .9;
				body.position = new Vector3D(0, 500 + 1000 * i, 0);
				_physicsWorld.addRigidBody(body);
			}

			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}

		private function createChairMesh(material : ColorMaterial) : Mesh {
			var mesh : Mesh = new Mesh();

			var child1 : Mesh = new Mesh();
			child1.geometry = new CubeGeometry(460, 60, 500);
			child1.material = material;

			var child2 : Mesh = new Mesh();
			child2.geometry = new CubeGeometry(60, 400, 60);
			child2.material = material;

			var child3 : Mesh = new Mesh();
			child2.geometry = new CubeGeometry(60, 400, 60);
			child2.material = material;

			var child4 : Mesh = new Mesh();
			child2.geometry = new CubeGeometry(60, 400, 60);
			child2.material = material;

			var child5 : Mesh = new Mesh();
			child2.geometry = new CubeGeometry(60, 400, 60);
			child2.material = material;

			var child6 : Mesh = new Mesh();
			child2.geometry = new CubeGeometry(400, 500, 60);
			child2.material = material;

			child2.position = new Vector3D(-180, -220, -200);
			child3.position = new Vector3D(180, -220, -200);
			child4.position = new Vector3D(180, -220, 200);
			child5.position = new Vector3D(-180, -220, 200);
			child6.position = new Vector3D(0, 250, 250);
			child6.rotate(new Vector3D(1, 0, 0), 20);
			mesh.addChild(child1);
			mesh.addChild(child2);
			mesh.addChild(child3);
			mesh.addChild(child4);
			mesh.addChild(child5);
			mesh.addChild(child6);
			return mesh;
		}

		private function createChairShape() : AWPCompoundShape {
			var boxShape1 : AWPBoxShape = new AWPBoxShape(460, 60, 500);
			var boxShape2 : AWPBoxShape = new AWPBoxShape(60, 400, 60);
			var boxShape3 : AWPBoxShape = new AWPBoxShape(400, 500, 60);

			var chairShape : AWPCompoundShape = new AWPCompoundShape();
			chairShape.addChildShape(boxShape1, new Vector3D(0, 0, 0), new Vector3D());
			chairShape.addChildShape(boxShape2, new Vector3D(-180, -220, -200), new Vector3D());
			chairShape.addChildShape(boxShape2, new Vector3D(180, -220, -200), new Vector3D());
			chairShape.addChildShape(boxShape2, new Vector3D(180, -220, 200), new Vector3D());
			chairShape.addChildShape(boxShape2, new Vector3D(-180, -220, 200), new Vector3D());

			chairShape.addChildShape(boxShape3, new Vector3D(0, 250, 250), new Vector3D(20, 0, 0));

			return chairShape;
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
			_physicsWorld.step(timeStep);
			debugDraw.debugDrawWorld();
			_view.render();
		}
	}
}