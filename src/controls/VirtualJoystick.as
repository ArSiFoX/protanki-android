package controls {
  import flash.display.Sprite;
  import flash.display.Stage;
  import flash.events.Event;
  import flash.geom.Point;
  import flash.ui.Keyboard;

  public class VirtualJoystick extends Sprite {

    private var stageRef:Stage;
    private var baseRadius:Number;
    private var knobRadius:Number;
    private var deadZone:Number;
    private var maxDistance:Number;

    private var base:Sprite;
    private var knob:Sprite;
    private var activeTouchId:int = -1;

    private var currentW:Boolean = false;
    private var currentA:Boolean = false;
    private var currentS:Boolean = false;
    private var currentD:Boolean = false;

    private var joystickSens:Number = 1.0;
    private var currentSteerRate:Number = 0.0;
    private var currentSteerDir:String = "";
    private var pwmAccumulator:Number = 0.0;
    private var wantW:Boolean = false;
    private var wantS:Boolean = false;

    public function VirtualJoystick(stage:Stage, radius:Number = 0) {
      super();
      this.stageRef = stage;
      this.baseRadius = radius > 0 ? radius : DPI.scale(55);
      this.knobRadius = this.baseRadius * 0.42;
      this.deadZone = this.baseRadius * 0.22;
      this.maxDistance = this.baseRadius - this.knobRadius * 0.25;

      createUI();
      buttonMode = true;
      mouseChildren = false;
      addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
    }

    private function onRemovedFromStage(e:Event):void {
      reset();
    }

    private function createUI():void {
      base = new Sprite();
      drawBase();
      addChild(base);

      knob = new Sprite();
      drawKnob(false);
      addChild(knob);
    }

    private var isSelected:Boolean = false;

    private function drawBase():void {
      base.graphics.clear();

      // Outer background
      base.graphics.beginFill(0x1a1a1a, 0.5);
      if (isSelected) {
        base.graphics.lineStyle(DPI.scale(3.5), 0xFFD700, 1.0);
      } else {
        base.graphics.lineStyle(DPI.scale(2.5), 0xFFFFFF, 0.7);
      }
      base.graphics.drawCircle(0, 0, baseRadius);
      base.graphics.endFill();

      // Inner deadzone ring
      base.graphics.lineStyle(DPI.scale(1), 0xFFFFFF, 0.2);
      base.graphics.drawCircle(0, 0, deadZone);

      // Directional tick marks
      var tickLen:Number = DPI.scale(6);
      base.graphics.lineStyle(DPI.scale(2), 0xFFFFFF, 0.45);

      // Up
      base.graphics.moveTo(0, -baseRadius + DPI.scale(3));
      base.graphics.lineTo(0, -baseRadius + DPI.scale(3) + tickLen);

      // Down
      base.graphics.moveTo(0, baseRadius - DPI.scale(3));
      base.graphics.lineTo(0, baseRadius - DPI.scale(3) - tickLen);

      // Left
      base.graphics.moveTo(-baseRadius + DPI.scale(3), 0);
      base.graphics.lineTo(-baseRadius + DPI.scale(3) + tickLen, 0);

      // Right
      base.graphics.moveTo(baseRadius - DPI.scale(3), 0);
      base.graphics.lineTo(baseRadius - DPI.scale(3) - tickLen, 0);
    }

    private function drawKnob(pressed:Boolean):void {
      knob.graphics.clear();
      var fillColor:uint = pressed ? 0x4a4a4a : 0x2e2e2e;
      var fillAlpha:Number = pressed ? 0.9 : 0.75;
      var strokeAlpha:Number = pressed ? 1.0 : 0.85;

      knob.graphics.beginFill(fillColor, fillAlpha);
      knob.graphics.lineStyle(DPI.scale(2), 0xFFFFFF, strokeAlpha);
      knob.graphics.drawCircle(0, 0, knobRadius);
      knob.graphics.endFill();

      // Center accent dot
      knob.graphics.beginFill(0xFFFFFF, pressed ? 0.9 : 0.6);
      knob.graphics.drawCircle(0, 0, DPI.scale(3.5));
      knob.graphics.endFill();
    }

    public function onTouchBegin(touchId:int, stageX:Number, stageY:Number):Boolean {
      var localPt:Point = globalToLocal(new Point(stageX, stageY));
      var dist:Number = Math.sqrt(localPt.x * localPt.x + localPt.y * localPt.y);
      if (dist <= baseRadius * 1.3) {
        activeTouchId = touchId;
        drawKnob(true);
        pwmAccumulator = 0.0;
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
        updateMovement(localPt.x, localPt.y);
        return true;
      }
      return false;
    }

    public function onTouchMove(touchId:int, stageX:Number, stageY:Number):void {
      if (touchId != activeTouchId) {
        return;
      }
      var localPt:Point = globalToLocal(new Point(stageX, stageY));
      updateMovement(localPt.x, localPt.y);
    }

    public function onTouchEnd(touchId:int):void {
      if (touchId == activeTouchId) {
        reset();
      }
    }

    public function reset():void {
      activeTouchId = -1;
      knob.x = 0;
      knob.y = 0;
      drawKnob(false);
      removeEventListener(Event.ENTER_FRAME, onEnterFrame);

      wantW = false;
      wantS = false;
      currentSteerRate = 0.0;
      currentSteerDir = "";
      pwmAccumulator = 0.0;

      var s:Stage = stageRef != null ? stageRef : this.stage;
      if (s != null) {
        if (currentW) {
          currentW = false;
          KeyUtil.simulateKeyPress(s, false, Keyboard.W);
        }
        if (currentS) {
          currentS = false;
          KeyUtil.simulateKeyPress(s, false, Keyboard.S);
        }
        if (currentA) {
          currentA = false;
          KeyUtil.simulateKeyPress(s, false, Keyboard.A);
        }
        if (currentD) {
          currentD = false;
          KeyUtil.simulateKeyPress(s, false, Keyboard.D);
        }
      }
    }

    private function updateMovement(localX:Number, localY:Number):void {
      var dist:Number = Math.sqrt(localX * localX + localY * localY);
      if (dist > maxDistance) {
        localX = (localX / dist) * maxDistance;
        localY = (localY / dist) * maxDistance;
        dist = maxDistance;
      }
      knob.x = localX;
      knob.y = localY;

      wantW = false;
      wantS = false;
      currentSteerRate = 0.0;
      currentSteerDir = "";

      if (dist >= deadZone) {
        var angleDeg:Number = Math.atan2(localY, localX) * 180 / Math.PI;

        // Drive forward W: angle in [-165, -15]
        if (angleDeg >= -165 && angleDeg <= -15) {
          wantW = true;
        }
        // Drive reverse S: angle in [15, 165]
        if (angleDeg >= 15 && angleDeg <= 165) {
          wantS = true;
        }

        // Steering: pure forward is -90 deg, pure reverse is +90 deg.
        // Deadzone cone: 18 degrees around vertical forward/backward
        var absAngle:Number = Math.abs(angleDeg);
        var devFromVertical:Number = Math.abs(absAngle - 90); // 0 at pure vertical, 90 at pure horizontal

        var deadzoneCone:Number = 18.0;
        if (devFromVertical > deadzoneCone) {
          var angleFactor:Number = (devFromVertical - deadzoneCone) / (90.0 - deadzoneCone);
          var distFactor:Number = (dist - deadZone) / (maxDistance - deadZone);
          distFactor = Math.max(0.0, Math.min(1.0, distFactor));

          var rawSteer:Number = angleFactor * distFactor;
          currentSteerRate = Math.max(0.0, Math.min(1.0, rawSteer * joystickSens));

          if (localX > 0) {
            currentSteerDir = "D";
          } else if (localX < 0) {
            currentSteerDir = "A";
          }
        }
      }

      syncDriveKeys();
    }

    private function syncDriveKeys():void {
      var s:Stage = stageRef != null ? stageRef : this.stage;
      if (s == null) {
        return;
      }
      if (wantW != currentW) {
        currentW = wantW;
        KeyUtil.simulateKeyPress(s, currentW, Keyboard.W);
      }
      if (wantS != currentS) {
        currentS = wantS;
        KeyUtil.simulateKeyPress(s, currentS, Keyboard.S);
      }
    }

    private function onEnterFrame(event:Event):void {
      if (activeTouchId == -1) {
        removeEventListener(Event.ENTER_FRAME, onEnterFrame);
        return;
      }
      var s:Stage = stageRef != null ? stageRef : this.stage;
      if (s == null) {
        return;
      }

      var steerKeyDown:Boolean = false;
      if (currentSteerRate >= 0.90) {
        steerKeyDown = true;
      } else if (currentSteerRate <= 0.05) {
        steerKeyDown = false;
      } else {
        pwmAccumulator += currentSteerRate;
        if (pwmAccumulator >= 1.0) {
          pwmAccumulator -= 1.0;
          steerKeyDown = true;
        } else {
          steerKeyDown = false;
        }
      }

      var wantA:Boolean = (currentSteerDir == "A") && steerKeyDown;
      var wantD:Boolean = (currentSteerDir == "D") && steerKeyDown;

      if (wantA != currentA) {
        currentA = wantA;
        KeyUtil.simulateKeyPress(s, currentA, Keyboard.A);
      }
      if (wantD != currentD) {
        currentD = wantD;
        KeyUtil.simulateKeyPress(s, currentD, Keyboard.D);
      }
    }

    public function setJoystickSens(sens:Number):void {
      this.joystickSens = Math.max(0.2, Math.min(2.5, sens));
    }

    public function getJoystickSens():Number {
      return this.joystickSens;
    }

    public function getActiveTouchId():int {
      return activeTouchId;
    }

    public function getBaseRadius():Number {
      return baseRadius;
    }

    public function setSelected(selected:Boolean):void {
      if (isSelected != selected) {
        isSelected = selected;
        drawBase();
      }
    }

    public function getSelected():Boolean {
      return isSelected;
    }

    public function setBaseAlpha(a:Number):void {
      alpha = a;
    }

  }
}
