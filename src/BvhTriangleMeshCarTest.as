package {
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.LoaderEvent;
	import away3d.lights.PointLight;
	import away3d.loaders.Loader3D;
	import away3d.loaders.parsers.Parsers;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.*;
	import away3d.textures.BitmapTexture;
	import away3d.materials.TextureMaterial;
	import away3d.primitives.*;

	import awayphysics.collision.dispatch.AWPCollisionObject;
	import awayphysics.collision.shapes.*;
	import awayphysics.dynamics.*;
	import awayphysics.dynamics.vehicle.*;
	import awayphysics.debug.AWPDebugDraw;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;

	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class BvhTriangleMeshCarTest extends Sprite {
		[Embed(source="../embeds/fskin.jpg")]
		private var CarSkin : Class;
		private var _view : View3D;
		private var _light : PointLight;
		private var lightPicker:StaticLightPicker;
		private var physicsWorld : AWPDynamicsWorld;
		private var car : AWPRaycastVehicle;
		private var _engineForce : Number = 0;
		private var _breakingForce : Number = 0;
		private var _vehicleSteering : Number = 0;
		private var timeStep : Number = 1.0 / 60;
		private var keyRight : Boolean = false;
		private var keyLeft : Boolean = false;
		
		private var debugDraw:AWPDebugDraw;

		public function BvhTriangleMeshCarTest() {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e : Event = null) : void {
			removeEventListener(Event.ADDED_TO_STAGE, init);

			_view = new View3D();
			this.addChild(_view);
			this.addChild(new AwayStats(_view));

			_light = new PointLight();
			_light.y = 5000;
			_view.scene.addChild(_light);
			
			lightPicker = new StaticLightPicker([_light]);

			_view.camera.lens.far = 20000;
			_view.camera.y = 2000;
			_view.camera.z = -2000;
			_view.camera.rotationX = 40;

			// init the physics world
			physicsWorld = AWPDynamicsWorld.getInstance();
			physicsWorld.initWithDbvtBroadphase();
			
			debugDraw = new AWPDebugDraw(_view, physicsWorld); 
			debugDraw.debugMode = AWPDebugDraw.DBG_NoDebug;
			
			Parsers.enableAllBundled();

			// load scene model
			var _loader : Loader3D = new Loader3D();
			_loader.load(new URLRequest('../assets/scene.obj'));
			_loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onSceneResourceComplete);

			 //load car model
			_loader = new Loader3D();
			_loader.load(new URLRequest('../assets/car.obj'));
			_loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onCarResourceComplete);

			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}

		private function onSceneResourceComplete(event : LoaderEvent) : void {
			var container : ObjectContainer3D = ObjectContainer3D(event.target);
			_view.scene.addChild(container);

			var materia : ColorMaterial = new ColorMaterial(0xfa6c16);
			materia.lightPicker = lightPicker;
			var sceneMesh : Mesh = Mesh(container.getChildAt(0));
			sceneMesh.geometry.scale(1000);
			sceneMesh.material = materia;

			// create triangle mesh shape
			var sceneShape : AWPBvhTriangleMeshShape = new AWPBvhTriangleMeshShape(sceneMesh.geometry);
			var sceneBody : AWPRigidBody = new AWPRigidBody(sceneShape, sceneMesh, 0);
			physicsWorld.addRigidBody(sceneBody);

			var material : ColorMaterial = new ColorMaterial(0x252525);
			material.lightPicker = lightPicker;

			// create rigidbody shape
			var boxShape : AWPBoxShape = new AWPBoxShape(200, 200, 200);

			// create rigidbodies
			var mesh : Mesh;
			var body : AWPRigidBody;
			var numx : int = 10;
			var numy : int = 5;
			var numz : int = 1;
			for (var i : int = 0; i < numx; i++ ) {
				for (var j : int = 0; j < numz; j++ ) {
					for (var k : int = 0; k < numy; k++ ) {
						// create boxes
						mesh = new Mesh(new CubeGeometry(200, 200, 200),material);
						_view.scene.addChild(mesh);
						body = new AWPRigidBody(boxShape, mesh, 1);
						body.friction = .9;
						body.position = new Vector3D(-1500 + i * 200, 200 + k * 200, 1000 + j * 200);
						physicsWorld.addRigidBody(body);
					}
				}
			}
		}

		private function onCarResourceComplete(event : LoaderEvent) : void {
			var container : ObjectContainer3D = ObjectContainer3D(event.target);
			_view.scene.addChild(container);
			var mesh : Mesh;
			
			var carMaterial : TextureMaterial = new TextureMaterial(new BitmapTexture(new CarSkin().bitmapData));
			carMaterial.lightPicker = lightPicker;
			for (var i : int = 0; i < container.numChildren; i++) {
				mesh = Mesh(container.getChildAt(i));
				mesh.geometry.scale(100);
				mesh.material = carMaterial;
			}

			// create the chassis body
			var carShape : AWPCompoundShape = createCarShape();
			var carBody : AWPRigidBody = new AWPRigidBody(carShape, container.getChildAt(4), 1200);
			carBody.activationState = AWPCollisionObject.DISABLE_DEACTIVATION;
			carBody.friction = 0.9;
			carBody.linearDamping = 0.1;
			carBody.angularDamping = 0.1;
			carBody.position = new Vector3D(0, 300, -1000);
			physicsWorld.addRigidBody(carBody);

			// create vehicle
			var turning : AWPVehicleTuning = new AWPVehicleTuning();
			turning.frictionSlip = 2;
			turning.suspensionStiffness = 100;
			turning.suspensionDamping = 0.85;
			turning.suspensionCompression = 0.83;
			turning.maxSuspensionTravelCm = 20;
			turning.maxSuspensionForce = 10000;
			car = new AWPRaycastVehicle(turning, carBody);
			physicsWorld.addVehicle(car);

			// add four wheels
			car.addWheel(container.getChildAt(0), new Vector3D(-110, 80, 170), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 40, 60, turning, true);
			car.addWheel(container.getChildAt(3), new Vector3D(110, 80, 170), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 40, 60, turning, true);
			car.addWheel(container.getChildAt(1), new Vector3D(-110, 90, -210), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 40, 60, turning, false);
			car.addWheel(container.getChildAt(2), new Vector3D(110, 90, -210), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 40, 60, turning, false);

			for (i = 0; i < car.getNumWheels(); i++) {
				var wheel : AWPWheelInfo = car.getWheelInfo(i);
				wheel.wheelsDampingRelaxation = 4.5;
				wheel.wheelsDampingCompression = 4.5;
				wheel.suspensionRestLength1 = 20;
				wheel.rollInfluence = 0.01;
			}
		}

		// create car chassis shape
		private function createCarShape() : AWPCompoundShape {
			var boxShape1 : AWPBoxShape = new AWPBoxShape(260, 60, 570);
			var boxShape2 : AWPBoxShape = new AWPBoxShape(240, 70, 300);

			var carShape : AWPCompoundShape = new AWPCompoundShape();
			carShape.addChildShape(boxShape1, new Vector3D(0, 100, 0), new Vector3D());
			carShape.addChildShape(boxShape2, new Vector3D(0, 150, -30), new Vector3D());

			return carShape;
		}

		private function keyDownHandler(event : KeyboardEvent) : void {
			switch(event.keyCode) {
				case Keyboard.UP:
					_engineForce = 2500;
					_breakingForce = 0;
					break;
				case Keyboard.DOWN:
					_engineForce = -2500;
					_breakingForce = 0;
					break;
				case Keyboard.LEFT:
					keyLeft = true;
					keyRight = false;
					break;
				case Keyboard.RIGHT:
					keyRight = true;
					keyLeft = false;
					break;
				case Keyboard.SPACE:
					_breakingForce = 80;
					_engineForce = 0;
			}
		}

		private function keyUpHandler(event : KeyboardEvent) : void {
			switch(event.keyCode) {
				case Keyboard.UP:
					_engineForce = 0;
					break;
				case Keyboard.DOWN:
					_engineForce = 0;
					break;
				case Keyboard.LEFT:
					keyLeft = false;
					break;
				case Keyboard.RIGHT:
					keyRight = false;
					break;
				case Keyboard.SPACE:
					_breakingForce = 0;
			}
		}

		private function handleEnterFrame(e : Event) : void {
			physicsWorld.step(timeStep);

			if (keyLeft) {
				_vehicleSteering -= 0.05;
				if (_vehicleSteering < -Math.PI / 6) {
					_vehicleSteering = -Math.PI / 6;
				}
			}
			if (keyRight) {
				_vehicleSteering += 0.05;
				if (_vehicleSteering > Math.PI / 6) {
					_vehicleSteering = Math.PI / 6;
				}
			}

			if (car) {
				// control the car
				car.applyEngineForce(_engineForce, 0);
				car.setBrake(_breakingForce, 0);
				car.applyEngineForce(_engineForce, 1);
				car.setBrake(_breakingForce, 1);
				car.applyEngineForce(_engineForce, 2);
				car.setBrake(_breakingForce, 2);
				car.applyEngineForce(_engineForce, 3);
				car.setBrake(_breakingForce, 3);

				car.setSteeringValue(_vehicleSteering, 0);
				car.setSteeringValue(_vehicleSteering, 1);
				_vehicleSteering *= 0.9;

				_view.camera.position = car.getRigidBody().position.add(new Vector3D(0, 2000, -2500));
				_view.camera.lookAt(car.getRigidBody().position);
			}
			debugDraw.debugDrawWorld();
			_view.render();
		}
	}
}