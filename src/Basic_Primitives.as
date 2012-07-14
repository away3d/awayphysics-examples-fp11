/*

Basic primitives example in Away3d

Demonstrates:

How to setup basic primivites with physics.

Code by Ringo Blanken
freelance@ringo.nl
http://www.ringo.nl/en/

This code is distributed under the MIT License

Copyright (c)  

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

 */
package {
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.MouseEvent3D;
	import away3d.lights.DirectionalLight;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.methods.FilteredShadowMapMethod;
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
	import awayphysics.debug.AWPDebugDraw;
	import awayphysics.dynamics.AWPDynamicsWorld;
	import awayphysics.dynamics.AWPRigidBody;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;

	[SWF(backgroundColor="#000000", frameRate="60", quality="LOW")]
	public class Basic_Primitives extends Sprite {
		// signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf : Class;
		// engine variables
		private var scene : Scene3D;
		private var camera : Camera3D;
		private var view : View3D;
		private var cameraController : HoverController;
		// physics variables
		private var physicsWorld : AWPDynamicsWorld;
		private var maxSubStep : int = 2;
		private var fixedTimeStep : Number = 1 / 60;
		private var deltaTime : Number;
		private var lastTimeStep : Number = -1;
		// signature variables
		private var Signature : Sprite;
		private var SignatureBitmap : Bitmap;
		// scene objects
		private var light : DirectionalLight;
		private var lightPoint : PointLight;
		private var lightPicker : StaticLightPicker;
		private var direction : Vector3D;
		// navigation variables
		private var move : Boolean = false;
		private var lastPanAngle : Number;
		private var lastTiltAngle : Number;
		private var lastMouseX : Number;
		private var lastMouseY : Number;
		//
		//private var meshDebugger : MeshDebugger = new MeshDebugger();
		private var debugDraw : AWPDebugDraw;

		/**
		 * Constructor
		 */
		public function Basic_Primitives() {
			init();
		}

		/**
		 * Global initialise function
		 */
		private function init() : void {
			initEngine();
			initPhysicsEngine();
			initObjects();
			initListeners();
		}

		/**
		 * Initialise the engine
		 */
		private function initEngine() : void {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;

			scene = new Scene3D();

			// setup camera for optimal shadow rendering
			camera = new Camera3D();
			camera.lens.far = 10000;

			view = new View3D();
			view.scene = scene;
			view.camera = camera;
			view.antiAlias = 4;

			// setup controller to be used on the camera
			cameraController = new HoverController(camera, null, 180, 0, 5000, 10);

			// view.addSourceURL("srcview/index.html");
			addChild(view);

			// add signature
			Signature = Sprite(new SignatureSwf());
			SignatureBitmap = new Bitmap(new BitmapData(Signature.width, Signature.height, true, 0));
			stage.quality = StageQuality.HIGH;
			SignatureBitmap.bitmapData.draw(Signature);
			stage.quality = StageQuality.LOW;
			addChild(SignatureBitmap);

			addChild(new AwayStats(view));
		}

		/**
		 * Initialise Away3D physics engine
		 */
		private function initPhysicsEngine() : void {
			physicsWorld = AWPDynamicsWorld.getInstance();
			physicsWorld.initWithDbvtBroadphase();
			physicsWorld.gravity = new Vector3D(0, -30, 0);

			debugDraw = new AWPDebugDraw(view, physicsWorld);
			debugDraw.debugMode |= AWPDebugDraw.DBG_DrawTransform;
		}

		/**
		 * Initialise the scene objects
		 */
		private function initObjects() : void {
			light = new DirectionalLight(-1, -1, 1);
			direction = new Vector3D(-1, -1, 1);
			lightPicker = new StaticLightPicker([light, lightPoint]);
			scene.addChild(light);

			// create ground mesh
			var materialGround : ColorMaterial = new ColorMaterial(0x252525);
			materialGround.lightPicker = lightPicker;
			materialGround.shadowMethod = new FilteredShadowMapMethod(light);

			var groundGeometry : PlaneGeometry = new PlaneGeometry(20000, 20000, 8, 8);
			var ground : Mesh = new Mesh(groundGeometry, materialGround);
			ground.castsShadows = true;
			ground.mouseEnabled = true;
			
			ground.addEventListener(MouseEvent3D.MOUSE_UP, onMouseUpGround);
			scene.addChild(ground);

			// create ground shape and rigidbody
			var groundShape : AWPStaticPlaneShape = new AWPStaticPlaneShape(new Vector3D(0, 1, 0));
			var groundRigidbody : AWPRigidBody = new AWPRigidBody(groundShape, ground, 0);
			physicsWorld.addRigidBody(groundRigidbody);

			// create a wall
			var materialWall : ColorMaterial = new ColorMaterial(0xff0000);
			materialWall.lightPicker = lightPicker;
			var wallGeometry : CubeGeometry = new CubeGeometry(10000, 2000, 100, 4, 4);
			var wall : Mesh = new Mesh(wallGeometry, materialWall);
			scene.addChild(wall);

			// create wall shape and rigidbody
			var wallShape : AWPBoxShape = new AWPBoxShape(wallGeometry.width, wallGeometry.height, wallGeometry.depth);
			// mass 0 is static
			var wallRigidbody : AWPRigidBody = new AWPRigidBody(wallShape, wall, 0);
			physicsWorld.addRigidBody(wallRigidbody);

			wallRigidbody.position = new Vector3D(0, 1000, 2000);

			// create rigidbody shapes
			var boxShape : AWPBoxShape = new AWPBoxShape(200, 200, 200);
			var cylinderShape : AWPCylinderShape = new AWPCylinderShape(100, 200);
			var coneShape : AWPConeShape = new AWPConeShape(100, 200);

			// create rigidbodies
			var mesh : Mesh;
			var body : AWPRigidBody;
			var numx : int = 3;
			var numy : int = 6;
			var numz : int = 1;

			// create geometry
			var boxGeometry : CubeGeometry = new CubeGeometry(200, 200, 200);
			var cylinderGeometry : CylinderGeometry = new CylinderGeometry(100, 100, 200);
			var coneGeometry : ConeGeometry = new ConeGeometry(100, 200);

			// create materials
			var materialCone : ColorMaterial = new ColorMaterial(0xffff00);
			materialCone.lightPicker = lightPicker;
			var materialCylinder : ColorMaterial = new ColorMaterial(0xff00ff);
			materialCylinder.lightPicker = lightPicker;
			var materialBox : ColorMaterial = new ColorMaterial(0x0fff00);
			materialBox.lightPicker = lightPicker;

			// create primitives with physics
			for (var i : int = 0; i < numx; i++ ) {
				for (var j : int = 0; j < numz; j++ ) {
					for (var k : int = 0; k < numy; k++ ) {
						// create Boxes
						mesh = new Mesh(boxGeometry, materialBox);
						scene.addChild(mesh);
						// create rigidbody and shape
						body = new AWPRigidBody(boxShape, mesh, 2);
						body.friction = .9;
						body.ccdSweptSphereRadius = 0.5;
						body.ccdMotionThreshold = 1;
						body.position = new Vector3D(-1000 + i * 200, 100 + k * 200, j * 200);
						physicsWorld.addRigidBody(body);

						// create Cylinders
						mesh = new Mesh(cylinderGeometry, materialCylinder);
						scene.addChild(mesh);
						// create rigidbody and shape
						body = new AWPRigidBody(cylinderShape, mesh, 1);
						body.friction = .9;
						body.ccdSweptSphereRadius = 0.5;
						body.ccdMotionThreshold = 1;
						body.position = new Vector3D(1000 + i * 200, 100 + k * 200, j * 200);
						physicsWorld.addRigidBody(body);

						// create Cones
						mesh = new Mesh(coneGeometry, materialCone);
						scene.addChild(mesh);
						// create rigidbody and shape
						body = new AWPRigidBody(coneShape, mesh, 1);
						body.friction = .9;
						body.ccdSweptSphereRadius = 0.5;
						body.ccdMotionThreshold = 1;
						body.position = new Vector3D(i * 200, 100 + k * 230, j * 200);
						physicsWorld.addRigidBody(body);

						// meshDebugger.debug(mesh, view.scene,true,true,true);
					}
				}
			}
		}

		/**
		 * Initialise the listeners
		 */
		private function initListeners() : void {
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}

		/**
		 * Navigation and render loop
		 */
		private function onEnterFrame(event : Event) : void {
			if (move) {
				cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
			}

			direction.x = -Math.sin(getTimer() / 4000);
			direction.z = -Math.cos(getTimer() / 4000);
			light.direction = direction;

			// meshDebugger.update();

			updatePhysics();

			debugDraw.debugDrawWorld();

			view.render();
		}

		/**
		 * Update the physics world
		 */
		private function updatePhysics() : void {
			if (lastTimeStep == -1) lastTimeStep = getTimer();
			deltaTime = (getTimer() - lastTimeStep) / 1000;
			lastTimeStep = getTimer();
			physicsWorld.step(deltaTime, maxSubStep, fixedTimeStep);
		}

		/**
		 * Mouse down listener for navigation
		 */
		private function onMouseDown(event : MouseEvent) : void {
			lastPanAngle = cameraController.panAngle;
			lastTiltAngle = cameraController.tiltAngle;
			lastMouseX = stage.mouseX;
			lastMouseY = stage.mouseY;
			move = true;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * Mouse up listener for navigation
		 */
		private function onMouseUp(event : MouseEvent) : void {
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * Mouse up listener for ground
		 */
		private function onMouseUpGround(event : MouseEvent3D) : void {
			// shoot a sphere

			// calculate position
			var pos : Vector3D = camera.position;
			var mpos : Vector3D = new Vector3D(event.localPosition.x, event.localPosition.y, event.localPosition.z);

			// shoot with a impulse
			var impulse : Vector3D = mpos.subtract(pos);
			impulse.normalize();
			impulse.scaleBy(500);

			// create mesh
			var material : ColorMaterial = new ColorMaterial(0xb35b11);
			material.lightPicker = lightPicker;

			var sphereGeometry : SphereGeometry = new SphereGeometry(100);
			var sphere : Mesh = new Mesh(sphereGeometry, material);
			scene.addChild(sphere);

			// create rigidbody and shape
			var sphereShape : AWPSphereShape = new AWPSphereShape(100);
			var body : AWPRigidBody = new AWPRigidBody(sphereShape, sphere, 2);
			body.position = pos;
			body.ccdSweptSphereRadius = 0.5;
			body.ccdMotionThreshold = 1;
			physicsWorld.addRigidBody(body);

			body.applyCentralImpulse(impulse);
		}

		/**
		 * Mouse stage leave listener for navigation
		 */
		private function onStageMouseLeave(event : Event) : void {
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * stage listener for resize events
		 */
		private function onResize(event : Event = null) : void {
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
			SignatureBitmap.y = stage.stageHeight - Signature.height;
		}
	}
}