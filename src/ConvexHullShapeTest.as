package {
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.LoaderEvent;
	import away3d.events.MouseEvent3D;
	import away3d.lights.PointLight;
	import away3d.loaders.Loader3D;
	import away3d.loaders.parsers.Parsers;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.*;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.SphereGeometry;
	import away3d.primitives.PlaneGeometry;
	
	import awayphysics.collision.shapes.AWPBoxShape;
	import awayphysics.collision.shapes.AWPConvexHullShape;
	import awayphysics.collision.shapes.AWPSphereShape;
	import awayphysics.collision.shapes.AWPStaticPlaneShape;
	import awayphysics.debug.AWPDebugDraw;
	import awayphysics.dynamics.AWPDynamicsWorld;
	import awayphysics.dynamics.AWPRigidBody;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;

	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class ConvexHullShapeTest extends Sprite {
		private var _view : View3D;
		private var _light : PointLight;
		private var lightPicker:StaticLightPicker;
		private var _physicsWorld : AWPDynamicsWorld;
		private var _timeStep : Number = 1.0 / 60;
		
		private var debugDraw:AWPDebugDraw;

		public function ConvexHullShapeTest() {
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
			_physicsWorld.gravity = new Vector3D(0, -20, 0);
			
			debugDraw = new AWPDebugDraw(_view, _physicsWorld);
			debugDraw.debugMode = AWPDebugDraw.DBG_NoDebug;

			// create ground mesh
			var material : ColorMaterial = new ColorMaterial(0x252525);
			material.lightPicker = lightPicker;
			var ground : Mesh = new Mesh(new PlaneGeometry(50000, 50000),material);
			ground.mouseEnabled = true;
			ground.addEventListener(MouseEvent3D.MOUSE_UP, onMouseUp);
			_view.scene.addChild(ground);

			// create ground shape and rigidbody
			var groundShape : AWPStaticPlaneShape = new AWPStaticPlaneShape(new Vector3D(0, 1, 0));
			var groundRigidbody : AWPRigidBody = new AWPRigidBody(groundShape, ground, 0);
			_physicsWorld.addRigidBody(groundRigidbody);

			// create a wall
			var wall : Mesh = new Mesh(new CubeGeometry(20000, 5000, 100),material);
			_view.scene.addChild(wall);

			var wallShape : AWPBoxShape = new AWPBoxShape(20000, 5000, 100);
			var wallRigidbody : AWPRigidBody = new AWPRigidBody(wallShape, wall, 0);
			_physicsWorld.addRigidBody(wallRigidbody);

			wallRigidbody.position = new Vector3D(0, 100, 2000);
			
			Parsers.enableAllBundled();
			var _loader:Loader3D = new Loader3D();
			_loader.load(new URLRequest('../assets/convex.obj'));
			_loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onConvexResourceComplete);
			
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}
		
		private function onConvexResourceComplete(event : LoaderEvent) : void
		{
			var container:ObjectContainer3D = ObjectContainer3D(event.target);
			
			var materia:ColorMaterial = new ColorMaterial(0xfc6a11);
			materia.lightPicker = lightPicker;
			
			var model:Mesh = Mesh(container.getChildAt(0));
			model.geometry.scale(300);
			model.material = materia;
			
			var shape:AWPConvexHullShape = new AWPConvexHullShape(model.geometry);
			shape.localScaling = new Vector3D(1, 2, 0.5);
			
			var skin:Mesh;
			var body:AWPRigidBody;
			for (var i:int = 0; i < 20; i++ ) {
				skin = Mesh(model.clone());
				_view.scene.addChild(skin);
				body = new AWPRigidBody(shape, skin, 1);
				body.friction = 0.9;
				body.position = new Vector3D(0, 200 + 400 * i, 0);
				_physicsWorld.addRigidBody(body);
			}
		}
		
		private function onMouseUp(event : MouseEvent3D) : void {
			var pos : Vector3D = _view.camera.position;
			var mpos : Vector3D = new Vector3D(event.localPosition.x, event.localPosition.y, event.localPosition.z);

			var impulse : Vector3D = mpos.subtract(pos);
			impulse.normalize();
			impulse.scaleBy(200);

			// shoot a sphere
			var material : ColorMaterial = new ColorMaterial(0xb35b11);
			material.lightPicker = lightPicker;

			var sphere : Mesh = new Mesh(new SphereGeometry(100),material);
			_view.scene.addChild(sphere);

			var shape:AWPSphereShape = new AWPSphereShape(100);
			var body : AWPRigidBody = new AWPRigidBody(shape, sphere, 2);
			body.position = pos;
			_physicsWorld.addRigidBody(body);

			body.applyCentralImpulse(impulse);
		}

		private function handleEnterFrame(e : Event) : void {
			_physicsWorld.step(_timeStep, 1, _timeStep);
			debugDraw.debugDrawWorld();
			_view.render();
		}
	}
}