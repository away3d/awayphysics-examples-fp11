package {
	import awayphysics.collision.shapes.AWPBoxShape;
	import awayphysics.collision.shapes.AWPStaticPlaneShape;
	import awayphysics.collision.shapes.AWPCylinderShape;
	import awayphysics.collision.shapes.AWPConeShape;
	import awayphysics.dynamics.AWPRigidBody;
	import awayphysics.plugin.away3d.Away3DMesh;
	import awayphysics.collision.shapes.AWPSphereShape;
	import awayphysics.dynamics.AWPDynamicsWorld;

	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.MouseEvent3D;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.primitives.Cone;
	import away3d.primitives.Cube;
	import away3d.primitives.Cylinder;
	import away3d.primitives.Plane;
	import away3d.primitives.Sphere;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class BasicTest extends Sprite {
		private var _view : View3D;
		private var _light : PointLight;
		private var _physicsWorld : AWPDynamicsWorld;
		private var _sphereShape : AWPSphereShape;
		private var _timeStep : Number = 1.0 / 60;

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
			_light.z = -3000;
			_view.scene.addChild(_light);

			_view.camera.lens.far = 10000;
			_view.camera.y = _light.y;
			_view.camera.z = _light.z;
			_view.camera.rotationX = 25;
			_view.antiAlias = 4;

			// init the physics world
			_physicsWorld = AWPDynamicsWorld.getInstance();
			_physicsWorld.initWithDbvtBroadphase();

			// create ground mesh
			var material : ColorMaterial = new ColorMaterial(0x252525);
			material.lights = [_light];
			var ground : Plane = new Plane(material, 50000, 50000);
			ground.mouseEnabled = true;
			ground.mouseDetails = true;
			ground.addEventListener(MouseEvent3D.MOUSE_UP, onMouseUp);
			_view.scene.addChild(ground);

			// create ground shape and rigidbody
			var groundShape : AWPStaticPlaneShape = new AWPStaticPlaneShape(new Vector3D(0, 0, -1));
			var groundRigidbody : AWPRigidBody = new AWPRigidBody(groundShape, new Away3DMesh(ground), 0);
			_physicsWorld.addRigidBody(groundRigidbody);

			// set ground rotation
			var rot : Matrix3D = new Matrix3D();
			rot.appendRotation(90, new Vector3D(1, 0, 0));
			groundRigidbody.rotation = rot;

			// create a wall
			var wall : Cube = new Cube(material, 20000, 2000, 100);
			_view.scene.addChild(wall);

			var wallShape : AWPBoxShape = new AWPBoxShape(20000, 2000, 100);
			var wallRigidbody : AWPRigidBody = new AWPRigidBody(wallShape, new Away3DMesh(wall), 0);
			_physicsWorld.addRigidBody(wallRigidbody);

			wallRigidbody.position = new Vector3D(0, 1000, 2000);

			material = new ColorMaterial(0xfc6a11);
			material.lights = [_light];

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
			for (var i : int = 0; i < numx; i++ ) {
				for (var j : int = 0; j < numz; j++ ) {
					for (var k : int = 0; k < numy; k++ ) {
						// create boxes
						mesh = new Cube(material, 200, 200, 200);
						_view.scene.addChild(mesh);
						body = new AWPRigidBody(boxShape, new Away3DMesh(mesh), 1);
						body.friction = .9;
						body.position = new Vector3D(-1000 + i * 200, 100 + k * 200, j * 200);
						_physicsWorld.addRigidBody(body);

						// create cylinders
						mesh = new Cylinder(material, 100, 100, 200);
						_view.scene.addChild(mesh);
						body = new AWPRigidBody(cylinderShape, new Away3DMesh(mesh), 1);
						body.friction = .9;
						body.position = new Vector3D(1000 + i * 200, 100 + k * 200, j * 200);
						_physicsWorld.addRigidBody(body);

						// create the Cones
						mesh = new Cone(material, 100, 200);
						_view.scene.addChild(mesh);
						body = new AWPRigidBody(coneShape, new Away3DMesh(mesh), 1);
						body.friction = .9;
						body.position = new Vector3D(i * 200, 100 + k * 230, j * 200);
						_physicsWorld.addRigidBody(body);
					}
				}
			}

			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}

		private function onMouseUp(event : MouseEvent3D) : void {
			var pos : Vector3D = _view.camera.position;
			var mpos : Vector3D = new Vector3D(event.localX, event.localZ, event.localY);

			var impulse : Vector3D = mpos.subtract(pos);
			impulse.normalize();
			impulse.scaleBy(20000);

			// shoot a sphere
			var material : ColorMaterial = new ColorMaterial(0xb35b11);
			material.lights = [_light];

			var sphere : Sphere = new Sphere(material, 100);
			_view.scene.addChild(sphere);

			var body : AWPRigidBody = new AWPRigidBody(_sphereShape, new Away3DMesh(sphere), 2);
			body.position = pos;
			_physicsWorld.addRigidBody(body);

			body.applyCentralImpulse(impulse);
		}

		private function handleEnterFrame(e : Event) : void {
			_physicsWorld.step(_timeStep, 1, _timeStep);
			_view.render();
		}
	}
}