package {
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;

	public class Main extends Sprite {
		/**
		 * Away Physics demos
		 * @authors 	Ringo Blanken - http://www.ringo.nl/en/
		 * 				Muzer - http://blog.muzerly.com/
		 */
		// Setting, change _selectedDemo to 0 till 8
		// 0 = Basictest, 1 = BasicStressTest, 2=Gravity, 3=compoundshape,4= collisionfilter
		// 5= constraint, 6= vehicle terrain, 7= character walk demo, 8 = bvhTriangleMeshCar
		private var _selectedDemo : int = 7;
		// private var _totalDemos		: int = 8;
		private var _currentDemo : Sprite;

		public function Main() {
			this.addEventListener(Event.ENTER_FRAME, tempLoop);
		}

		private function init() : void {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.quality = StageQuality.HIGH;
			stage.frameRate = 60;
			// stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			startCurrentDemo();
		}

		private function startCurrentDemo() : void {
			switch (_selectedDemo) {
				case 0:
					var basicTest : BasicTest = new BasicTest();
					this.addChild(basicTest);
					_currentDemo = basicTest;
					break;
				case 1:
					var basicStressTest : BasicStressTest = new BasicStressTest();
					this.addChild(basicStressTest);
					_currentDemo = basicStressTest;
					break;
				case 2:
					var gravity : GravityTest = new GravityTest();
					this.addChild(gravity);
					_currentDemo = gravity;
					break;
				case 3:
					var compoundShapeTest : CompoundShapeTest = new CompoundShapeTest();
					this.addChild(compoundShapeTest);
					_currentDemo = compoundShapeTest;
					break;
				case 4:
					var collisionFilterTest : CollisionFilterTest = new CollisionFilterTest();
					this.addChild(collisionFilterTest);
					_currentDemo = collisionFilterTest;
					break;
				case 5:
					var constraintTest : ConstraintTest = new ConstraintTest();
					this.addChild(constraintTest);
					_currentDemo = constraintTest;
					break;
				case 6:
					var vehicleTerrainTest : VehicleTerrainTest = new VehicleTerrainTest();
					this.addChild(vehicleTerrainTest);
					_currentDemo = vehicleTerrainTest;
					break;
				case 7:
					var characterDemo : CharacterDemo = new CharacterDemo();
					this.addChild(characterDemo);
					_currentDemo = characterDemo;
					break;
				case 8:
					var bvhTriangleMeshCarTest : BvhTriangleMeshCarTest = new BvhTriangleMeshCarTest();
					this.addChild(bvhTriangleMeshCarTest);
					_currentDemo = bvhTriangleMeshCarTest;
					break;
			}
		}

		// Make sure the stage is ready
		private function tempLoop(event : Event) : void {
			if ( stage.stageWidth > 0 && stage.stageHeight > 0 ) {
				this.removeEventListener(Event.ENTER_FRAME, tempLoop);
				init();
			}
		}
		/*
		private function keyDownHandler(event : KeyboardEvent) : void {
		switch(event.keyCode) {
		case Keyboard.PAGE_UP:
		if (_selectedDemo == _totalDemos) {
		_selectedDemo = 0;
		}
		else {
		_selectedDemo += 1;	
		}
		_currentDemo.removeChildren();
		startCurrentDemo();
		break;
					
		case Keyboard.PAGE_DOWN:
		if (_selectedDemo > 0) {
		_selectedDemo -= 1;
		}
		else {
		_selectedDemo = _totalDemos;
		}
		this.removeChild(_currentDemo);
		_currentDemo.removeChildren();
		startCurrentDemo();
		break;
		}
		}
		 */
	}
}