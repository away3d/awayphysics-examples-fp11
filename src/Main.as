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
		 
		 * Tech demo's, 11 in total		
		 * 0 =  Basictest
		 * 1 =  BasicStressTest
		 * 2 =  Gravity
		 * 3 =  Compoundshape
		 * 4 =  Collisionfilter
		 * 5 =  Constraint
		 * 6 =  Vehicle terrain
		 * 7 =  Character walk demo
		 * 8 =  BVHTriangleMeshCar
		 * 9 =  Convexhull
		 * 10 = CollionEventTest
		 */
		// CHANGE NUMBER HERE for different demo's, 0 till 10
		private var _selectedDemo : int = 10;
		private var _currentDemo : Sprite;

		public function Main() {
			this.addEventListener(Event.ENTER_FRAME, tempLoop);
		}

		private function init() : void {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.quality = StageQuality.HIGH;
			stage.frameRate = 60;
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
				case 9:
					var convexHullShapeTest : ConvexHullShapeTest = new ConvexHullShapeTest();
					this.addChild(convexHullShapeTest);
					_currentDemo = convexHullShapeTest;
					break;
				case 10:
					var collisionEventTest : CollisionEventTest = new CollisionEventTest();
					this.addChild(collisionEventTest);
					_currentDemo = collisionEventTest;
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
	}
}