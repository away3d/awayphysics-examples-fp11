/*

Car physics example in Away3d

Demonstrates:

How to use Away Physics for real car simulation
How to import AWD with linked objects
How to drasticaly reduce mapping size by using vector .swc map and mapper generator

Code by Rob Bateman & LoTh
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
3dflashlo@gmail.com
http://3dflashlo.wordpress.com

Model and map by LoTh
3dflashlo@gmail.com
http://3dflashlo.wordpress.com

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
package
{
    import away3d.utils.Cast;
    import away3d.textures.*;
    import away3d.cameras.lenses.*;
    import away3d.containers.*;
    import away3d.controllers.*;
    import away3d.debug.*;
    import away3d.entities.*;
    import away3d.events.*;
    import away3d.materials.methods.*;
    import away3d.materials.lightpickers.*;
    import away3d.materials.*;
    import away3d.library.assets.*;
    import away3d.lights.*;
    import away3d.lights.shadowmaps.*;
    import away3d.loaders.*;
    import away3d.loaders.parsers.*;
    import away3d.primitives.*;
    
    import awayphysics.dynamics.*;
    import awayphysics.collision.shapes.*;
    import awayphysics.collision.dispatch.*;
    import awayphysics.dynamics.vehicle.*;
    
    import flash.display.*;
    import flash.events.*;
    import flash.filters.*;
    import flash.geom.*;
    import flash.net.*;
    import flash.text.*;
    import flash.ui.*;
    import flash.utils.*;
	
    import utils.*;
    
    [SWF(backgroundColor="#333338", frameRate="60", quality="LOW")]
    public class Advanced_CarPhysicsDemo extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf:Class;
		
		private var assetsRoot:String = "assets/";
		private var textureSprites:Vector.<Sprite> = Vector.<Sprite>([new TextureBodyColor(), new TextureDoorColor(), new TextureWheel(), new TextureInterior(), new TextureCarlights(), new TextureSteering(), new TextureWall(), new TextureRoad()]);
		private var textureMaterials:Vector.<TextureMaterial> = new Vector.<TextureMaterial>();
        
        //global light setting
        private var sunColor:uint = 0xAAAAA9;
		private var sunAmbient:Number = 0.4;
		private var sunDiffuse:Number = 0.5;
		private var sunSpecular:Number = 1;
		private var skyColor:uint = 0x333338;
		private var skyAmbient:Number = 0.2;
		private var skyDiffuse:Number = 0.3;
		private var skySpecular:Number = 0.5;
		private var fogColor:uint = 0x333338;
		private var zenithColor:uint = 0x445465;
		private var fogNear:Number = 1000;
		private var fogFar:Number = 10000;
		
        //engine variables
        private var _view:View3D;
		private var _signature:Sprite;
        private var _stats:AwayStats;
        private var _lightPicker:StaticLightPicker;
        private var _cameraController:HoverController;
		
		//light variables
		private var _sunLight:DirectionalLight;
		private var _skyLight:PointLight;
        
        //materials
        private var _skyMap:BitmapCubeTexture;
        private var _fog:FogMethod;
        private var _specularMethod:FresnelSpecularMethod;
        private var _shadowMethod:NearShadowMapMethod;
        
		//objects
        private var _carContainer:ObjectContainer3D;
		
        //physics
        private var _timeStep:Number = 1.0 / 60;
        private var _car:AWPRaycastVehicle;
        private var _physicsWorld:AWPDynamicsWorld;
		
        //navigation
        private var _prevPanAngle:Number;
		private var _prevTiltAngle:Number;
        private var _prevMouseX:Number;
        private var _prevMouseY:Number;
        private var _mouseMove:Boolean;
		
        //car variables
        private var _startPosition:Vector3D = new Vector3D(0, 100, -180);
		private var _startRotation:Vector3D = new Vector3D(0, -90, 0);
        private var _engineForce:Number = 0;
        private var _breakingForce:Number = 0;
        private var _vehicleSteering:Number = 0;
        private var _keyRight:Boolean = false;
        private var _keyLeft:Boolean = false;
        private var _boost:int = 0;
		
        //car mesh reference
        private var _carShape:Mesh;
        private var _wheelL:Mesh;
		private var _wheelR:ObjectContainer3D;
        private var _steeringWheel:Mesh;
        
        //flash 2d
        private var _text:TextField;
        private var _startText:TextField;
		
        //start counter 
        private var _timer:Timer;
        private var _countdown:int = 3;
        
        /**
         * Constructor
         */
        public function Advanced_CarPhysicsDemo()
		{
            init();
        }
        
        /**
         * Global initialise function
         */
        private function init():void
		{
            initAway3D();
            initAwayPhysics();
            initText();
            initLights();
            initMaterials();
			initObjects();
            initListeners();
			
            load("car.awd");
        }
        
        /**
         * Initialise the 3d engine
         */
        private function initAway3D():void
		{
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
			
			//create the view
            _view = new View3D();
			_view.forceMouseMove = true;
            _view.backgroundColor = skyColor;
            addChild(_view);
            
			//create custom lens
            _view.camera.lens = new PerspectiveLens(70);
            _view.camera.lens.far = 30000;
            _view.camera.lens.near = 1;
            
			//setup controller to be used on the camera
            _cameraController = new HoverController(_view.camera, null, 90, 10, 500, 10, 90);
            _cameraController.minTiltAngle = -60;
            _cameraController.maxTiltAngle = 60;
            _cameraController.autoUpdate = false;
			_cameraController.wrapPanAngle = true;
            
            
            //add signature
			addChild(_signature = new SignatureSwf());
            
            //add stats
            addChild(_stats = new AwayStats(_view, true, true));
			
			//create timer
			_timer = new Timer(1000, 5);
            _timer.addEventListener(TimerEvent.TIMER, onTick);
        }
                
        /**
         * Initialise the physics engine
         */
        private function initAwayPhysics():void
		{
            _physicsWorld = AWPDynamicsWorld.getInstance();
            _physicsWorld.initWithDbvtBroadphase();
            _physicsWorld.gravity = new Vector3D(0, -10, 0);
        }
		
        /**
         * Create an instructions overlay and start text
         */
        private function initText():void
		{
            _text = getTextField(11);
			_text.embedFonts = true;
			_text.antiAliasType = AntiAliasType.ADVANCED;
			_text.gridFitType = GridFitType.PIXEL;
            addChild(_text);
            
            _startText = getTextField(40);
            addChild(_startText);
        }
		
        /**
         * Initialise the lights
         */
        private function initLights():void
		{
            //create a light for shadows that mimics the sun's position in the skybox
            _sunLight = new DirectionalLight();
			_sunLight.y = 1200;
            _sunLight.color = sunColor;
            _sunLight.ambientColor = sunColor;
            _sunLight.ambient = sunAmbient;
            _sunLight.diffuse = sunDiffuse;
            _sunLight.specular = sunSpecular;
            
            _sunLight.castsShadows = true;
            _sunLight.shadowMapper = new NearDirectionalShadowMapper(.1);
            _view.scene.addChild(_sunLight);
			
            //create a light for ambient effect that mimics the sky
            _skyLight = new PointLight();
            _skyLight.color = skyColor;
            _skyLight.ambientColor = skyColor;
            _skyLight.ambient = skyAmbient;
            _skyLight.diffuse = skyDiffuse;
            _skyLight.specular = skySpecular;
            _skyLight.y = 1200;
            _skyLight.radius = 1000;
            _skyLight.fallOff = 2500;
            _view.scene.addChild(_skyLight);
			
			//create light picker for materials
            _lightPicker = new StaticLightPicker([_sunLight, _skyLight]);
			
			//generate cube texture for sky
            _skyMap = BitmapFilterEffects.vectorSky(zenithColor, fogColor, fogColor, 8);
        }
        
        /**
         * Initialise the material from libs/cartextures_c1gt.swc
         */
        private function initMaterials():void
		{
            //global methods
            _fog = new FogMethod(fogNear, fogFar, fogColor);
            _specularMethod = new FresnelSpecularMethod();
            _specularMethod.normalReflectance = 1.8;
            
            _shadowMethod = new NearShadowMapMethod(new FilteredShadowMapMethod(_sunLight));
            _shadowMethod.epsilon = .0007;
			
            //change color of car paint
            var color01:Number = 0xffffff * Math.random();
            var color02:Number = 0xffffff * Math.random();
            color((textureSprites[0] as TextureBodyColor).C, color01);
            color((textureSprites[1] as TextureDoorColor).C, color01);
            color((textureSprites[3] as TextureInterior).C, color02);
            color((textureSprites[5] as TextureSteering).C, color02);
            
            stage.quality = StageQuality.HIGH;
            var material:TextureMaterial;
			
            // 0 - car paint
            material = materialFromSprite("paint", textureSprites[0], true);
            material.gloss = 60;
            material.specular = 1;
			textureMaterials.push(material);
			
            // 1 - glass
            material = materialFromSprite("glass", textureSprites[0], true);
            material.alphaBlending = true;
            material.gloss = 150;
            material.specular = 3;
			textureMaterials.push(material);
			
            // 2 - door
            material = materialFromSprite("door", textureSprites[1], true);
            material.gloss = 60;
            material.specular = 1;
			textureMaterials.push(material);
			
            // 3 - wheel
            material = materialFromSprite("wheel", textureSprites[2], true);
            material.gloss = 25;
            material.specular = 0.3;
            material.addMethod(new RimLightMethod(skyColor, .2, 2, "mix"));
			textureMaterials.push(material);
			
            // 4 - intern
            material = materialFromSprite("intern", textureSprites[3], true);
			textureMaterials.push(material);
			
            // 5 - lights
            material = materialFromSprite("light", textureSprites[4], true);
			textureMaterials.push(material);
			
            // 6 - steering wheel
            material = materialFromSprite("steering", textureSprites[5], true);
            textureMaterials.push(material);
			
            // 7 - wall
            material = materialFromSprite("wall", textureSprites[6], true);
            material.repeat = true;
            material.gloss = 30;
            material.specular = 0.3;
            material.addMethod(_fog);
			textureMaterials.push(material);
			
            // 8 - ground
            material = materialFromSprite("road", textureSprites[7], false);
            material.repeat = true;
            material.gloss = 30;
            material.specular = 0.3;
            material.addMethod(_fog);
			textureMaterials.push(material);
			
            stage.quality = StageQuality.LOW;
        }
        		
        /**
         * Initialise the scene objects
         */
        private function initObjects():void
		{
			//create skybox
            _view.scene.addChild(new SkyBox(_skyMap));
			
			//create car container
			_carContainer = new ObjectContainer3D();
			_carContainer.position = _startPosition;
			_carContainer.rotateTo(_startRotation.x, _startRotation.y, _startRotation.z);
		}
		
        /**
         * Initialise the listeners
         */
        private function initListeners():void
		{
            //add render loop
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
            //add key listeners
            stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			
            //navigation
            stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
            stage.addEventListener(Event.MOUSE_LEAVE, onMouseUp);
			
            //add resize event
            stage.addEventListener(Event.RESIZE, onResize);
            onResize();
        }
                
        /**
         * Car physics
         */
        private function initCarPhysics():void
		{
            // create the chassis body
            var carBody:AWPRigidBody = new AWPRigidBody(new AWPConvexHullShape(_carShape.geometry), _carContainer, 1000);
            carBody.activationState = AWPCollisionObject.DISABLE_DEACTIVATION;
            carBody.angularDamping = 0.1;
            carBody.linearDamping = 0.1;
            carBody.friction = 0.9;
			
            // add to world physics
            _physicsWorld.addRigidBody(carBody);
            
            // setup vehicle tuning
            var tuning:AWPVehicleTuning = new AWPVehicleTuning();
            tuning.frictionSlip = 2;
            tuning.suspensionStiffness = 100;
            tuning.suspensionDamping = 0.85;
            tuning.suspensionCompression = 0.83;
            tuning.maxSuspensionTravelCm = 10;
            tuning.maxSuspensionForce = 10000;
			
            //create a new car physics object
            _physicsWorld.addVehicle(_car = new AWPRaycastVehicle(tuning, carBody));
            
            // wheels setting
            _car.addWheel(_view.scene.addChild(_wheelR.clone() as ObjectContainer3D), new Vector3D(39, 5, 60), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 5, 17, tuning, true);
            _car.addWheel(_view.scene.addChild(_wheelL.clone() as ObjectContainer3D), new Vector3D(-39, 5, 60), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 5, 17, tuning, true);
            _car.addWheel(_view.scene.addChild(_wheelR.clone() as ObjectContainer3D), new Vector3D(39, 5, -60), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 5, 17, tuning, false);
            _car.addWheel(_view.scene.addChild(_wheelL.clone() as ObjectContainer3D), new Vector3D(-39, 5, -60), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 5, 17, tuning, false);
            
            // wheels settings
            for (var i:int = 0; i < _car.getNumWheels(); i++) {
                var wheel:AWPWheelInfo = _car.getWheelInfo(i);
                wheel.wheelsDampingRelaxation = 4.5;
                wheel.wheelsDampingCompression = 4.5;
                wheel.suspensionRestLength1 = 10;
                wheel.rollInfluence = 0.01;
            }
            
			//add car to view
			_view.scene.addChild(_carContainer);
			
            // reset game
            resetGame();
        }
        
        /**
         * Car position rotation
         */
        private function resetGame():void
		{
            var body:AWPRigidBody = _car.getRigidBody();
            body.position = _startPosition;
            body.rotation = _startRotation;
            body.linearVelocity = new Vector3D();
            body.angularVelocity = new Vector3D();
			
            _countdown = 3;
            _timer.reset();
			_timer.start();
        }
		
        /**
         * apply color to object
         */
        private function color(o:DisplayObject, c:int=0, a:Number=1):void
		{
            if (o) {
                var nc:ColorTransform = o.transform.colorTransform;
                nc.color = c;
                nc.alphaMultiplier = a;
                if (c == 0)
                    o.transform.colorTransform = new ColorTransform();
                else
                    o.transform.colorTransform = nc;
            }
        }
		
        /**
         * Material from movieClip
         * ( material name, movieClip, resolution, quality, transparent )
         */
        protected function materialFromSprite(name:String, sprite:Sprite, transparent:Boolean = true):TextureMaterial
		{
            var bmp:BitmapData = new BitmapData(sprite.width, sprite.height, transparent, 0x000000);
            bmp.draw(sprite);
			
            var material:TextureMaterial = new TextureMaterial(Cast.bitmapTexture(bmp));
            material.normalMap = Cast.bitmapTexture(BitmapFilterEffects.normalMap(bmp));
            material.name = name;
            material.lightPicker = _lightPicker;
            material.specularMethod = _specularMethod;
            material.shadowMethod = _shadowMethod;
            
            return material;
        }
        
        /**
         * Global binary file loader
         */
        private function load(url:String):void
		{
            var loader:URLLoader = new URLLoader();
            loader.dataFormat = URLLoaderDataFormat.BINARY;
			
            switch (url.substring(url.length - 3)) {
                case "AWD": 
                case "awd": 
                    loader.addEventListener(Event.COMPLETE, parseAWD, false, 0, true);
                    break;
            }
			
            loader.addEventListener(ProgressEvent.PROGRESS, loadProgress, false, 0, true);
            loader.load(new URLRequest(assetsRoot + url));
        }
        
        /**
         * Display current load
         */
        private function loadProgress(e:ProgressEvent):void
		{
            var P:int = int(e.bytesLoaded / e.bytesTotal * 100);
            if (P != 100) {
                _text.text = "Load : " + P + " % | " + int((e.bytesLoaded / 1024) << 0) + " KB";
			} else {
	            _text.text = "Cursor keys / WSAD / ZSQD - move\n";
	            _text.appendText("SHIFT - boost\n");
				_text.appendText("SPACE - brake\n");
				_text.appendText("R - restart\n");
			}
        }
		
        /**
         * Load AWD
         */
        private function parseAWD(e:Event):void
		{
            var loader:URLLoader = e.target as URLLoader;
            var loader3d:Loader3D = new Loader3D(false);
			
            loader3d.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete, false, 0, true);
            loader3d.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete, false, 0, true);
            loader3d.loadData(loader.data, null, null, new AWD2Parser());
			
            loader.removeEventListener(ProgressEvent.PROGRESS, loadProgress);
            loader.removeEventListener(Event.COMPLETE, parseAWD);
        }
        
        private function getTextField(size:int = 11):TextField
		{
            var t:TextField = new TextField();
            t.defaultTextFormat = new TextFormat("Verdana", size, 0xFFFFFF);
            t.width = 300;
            t.height = 100;
            t.selectable = false;
            t.mouseEnabled = true;
            t.wordWrap = true;
            t.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
			
            return t;
        }
		
        private function onTick(e:TimerEvent):void
		{
			var text:String;
            if (_countdown == 0)
                text = "GO";
            else if (_countdown > 0)
                text = _countdown.toString();
            
			if (text) {
				_startText.visible = true;
				_startText.htmlText = "<p align='center'><b>" + text + "</b></p>";
			} else {
				_startText.visible = false;
				_timer.stop();
			}
			
            _countdown--;
        }
        
        /**
         * Render loop
         */
        private function onEnterFrame(e:Event):void
		{
            //update physics engine
            if (_physicsWorld)
                _physicsWorld.step(_timeStep);
			
            if (_car) {
	            if (_keyLeft) {
	                _vehicleSteering -= 0.05;
	                if (_vehicleSteering < -Math.PI / 6)
	                    _vehicleSteering = -Math.PI / 6;
	            }
				
	            if (_keyRight) {
	                _vehicleSteering += 0.05;
	                if (_vehicleSteering > Math.PI / 6)
	                    _vehicleSteering = Math.PI / 6;
	            }
				
                // apply the force to the car
                _car.applyEngineForce(_engineForce, 0);
                _car.setBrake(_breakingForce, 0);
                _car.applyEngineForce(_engineForce, 1);
                _car.setBrake(_breakingForce, 1);
                _car.applyEngineForce(_engineForce, 2);
                _car.setBrake(_breakingForce, 2);
                _car.applyEngineForce(_engineForce, 3);
                _car.setBrake(_breakingForce, 3);
                
                _car.setSteeringValue(_vehicleSteering, 0);
                _car.setSteeringValue(_vehicleSteering, 1);
                _vehicleSteering *= 0.9;
				
            }
            //update camera controller
            _cameraController.lookAtPosition = _carContainer.position;
			
			if (_mouseMove) {
                _cameraController.panAngle = 0.3*(stage.mouseX - _prevMouseX) + _prevPanAngle;
				_cameraController.tiltAngle = 0.3*(stage.mouseY - _prevMouseY) + _prevTiltAngle;
            } else {
				_cameraController.panAngle = 270-Math.atan2(_carContainer.forwardVector.z, _carContainer.forwardVector.x)*180/Math.PI;
			}
            
            _cameraController.update();
			
            //update light
            _skyLight.position = _view.camera.position;
            
            //update 3d engine
            _view.render();
			
			//reset if car fallen off
			if (_carContainer.y < -1000)
				resetGame();
        }
		
        /**
         * Listener for asset complete
         */
        private function onAssetComplete(event:AssetEvent):void
		{
            if (event.asset.assetType == AssetType.MESH) {
                var mesh:Mesh = event.asset as Mesh;
                switch (mesh.name) {
                    case "body":
                        //the main car body
                        mesh.material = textureMaterials[0];
                        mesh.castsShadows = true;
                        _carContainer.addChild(mesh);
						break;
                    case "wheel":
                        // the wheel used to create our 4 dynamic wheels
                        mesh.material = textureMaterials[3];
                        _wheelL = mesh.clone() as Mesh;
						_wheelR = new ObjectContainer3D();
						_wheelL.rotationY = -180;
						_wheelR.addChild(_wheelL);
						_wheelL = mesh;
						break;
                    case "headLight":
                        mesh.material = textureMaterials[5];
						break;
                    case "hood":
                    case "bottomCar":
                        mesh.material = textureMaterials[0];
						break;
                    case "trunk":
					case "glass":
					case "doorGlassLeft":
					case "doorGlassRight":
                        mesh.castsShadows = false;
                        mesh.material = textureMaterials[1];
						break;
                    case "interior":
                        mesh.material = textureMaterials[4];
						break;
                    case "doorRght":
					case "dooLeft":
                        mesh.material = textureMaterials[2];
						break;
                    case "steeringWheel":
                        _steeringWheel = mesh;
                        mesh.material = textureMaterials[6];
						
						//create container for steering wheel
			            var axe:ObjectContainer3D = new ObjectContainer3D();
			            axe.rotationX = 25 + 180;
			            axe.position = new Vector3D(-20, 30, 30);
			            axe.addChild(_steeringWheel);
			            _carContainer.addChild(axe);
						break;
                    case "MotorAndBorder":
                        mesh.visible = false;
						break;
                    case "Track":
						//add mesh to view
                        mesh.castsShadows = false;
                        mesh.material = textureMaterials[8];
                        _view.scene.addChild(mesh);
						
                        // create triangle mesh shape for Track ground
                        _physicsWorld.addRigidBody(new AWPRigidBody(new AWPBvhTriangleMeshShape(mesh.geometry), mesh));
						break;
                    case "Wall":
						//add mesh to view
                        mesh.castsShadows = false;
                        mesh.material = textureMaterials[7];
                        _view.scene.addChild(mesh);
						
                        // create triangle mesh shape for wall
                        _physicsWorld.addRigidBody(new AWPRigidBody(new AWPBvhTriangleMeshShape(mesh.geometry), mesh));
						break;
                    case "Deco":
                        mesh.castsShadows = false;
                        mesh.material = textureMaterials[7];
                        mesh.geometry.scaleUV(50, 50);
                        _view.scene.addChild(mesh);
                        break;
                    case "carShape":
                        //! invisible : physics car collision shape 
                        mesh.castsShadows = false;
                        _carShape = mesh;
                    case "extraCollision":
						// create triangle mesh shape for extra
                        _physicsWorld.addRigidBody(new AWPRigidBody(new AWPBvhTriangleMeshShape(mesh.geometry), mesh));
						break;
					default:
                }
            }
        }
        
        /**
         * Listener for resource complete
         */
        private function onResourceComplete(e:LoaderEvent):void
		{
            initCarPhysics();
			
            var loader3d:Loader3D = e.target as Loader3D;
            loader3d.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
            loader3d.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
        }
        
        /**
         * Key down listener
         */
        private function onKeyDown(event:KeyboardEvent):void
		{
            switch (event.keyCode) {
                case Keyboard.SHIFT: 
                    _boost = 5000;
                    break;
                case Keyboard.UP: 
                case Keyboard.W: 
                case Keyboard.Z: //fr
                    _engineForce = 2500 + _boost;
                    break;
                case Keyboard.DOWN: 
                case Keyboard.S: 
                    _engineForce = -2500;
                    break;
                case Keyboard.LEFT: 
                case Keyboard.A: 
                case Keyboard.Q: //fr
                    _keyLeft = true;
                    break;
                case Keyboard.RIGHT: 
                case Keyboard.D: 
                    _keyRight = true;
                    break;
                case Keyboard.SPACE: 
                    _breakingForce = 80;
                    break;
                case Keyboard.R: 
                    resetGame();
                    break;
            }
        }
        
        /**
         * Key up listener
         */
        private function onKeyUp(event:KeyboardEvent):void
		{
            switch (event.keyCode) {
                case Keyboard.SHIFT: 
                    _boost = 0;
                    break;
                case Keyboard.UP: 
                case Keyboard.W: 
                case Keyboard.Z: //fr
                    _engineForce = 0;
                    break;
                case Keyboard.DOWN: 
                case Keyboard.S: 
                    _engineForce = 0;
                    break;
                case Keyboard.LEFT: 
                case Keyboard.A: 
                case Keyboard.Q: //fr
                    _keyLeft = false;
                    break;
                case Keyboard.RIGHT: 
                case Keyboard.D: 
                    _keyRight = false;
                    break;
                case Keyboard.SPACE: 
                    _breakingForce = 0;
                    break;
            }
        }
		
        /**
         * stage listener and mouse control
         */
        private function onResize(event:Event=null):void
		{
			var w:uint = stage.stageWidth;
			var h:uint = stage.stageHeight;
			
            _view.width = w;
            _view.height = h;
            _stats.x = w - _stats.width;
            _signature.y = h - _signature.height;
			_startText.y = (h / 3) - 50;
            _startText.width = w;
        }
        
		/**
		 * Mouse down listener for navigation
		 */
        private function onMouseDown(ev:MouseEvent):void
		{
			_prevPanAngle = _cameraController.panAngle;
			_prevTiltAngle = _cameraController.tiltAngle;
            _prevMouseX = ev.stageX;
            _prevMouseY = ev.stageY;
            _mouseMove = true;
        }

		/**
		 * Mouse up listener for navigation
		 */
        private function onMouseUp(event:Event):void
		{
            _mouseMove = false;
		}
        
        /**
         * mouseWheel listener
         */
        private function onMouseWheel(ev:MouseEvent):void
		{
            _cameraController.distance -= ev.delta * 5;
			
            if (_cameraController.distance < 100)
                _cameraController.distance = 100;
            else if (_cameraController.distance > 2000)
                _cameraController.distance = 2000;
        }
    }
}