package {
	import awayphysics.dynamics.AWPDynamicsWorld;
	import awayphysics.collision.shapes.AWPStaticPlaneShape;
	import awayphysics.collision.shapes.AWPSphereShape;
	import awayphysics.dynamics.constraintsolver.AWPGeneric6DofConstraint;
	import awayphysics.dynamics.constraintsolver.AWPHingeConstraint;
	import awayphysics.dynamics.constraintsolver.AWPConeTwistConstraint;
	import awayphysics.dynamics.constraintsolver.AWPPoint2PointConstraint;
	import awayphysics.collision.shapes.AWPBoxShape;
	import awayphysics.plugin.away3d.Away3DMesh;
	import awayphysics.dynamics.AWPRigidBody;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Vector3D;
	import flash.geom.Matrix3D;
	import flash.utils.Timer;

	import away3d.debug.AwayStats;
	import away3d.containers.View3D;
	import away3d.lights.PointLight;
	import away3d.events.MouseEvent3D;
	import away3d.materials.ColorMaterial;
	import away3d.entities.Mesh;
	import away3d.primitives.Plane;
	import away3d.primitives.Cube;
	import away3d.primitives.Sphere;

	public class ConstraintTest extends Sprite {
		private var _view : View3D;
		private var _light : PointLight;
		private var physicsWorld : AWPDynamicsWorld;
		private var sphereShape : AWPSphereShape;
		private var timeStep : Number = 1.0 / 60;
		private var generic6Dof : AWPGeneric6DofConstraint;

		public function ConstraintTest() {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e : Event = null) : void {
			removeEventListener(Event.ADDED_TO_STAGE, init);

			_view = new View3D();
			this.addChild(_view);
			this.addChild(new AwayStats(_view));
			_view.antiAlias = 4;
			
			_light = new PointLight();
			_light.y = 2500;
			_light.z = -3000;
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
			ground.mouseEnabled = true;
			ground.mouseDetails = true;
			ground.addEventListener(MouseEvent3D.MOUSE_UP, onMouseUp);
			_view.scene.addChild(ground);

			// create ground shape and rigidbody
			var groundShape : AWPStaticPlaneShape = new AWPStaticPlaneShape(new Vector3D(0, 0, -1));
			var groundRigidbody : AWPRigidBody = new AWPRigidBody(groundShape, new Away3DMesh(ground), 0);
			physicsWorld.addRigidBody(groundRigidbody);

			// set ground rotation
			var rot : Matrix3D = new Matrix3D();
			rot.appendRotation(90, new Vector3D(1, 0, 0));
			groundRigidbody.rotation = rot;

			material = new ColorMaterial(0xfc6a11);
			material.lights = [_light];

			// create rigidbody shapes
			sphereShape = new AWPSphereShape(100);

			var mesh : Mesh;
			var currBody : AWPRigidBody = null;
			var prevBody : AWPRigidBody = null;

			// create a chain with AWPPoint2PointConstraint and box shape;
			var boxShape : AWPBoxShape = new AWPBoxShape(200, 200, 200);
			var p2p : AWPPoint2PointConstraint;
			for (var i : int = 0; i < 6; i++ ) {
				mesh = new Cube(material, 200, 200, 200);
				_view.scene.addChild(mesh);
				prevBody = currBody;
				currBody = new AWPRigidBody(sphereShape, new Away3DMesh(mesh), 2);
				currBody.position = new Vector3D(-1500 - (200 * i), 1500, 0);
				physicsWorld.addRigidBody(currBody);
				if (i == 0) {
					p2p = new AWPPoint2PointConstraint(currBody, new Vector3D(100, 100, 0));
					physicsWorld.addConstraint(p2p);
				} else {
					p2p = new AWPPoint2PointConstraint(prevBody, new Vector3D(-100, 0, 0), currBody, new Vector3D(100, 0, 0));
					physicsWorld.addConstraint(p2p);
				}
			}

			// create a bridge with AWPHingeConstraint and box shape
			boxShape = new AWPBoxShape(400, 80, 300);
			var hinge : AWPHingeConstraint;
			for (i = 0; i < 5; i++ ) {
				mesh = new Cube(material, 400, 80, 300);
				_view.scene.addChild(mesh);
				prevBody = currBody;
				currBody = new AWPRigidBody(boxShape, new Away3DMesh(mesh), 2);
				currBody.position = new Vector3D(-500, 2000, (310 * i));
				physicsWorld.addRigidBody(currBody);
				if (i == 0) {
					hinge = new AWPHingeConstraint(currBody, new Vector3D(0, 0, -155), new Vector3D(1, 0, 0));
					physicsWorld.addConstraint(hinge);
				} else {
					hinge = new AWPHingeConstraint(prevBody, new Vector3D(0, 0, 155), new Vector3D(1, 0, 0), currBody, new Vector3D(0, 0, -155), new Vector3D(1, 0, 0));
					physicsWorld.addConstraint(hinge);
				}
			}

			// create a door use AWPHingeConstraint
			boxShape = new AWPBoxShape(500, 700, 80);
			mesh = new Cube(material, 500, 700, 80);
			_view.scene.addChild(mesh);

			currBody = new AWPRigidBody(boxShape, new Away3DMesh(mesh), 1);
			currBody.position = new Vector3D(0, 800, 0);
			physicsWorld.addRigidBody(currBody);

			var doorHinge : AWPHingeConstraint = new AWPHingeConstraint(currBody, new Vector3D(-250, 0, 0), new Vector3D(0, 1, 0));
			doorHinge.setLimit(-Math.PI / 4, Math.PI / 4);
			// doorHinge.setAngularMotor(true, 10, 20);
			physicsWorld.addConstraint(doorHinge);

			// create a slider use AWPGeneric6DofConstraint
			boxShape = new AWPBoxShape(300, 300, 600);
			mesh = new Cube(material, 300, 300, 600);
			_view.scene.addChild(mesh);

			prevBody = new AWPRigidBody(boxShape, new Away3DMesh(mesh), 10);
			prevBody.friction = 0.9;
			prevBody.position = new Vector3D(600, 200, 400);
			physicsWorld.addRigidBody(prevBody);

			boxShape = new AWPBoxShape(200, 200, 600);
			mesh = new Cube(material, 200, 200, 600);
			_view.scene.addChild(mesh);

			currBody = new AWPRigidBody(boxShape, new Away3DMesh(mesh), 2);
			currBody.position = new Vector3D(600, 200, -400);
			physicsWorld.addRigidBody(currBody);

			generic6Dof = new AWPGeneric6DofConstraint(prevBody, new Vector3D(0, 0, -300), new Matrix3D(), currBody, new Vector3D(0, 0, 300), new Matrix3D());
			generic6Dof.setLinearLimit(new Vector3D(0, 0, 0), new Vector3D(0, 0, 400));
			generic6Dof.setAngularLimit(new Vector3D(0, 0, 0), new Vector3D(0, 0, 0));
			generic6Dof.getTranslationalLimitMotor().enableMotorZ = true;
			generic6Dof.getTranslationalLimitMotor().targetVelocity = new Vector3D(0, 0, 1000);
			generic6Dof.getTranslationalLimitMotor().maxMotorForce = new Vector3D(0, 0, 5);
			physicsWorld.addConstraint(generic6Dof, true);

			var timer : Timer = new Timer(1000);
			timer.addEventListener(TimerEvent.TIMER, onTimer);
			timer.start();

			// create a ConeTwist constraint
			boxShape = new AWPBoxShape(200, 600, 200);
			mesh = new Cube(material, 200, 600, 200);
			_view.scene.addChild(mesh);

			prevBody = new AWPRigidBody(boxShape, new Away3DMesh(mesh), 5);
			prevBody.position = new Vector3D(1000, 1000, 0);
			physicsWorld.addRigidBody(prevBody);

			mesh = new Cube(material, 200, 600, 200);
			_view.scene.addChild(mesh);

			currBody = new AWPRigidBody(boxShape, new Away3DMesh(mesh), 5);
			currBody.position = new Vector3D(1000, 400, 0);
			physicsWorld.addRigidBody(currBody);

			p2p = new AWPPoint2PointConstraint(prevBody, new Vector3D(0, 300, 0));
			physicsWorld.addConstraint(p2p);

			var coneTwist : AWPConeTwistConstraint = new AWPConeTwistConstraint(prevBody, new Vector3D(0, -300, 0), new Matrix3D(), currBody, new Vector3D(0, 300, 0), new Matrix3D());
			coneTwist.setLimit(Math.PI / 2, 0, Math.PI / 2);
			physicsWorld.addConstraint(coneTwist, true);

			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}

		private function onTimer(e : TimerEvent) : void {
			var vec : Number = generic6Dof.getTranslationalLimitMotor().targetVelocity.z;
			generic6Dof.getTranslationalLimitMotor().targetVelocity = new Vector3D(0, 0, -vec);
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

			var body : AWPRigidBody = new AWPRigidBody(sphereShape, new Away3DMesh(sphere), 2);
			body.position = pos;
			physicsWorld.addRigidBody(body);

			body.applyCentralImpulse(impulse);
		}

		private function handleEnterFrame(e : Event) : void {
			physicsWorld.step(timeStep);

			_view.render();
		}
	}
}