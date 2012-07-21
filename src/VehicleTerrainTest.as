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
	import away3d.materials.TextureMaterial;
	import away3d.materials.lightpickers.*;
	import away3d.materials.methods.TerrainDiffuseMethod;
	import away3d.primitives.ConeGeometry;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.CylinderGeometry;
	import away3d.textures.BitmapTexture;
	
	import awayphysics.collision.dispatch.AWPCollisionObject;
	import awayphysics.collision.shapes.*;
	import awayphysics.dynamics.AWPDynamicsWorld;
	import awayphysics.dynamics.AWPRigidBody;
	import awayphysics.dynamics.vehicle.AWPRaycastVehicle;
	import awayphysics.dynamics.vehicle.AWPVehicleTuning;
	import awayphysics.dynamics.vehicle.AWPWheelInfo;
	import awayphysics.extend.AWPTerrain;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;

	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class VehicleTerrainTest extends Sprite {
		[Embed(source="../embeds/fskin.jpg")]
		private var CarSkin : Class;
		[Embed(source="../embeds/Heightmap.jpg")]
		private var HeightMap : Class;
		[Embed(source="../embeds/terrain_tex.jpg")]
		private var Albedo : Class;
		[Embed(source="../embeds/terrain_norms.jpg")]
		private var Normals : Class;
		[Embed(source="../embeds/grass.jpg")]
		private var Grass : Class;
		[Embed(source="../embeds/rock.jpg")]
		private var Rock : Class;
		[Embed(source="../embeds/beach.jpg")]
		private var Beach : Class;
		[Embed(source="/../embeds/terrain/terrain_splats.png")]
		private var Blend:Class;
		private var _view : View3D;
		private var _light : PointLight;
		private var carMaterial : TextureMaterial;
		private var lightPicker:StaticLightPicker;
		private var physicsWorld : AWPDynamicsWorld;
		private var timeStep : Number = 1.0 / 60;
		private var car : AWPRaycastVehicle;
		private var _engineForce : Number = 0;
		private var _breakingForce : Number = 0;
		private var _vehicleSteering : Number = 0;
		private var keyRight : Boolean = false;
		private var keyLeft : Boolean = false;

		public function VehicleTerrainTest() {
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

			_view.camera.lens.far = 100000;
			_view.camera.y = 2000;
			_view.camera.z = -2000;
			_view.camera.rotationX = 40;

			// init the physics world
			physicsWorld = AWPDynamicsWorld.getInstance();
			physicsWorld.initWithDbvtBroadphase();

			var terrainMethod : TerrainDiffuseMethod = new TerrainDiffuseMethod([new BitmapTexture(new Beach().bitmapData),new BitmapTexture(new Grass().bitmapData), new BitmapTexture(new Rock().bitmapData)], new BitmapTexture(new Blend().bitmapData) , [1,150, 100, 50]);

			var bmaterial : TextureMaterial = new TextureMaterial(new BitmapTexture(new Albedo().bitmapData));
			bmaterial.diffuseMethod = terrainMethod;
			bmaterial.normalMap = new BitmapTexture(new Normals().bitmapData);
			bmaterial.ambientColor = 0x202030;
			bmaterial.specular = .2;

			// create the terrain mesh
			var terrainBMD : Bitmap = new HeightMap();
			var terrain : AWPTerrain = new AWPTerrain(bmaterial, terrainBMD.bitmapData, 50000, 1200, 50000, 60, 60, 1200, 0, false);
			_view.scene.addChild(terrain);

			// create the terrain shape and rigidbody
			var terrainShape : AWPHeightfieldTerrainShape = new AWPHeightfieldTerrainShape(terrain);
			var terrainBody : AWPRigidBody = new AWPRigidBody(terrainShape, terrain, 0);
			physicsWorld.addRigidBody(terrainBody);

			var material : ColorMaterial = new ColorMaterial(0xfc6a11);
			material.lightPicker = lightPicker;

			// create rigidbody shapes
			var boxShape : AWPBoxShape = new AWPBoxShape(200, 200, 200);
			var cylinderShape : AWPCylinderShape = new AWPCylinderShape(100, 200);
			var coneShape : AWPConeShape = new AWPConeShape(100, 200);

			// create rigidbodies
			var mesh : Mesh;
			// var shape:AWPShape;
			var body : AWPRigidBody;
			for (var i : int = 0; i < 10; i++ ) {
				// create boxes
				mesh = new Mesh(new CubeGeometry(200, 200, 200), material);
				_view.scene.addChild(mesh);
				body = new AWPRigidBody(boxShape, mesh, 1);
				body.position = new Vector3D(-5000 + 10000 * Math.random(), 1000 + 1000 * Math.random(), -5000 + 10000 * Math.random());
				physicsWorld.addRigidBody(body);

				// create cylinders
				mesh = new Mesh(new CylinderGeometry(100, 100, 200), material);
				_view.scene.addChild(mesh);
				body = new AWPRigidBody(cylinderShape, mesh, 1);
				body.position = new Vector3D(-5000 + 10000 * Math.random(), 1000 + 1000 * Math.random(), -5000 + 10000 * Math.random());
				physicsWorld.addRigidBody(body);

				// create the Cones
				mesh = new Mesh(new ConeGeometry(100, 200), material);
				_view.scene.addChild(mesh);
				body = new AWPRigidBody(coneShape, mesh, 1);
				body.position = new Vector3D(-5000 + 10000 * Math.random(), 1000 + 1000 * Math.random(), -5000 + 10000 * Math.random());
				physicsWorld.addRigidBody(body);
			}

			carMaterial  = new TextureMaterial(new BitmapTexture(new CarSkin().bitmapData));
			carMaterial.lightPicker = lightPicker;

			 //load car model
			 Parsers.enableAllBundled();
			var _loader : Loader3D = new Loader3D();
			_loader.load(new URLRequest('../assets/car.obj'));
			_loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onCarResourceComplete);
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}

		private function onCarResourceComplete(event : LoaderEvent) : void {
			var container : ObjectContainer3D = ObjectContainer3D(event.target);
			_view.scene.addChild(container);
			var mesh : Mesh;

			for (var i : int = 0; i < container.numChildren; i++) {
				mesh = Mesh(container.getChildAt(i));
				mesh.geometry.scale(100);
				mesh.material = carMaterial;
			}

			// create the chassis body
			var carShape : AWPCompoundShape = createCarShape();
			var carBody : AWPRigidBody = new AWPRigidBody(carShape, container.getChildAt(4), 1200);
			carBody.activationState = AWPCollisionObject.DISABLE_DEACTIVATION;
			carBody.linearDamping = 0.1;
			carBody.angularDamping = 0.1;
			carBody.position = new Vector3D(0, 1500, 0);
			physicsWorld.addRigidBody(carBody);

			// create vehicle
			var turning : AWPVehicleTuning = new AWPVehicleTuning();
			turning.frictionSlip = 2;
			turning.suspensionStiffness = 100;
			turning.suspensionDamping = 0.85;
			turning.suspensionCompression = 0.83;
			turning.maxSuspensionTravelCm = 20;
			turning.maxSuspensionForce = 8000;
			car = new AWPRaycastVehicle(turning, carBody);
			physicsWorld.addVehicle(car);

			// add four wheels
			car.addWheel(container.getChildAt(0), new Vector3D(-110, 80, 170), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 50, 100, turning, true);
			car.addWheel(container.getChildAt(3), new Vector3D(110, 80, 170), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 50, 100, turning, true);
			car.addWheel(container.getChildAt(1), new Vector3D(-110, 90, -210), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 50, 100, turning, false);
			car.addWheel(container.getChildAt(2), new Vector3D(110, 90, -210), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 50, 100, turning, false);

			for (i = 0; i < car.getNumWheels(); i++) {
				var wheel : AWPWheelInfo = car.getWheelInfo(i);
				wheel.wheelsDampingRelaxation = 4.5;
				wheel.wheelsDampingCompression = 4.5;
				wheel.suspensionRestLength1 = 20;
				wheel.rollInfluence = 0.01;
			}
		}

		// create chassis shape
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
				_vehicleSteering -= 0.1;
				if (_vehicleSteering < -Math.PI / 6) {
					_vehicleSteering = -Math.PI / 6;
				}
			}
			if (keyRight) {
				_vehicleSteering += 0.1;
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

				_view.camera.position = car.getRigidBody().position.add(new Vector3D(0, 700, -1500));
				_view.camera.lookAt(car.getRigidBody().position);
			}
			_view.render();
		}
	}
}