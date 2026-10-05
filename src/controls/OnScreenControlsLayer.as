package controls {
  import flash.display.DisplayObjectContainer;
  import flash.display.Screen;
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.MouseEvent;
  import flash.events.TouchEvent;
  import flash.geom.Point;
  import flash.net.SharedObject;
  import flash.ui.Keyboard;
  import flash.ui.Multitouch;
  import flash.ui.MultitouchInputMode;
  import flash.utils.Dictionary;
  import flash.utils.getTimer;

  public class OnScreenControlsLayer extends Sprite {

    private var settingsButton:SettingsButton;
    private var settingsMenu:SettingsMenu;

    private var joystick:VirtualJoystick;
    private var movementGroup:Sprite;

    private var allButtons:Vector.<ControlButton> = new Vector.<ControlButton>();
    private var customButtons:Vector.<ControlButton> = new Vector.<ControlButton>();
    private var activeControls:Dictionary = new Dictionary();
    private var touchStates:Dictionary = new Dictionary();

    private var defaultPositions:Object;
    private const buttonSizes:Vector.<Number> = Vector.<Number>([DPI.scale(40), DPI.scale(50), DPI.scale(70)]);

    private var controlsEnabled:Boolean = true;
    private var isJoystickEnabled:Boolean = true;
    private var isDpadEnabled:Boolean = false;
    private var isTouchCameraEnabled:Boolean = true;
    private var isTurretButtonsEnabled:Boolean = true;
    private var isQEButtonsEnabled:Boolean = false;
    private var isFire2Enabled:Boolean = true;
    private var isAimWhileShootingEnabled:Boolean = true;
    private var isCombineSuppliesEnabled:Boolean = false;
    private var isVerticalCameraDisabled:Boolean = false;

    private var combinedSuppliesBtn:ControlButton;

    private var buttonScale:Number = 1.0;
    private var joystickScale:Number = 1.0;
    private var buttonsAlpha:Number = 1.0;
    private var cameraSensH:Number = 1.0;
    private var cameraSensV:Number = 1.0;
    private var joystickSens:Number = 1.0;

    private var selectedElement:Sprite = null;
    private var buttonScales:Object = {};

    // Touch camera control variables
    private var cameraTouchId:int = -1;
    private var cameraLastX:Number = 0;
    private var cameraLastY:Number = 0;
    private var simulatedMouseX:Number = 0;
    private var simulatedMouseY:Number = 0;
    private var lastCameraMoveTime:int = 0;

    // Aim while shooting variables
    private var fireAimTouchId:int = -1;
    private var fireAimButton:ControlButton = null;
    private var fireAimLastX:Number = 0;
    private var fireAimLastY:Number = 0;

    private var cameraBudgetX:Number = 0;
    private var cameraBudgetY:Number = 0;

    private var cameraKeyZPressed:Boolean = false;
    private var cameraKeyXPressed:Boolean = false;
    private var cameraKeyPageUpPressed:Boolean = false;
    private var cameraKeyPageDownPressed:Boolean = false;
    private var cameraKeyQPressed:Boolean = false;
    private var cameraKeyEPressed:Boolean = false;

    public function OnScreenControlsLayer() {
      super();
      Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
      addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }

    private function onAddedToStage(event:Event):void {
      removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
      defaultPositions = getDefaultPositions();
      createControls();
      createSettings();
      loadPositions();
    }

    private function createSettings():void {
      settingsButton = new SettingsButton(this);
      settingsButton.x = Math.max(Screen.mainScreen.safeArea.x, DPI.scale(10));
      settingsButton.y = DPI.scale(10);
      addChild(settingsButton);

      settingsMenu = new SettingsMenu(settingsButton, this);
      settingsMenu.x = settingsButton.x;
      settingsMenu.y = settingsButton.y + settingsButton.height + DPI.scale(4);
      settingsMenu.visible = false;
      addChild(settingsMenu);
    }

    public function toggleSettings():void {
      settingsMenu.visible = !settingsMenu.visible;
      if (settingsMenu.visible) {
        if (joystick != null) joystick.reset();
        releaseAllButtons();
        releaseCameraKeys();
        cameraTouchId = -1;
        if (fireAimTouchId != -1) {
          if (fireAimButton != null) {
            setButtonState(fireAimButton, false);
            fireAimButton = null;
          }
          fireAimTouchId = -1;
        }
      } else {
        selectElement(null);
      }
    }

    public function isSettingsOpen():Boolean {
      return settingsMenu != null && settingsMenu.visible;
    }

    private function getDefaultPositions():Object {
      var sw:Number = stage.stageWidth;
      var sh:Number = stage.stageHeight;

      // Virtual Joystick (Left)
      var joyX:Number = sw * 0.16;
      var joyY:Number = sh * 0.72;

      // WASD D-Pad (Left side)
      var leftX:Number = sw * 0.16;
      var baseY:Number = sh * 0.70;
      var diffSize:Number = buttonSizes[1] - buttonSizes[0];

      // Consumables 1 to 5 (Bottom Center)
      var consSize:Number = buttonSizes[0];
      var consGap:Number = DPI.scale(8);
      var totalConsW:Number = 5 * consSize + 4 * consGap;
      var consStartX:Number = sw * 0.50 - totalConsW / 2;
      var consY:Number = sh - consSize - DPI.scale(12);

      // Space (Shoot) (Right side)
      var spaceW:Number = DPI.scale(85);
      var spaceH:Number = buttonSizes[2];
      var spaceX:Number = sw * 0.86 - spaceW / 2;
      var spaceY:Number = sh * 0.68 - spaceH / 2;

      // Turret rotation Z, X and Centering C (Left of Space)
      var zSize:Number = buttonSizes[1];
      var zX:Number = sw * 0.65;
      var zY:Number = sh * 0.72;
      var xX:Number = zX + zSize + DPI.scale(10);
      var xY:Number = zY;
      var cX:Number = zX + (zSize + DPI.scale(10)) / 2;
      var cY:Number = zY - buttonSizes[0] - DPI.scale(10);

      // Vertical camera Q (Down) and E (Up) (Above Z and X)
      var qX:Number = zX;
      var qY:Number = zY - zSize - DPI.scale(12);
      var eX:Number = xX;
      var eY:Number = qY;

      // F (Drop Flag) (Above Space)
      var fSize:Number = buttonSizes[0];
      var fX:Number = spaceX + (spaceW - fSize) / 2;
      var fY:Number = spaceY - fSize - DPI.scale(16);

      // ENTER (Chat) (Top Right)
      var enterW:Number = DPI.scale(60);
      var enterH:Number = buttonSizes[0];
      var enterX:Number = sw - enterW - DPI.scale(15);
      var enterY:Number = DPI.scale(15);

      // TAB (Battle statistics / scoreboard) (Left of ENTER)
      var tabW:Number = DPI.scale(55);
      var tabH:Number = buttonSizes[0];
      var tabX:Number = enterX - tabW - DPI.scale(10);
      var tabY:Number = enterY;

      // Secondary Fire button (above joystick)
      var fire2Size:Number = buttonSizes[1];
      var fire2X:Number = joyX - fire2Size / 2;
      var fire2Y:Number = joyY - DPI.scale(55) - fire2Size - DPI.scale(10);

      // Combined 2+3+4 supplies button (placed where supply 3 was)
      var comb3X:Number = consStartX + 2 * (consSize + consGap) - DPI.scale(7.5);

      return {
        JOYSTICK: new Point(joyX, joyY),
        FIRE2: new Point(fire2X, fire2Y),

        '1': new Point(consStartX + 0 * (consSize + consGap), consY),
        '2': new Point(consStartX + 1 * (consSize + consGap), consY),
        '3': new Point(consStartX + 2 * (consSize + consGap), consY),
        '4': new Point(consStartX + 3 * (consSize + consGap), consY),
        '5': new Point(consStartX + 4 * (consSize + consGap), consY),
        COMBINED_234: new Point(comb3X, consY),

        F: new Point(fX, fY),
        SPACE: new Point(spaceX, spaceY),
        ENTER: new Point(enterX, enterY),
        TAB: new Point(tabX, tabY),

        Z: new Point(zX, zY),
        X: new Point(xX, xY),
        C: new Point(cX, cY),
        Q: new Point(qX, qY),
        E: new Point(eX, eY),

        W: new Point(leftX, baseY - buttonSizes[1]),
        A: new Point(leftX - buttonSizes[1], baseY),
        S: new Point(leftX, baseY + buttonSizes[1]),
        D: new Point(leftX + buttonSizes[1], baseY),
        WA: new Point(leftX - buttonSizes[1] + diffSize, baseY - buttonSizes[1] + diffSize),
        WD: new Point(leftX + buttonSizes[1], baseY - buttonSizes[1] + diffSize),
        SA: new Point(leftX - buttonSizes[1] + diffSize, baseY + buttonSizes[1]),
        SD: new Point(leftX + buttonSizes[1], baseY + buttonSizes[1])
      };
    }

    private function addStageListeners():void {
      stage.addEventListener(TouchEvent.TOUCH_BEGIN, onStageTouchBegin);
      stage.addEventListener(TouchEvent.TOUCH_MOVE, onStageTouchMove);
      stage.addEventListener(TouchEvent.TOUCH_END, onStageTouchEnd);
      stage.addEventListener(Event.DEACTIVATE, onDeactivate);
      addEventListener(Event.ENTER_FRAME, onEnterFrame);

      if (!Multitouch.supportsTouchEvents) {
        stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
        stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
      }
    }

    private function removeStageListeners():void {
      stage.removeEventListener(TouchEvent.TOUCH_BEGIN, onStageTouchBegin);
      stage.removeEventListener(TouchEvent.TOUCH_MOVE, onStageTouchMove);
      stage.removeEventListener(TouchEvent.TOUCH_END, onStageTouchEnd);
      stage.removeEventListener(Event.DEACTIVATE, onDeactivate);
      removeEventListener(Event.ENTER_FRAME, onEnterFrame);

      if (!Multitouch.supportsTouchEvents) {
        stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
        stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
        stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
      }
      releaseCameraKeys();
    }

    private function onDeactivate(event:Event):void {
      if (joystick != null) {
        joystick.reset();
      }
      releaseAllButtons();
      releaseCameraKeys();
      cameraTouchId = -1;
      if (fireAimTouchId != -1) {
        if (fireAimButton != null) {
          setButtonState(fireAimButton, false);
          fireAimButton = null;
        }
        fireAimTouchId = -1;
      }
    }

    private function onEnterFrame(event:Event):void {
      if (stage == null) return;

      // Drain horizontal budget (X / Z)
      var drainRateX:Number = 1.0;
      if (cameraBudgetX > 0.4) {
        if (!cameraKeyXPressed) {
          KeyUtil.simulateKeyPress(stage, true, Keyboard.X);
          cameraKeyXPressed = true;
        }
        if (cameraKeyZPressed) {
          KeyUtil.simulateKeyPress(stage, false, Keyboard.Z);
          cameraKeyZPressed = false;
        }
        var drainX:Number = Math.min(cameraBudgetX, drainRateX);
        cameraBudgetX -= drainX;
      } else if (cameraBudgetX < -0.4) {
        if (!cameraKeyZPressed) {
          KeyUtil.simulateKeyPress(stage, true, Keyboard.Z);
          cameraKeyZPressed = true;
        }
        if (cameraKeyXPressed) {
          KeyUtil.simulateKeyPress(stage, false, Keyboard.X);
          cameraKeyXPressed = false;
        }
        var drainNegX:Number = Math.min(-cameraBudgetX, drainRateX);
        cameraBudgetX += drainNegX;
      } else {
        if (cameraKeyXPressed) {
          KeyUtil.simulateKeyPress(stage, false, Keyboard.X);
          cameraKeyXPressed = false;
        }
        if (cameraKeyZPressed) {
          KeyUtil.simulateKeyPress(stage, false, Keyboard.Z);
          cameraKeyZPressed = false;
        }
        cameraBudgetX = 0;
      }

      // Drain vertical budget (PageDown/Q, PageUp/E)
      if (!isVerticalCameraDisabled) {
        var drainRateY:Number = 1.0;
        if (cameraBudgetY > 0.4) {
          if (!cameraKeyPageDownPressed) {
            KeyUtil.simulateKeyPress(stage, true, Keyboard.PAGE_DOWN);
            KeyUtil.simulateKeyPress(stage, true, Keyboard.Q);
            cameraKeyPageDownPressed = true;
          }
          if (cameraKeyPageUpPressed) {
            KeyUtil.simulateKeyPress(stage, false, Keyboard.PAGE_UP);
            KeyUtil.simulateKeyPress(stage, false, Keyboard.E);
            cameraKeyPageUpPressed = false;
          }
          var drainY:Number = Math.min(cameraBudgetY, drainRateY);
          cameraBudgetY -= drainY;
        } else if (cameraBudgetY < -0.4) {
          if (!cameraKeyPageUpPressed) {
            KeyUtil.simulateKeyPress(stage, true, Keyboard.PAGE_UP);
            KeyUtil.simulateKeyPress(stage, true, Keyboard.E);
            cameraKeyPageUpPressed = true;
          }
          if (cameraKeyPageDownPressed) {
            KeyUtil.simulateKeyPress(stage, false, Keyboard.PAGE_DOWN);
            KeyUtil.simulateKeyPress(stage, false, Keyboard.Q);
            cameraKeyPageDownPressed = false;
          }
          var drainNegY:Number = Math.min(-cameraBudgetY, drainRateY);
          cameraBudgetY += drainNegY;
        } else {
          if (cameraKeyPageDownPressed) {
            KeyUtil.simulateKeyPress(stage, false, Keyboard.PAGE_DOWN);
            KeyUtil.simulateKeyPress(stage, false, Keyboard.Q);
            cameraKeyPageDownPressed = false;
          }
          if (cameraKeyPageUpPressed) {
            KeyUtil.simulateKeyPress(stage, false, Keyboard.PAGE_UP);
            KeyUtil.simulateKeyPress(stage, false, Keyboard.E);
            cameraKeyPageUpPressed = false;
          }
          cameraBudgetY = 0;
        }
      }

      // If finger stopped moving while touching (holding finger still to stop/aim), clear budget
      if ((cameraTouchId != -1 || fireAimTouchId != -1) && getTimer() - lastCameraMoveTime > 110) {
        cameraBudgetX = 0;
        cameraBudgetY = 0;
        if (cameraKeyXPressed) {
          KeyUtil.simulateKeyPress(stage, false, Keyboard.X);
          cameraKeyXPressed = false;
        }
        if (cameraKeyZPressed) {
          KeyUtil.simulateKeyPress(stage, false, Keyboard.Z);
          cameraKeyZPressed = false;
        }
        if (cameraKeyPageDownPressed) {
          KeyUtil.simulateKeyPress(stage, false, Keyboard.PAGE_DOWN);
          KeyUtil.simulateKeyPress(stage, false, Keyboard.Q);
          cameraKeyPageDownPressed = false;
        }
        if (cameraKeyPageUpPressed) {
          KeyUtil.simulateKeyPress(stage, false, Keyboard.PAGE_UP);
          KeyUtil.simulateKeyPress(stage, false, Keyboard.E);
          cameraKeyPageUpPressed = false;
        }
      }
    }

    private function onStageTouchBegin(event:TouchEvent):void {
      if (settingsMenu.visible) {
        return;
      }
      handleTouchBegin(event.touchPointID, event.stageX, event.stageY);
    }

    private function onStageTouchMove(event:TouchEvent):void {
      if (settingsMenu.visible) {
        return;
      }
      handleTouchMove(event.touchPointID, event.stageX, event.stageY);
    }

    private function onStageTouchEnd(event:TouchEvent):void {
      handleTouchEnd(event.touchPointID);
    }

    private function onStageMouseDown(event:MouseEvent):void {
      if (settingsMenu.visible) {
        return;
      }
      handleTouchBegin(0, event.stageX, event.stageY);
    }

    private function onStageMouseMove(event:MouseEvent):void {
      if (settingsMenu.visible) {
        return;
      }
      if (event.buttonDown) {
        handleTouchMove(0, event.stageX, event.stageY);
      }
    }

    private function onStageMouseUp(event:MouseEvent):void {
      handleTouchEnd(0);
    }

    private function handleTouchBegin(touchId:int, stageX:Number, stageY:Number):void {
      if (joystick != null && joystick.visible) {
        if (joystick.onTouchBegin(touchId, stageX, stageY)) {
          touchStates[touchId] = joystick;
          return;
        }
      }
      var button:ControlButton = getButtonAt(stageX, stageY);
      if (button != null) {
        touchStates[touchId] = button;
        setButtonState(button, true);

        // Aim while shooting: dragging on Fire button rotates camera while shooting
        if (isAimWhileShootingEnabled && (button.getLabel() == 'SPACE' || button.getLabel() == 'FIRE2')) {
          fireAimTouchId = touchId;
          fireAimButton = button;
          fireAimLastX = stageX;
          fireAimLastY = stageY;
        }
        return;
      }

      // Empty area: Camera touch
      if (controlsEnabled && isTouchCameraEnabled && cameraTouchId == -1) {
        cameraTouchId = touchId;
        touchStates[touchId] = "CAMERA";
        cameraLastX = stageX;
        cameraLastY = stageY;
        simulatedMouseX = stageX;
        simulatedMouseY = stageY;
        cameraBudgetX = 0;
        cameraBudgetY = 0;
        lastCameraMoveTime = getTimer();
      }
    }

    private function handleTouchMove(touchId:int, stageX:Number, stageY:Number):void {
      var currentTarget:Object = touchStates[touchId];
      if (currentTarget == joystick) {
        joystick.onTouchMove(touchId, stageX, stageY);
        return;
      }

      if (currentTarget == "CAMERA") {
        handleCameraMove(stageX, stageY);
        return;
      }

      if (touchId == fireAimTouchId && fireAimButton != null) {
        setButtonState(fireAimButton, true);
        var fDeltaX:Number = stageX - fireAimLastX;
        var fDeltaY:Number = stageY - fireAimLastY;
        fireAimLastX = stageX;
        fireAimLastY = stageY;
        applyCameraDelta(fDeltaX, fDeltaY);
        return;
      }

      var buttonUnderTouch:ControlButton = getButtonAt(stageX, stageY);
      var currentButton:ControlButton = currentTarget as ControlButton;
      if (buttonUnderTouch == currentButton) {
        return;
      }
      if (currentButton != null) {
        setButtonState(currentButton, false);
      }
      if (buttonUnderTouch != null) {
        setButtonState(buttonUnderTouch, true);
      }
      touchStates[touchId] = buttonUnderTouch;
    }

    private function applyCameraDelta(deltaX:Number, deltaY:Number):void {
      lastCameraMoveTime = getTimer();

      // Normalize by DPI scale so feeling is identical across devices
      var normX:Number = deltaX / DPI.dpiScale;
      var normY:Number = deltaY / DPI.dpiScale;

      // 1. Mouse distance rotation: dispatch SimulatedMouseEvent with movementX & movementY
      var moveX:Number = normX * cameraSensH * 2.2;
      var moveY:Number = isVerticalCameraDisabled ? 0 : (normY * cameraSensV * 1.6);

      simulatedMouseX += moveX;
      simulatedMouseY += moveY;

      if (stage != null) {
        if (simulatedMouseX < -1000) simulatedMouseX = 0;
        else if (simulatedMouseX > stage.stageWidth + 1000) simulatedMouseX = stage.stageWidth;
        if (simulatedMouseY < -1000) simulatedMouseY = 0;
        else if (simulatedMouseY > stage.stageHeight + 1000) simulatedMouseY = stage.stageHeight;

        var mouseEvt:SimulatedMouseEvent = new SimulatedMouseEvent(
          MouseEvent.MOUSE_MOVE,
          true,
          false,
          simulatedMouseX,
          simulatedMouseY,
          null,
          false, false, false, false, 0,
          moveX,
          moveY
        );
        stage.dispatchEvent(mouseEvt);
      }

      // 2. Horizontal keyboard rotation assist (Z/X)
      cameraBudgetX += normX * cameraSensH * 2.0;
      cameraBudgetX = Math.max(-120, Math.min(120, cameraBudgetX));

      // 3. Vertical keyboard rotation assist (PageDown/Q, PageUp/E)
      if (!isVerticalCameraDisabled) {
        // Gentle vertical budget: clamp to +/- 5.0 frames max so camera changes "не сильно"
        cameraBudgetY += normY * cameraSensV * 0.35;
        cameraBudgetY = Math.max(-5.0, Math.min(5.0, cameraBudgetY));
      } else {
        cameraBudgetY = 0;
      }
    }

    private function handleCameraMove(stageX:Number, stageY:Number):void {
      var deltaX:Number = stageX - cameraLastX;
      var deltaY:Number = stageY - cameraLastY;
      cameraLastX = stageX;
      cameraLastY = stageY;

      applyCameraDelta(deltaX, deltaY);
    }

    private function handleTouchEnd(touchId:int):void {
      if (touchId == fireAimTouchId) {
        if (fireAimButton != null) {
          setButtonState(fireAimButton, false);
          fireAimButton = null;
        }
        fireAimTouchId = -1;
        delete touchStates[touchId];
        releaseCameraKeys();
        return;
      }

      var currentTarget:Object = touchStates[touchId];
      if (currentTarget == joystick) {
        joystick.onTouchEnd(touchId);
        delete touchStates[touchId];
        return;
      }
      if (currentTarget == "CAMERA") {
        cameraTouchId = -1;
        delete touchStates[touchId];
        releaseCameraKeys();
        return;
      }
      var currentButton:ControlButton = currentTarget as ControlButton;
      if (currentButton != null) {
        setButtonState(currentButton, false);
        delete touchStates[touchId];
      }
    }

    private function releaseCameraKeys():void {
      cameraBudgetX = 0;
      cameraBudgetY = 0;
      if (cameraKeyZPressed) {
        KeyUtil.simulateKeyPress(stage, false, Keyboard.Z);
        cameraKeyZPressed = false;
      }
      if (cameraKeyXPressed) {
        KeyUtil.simulateKeyPress(stage, false, Keyboard.X);
        cameraKeyXPressed = false;
      }
      if (cameraKeyPageUpPressed) {
        KeyUtil.simulateKeyPress(stage, false, Keyboard.PAGE_UP);
        KeyUtil.simulateKeyPress(stage, false, Keyboard.E);
        cameraKeyPageUpPressed = false;
      }
      if (cameraKeyPageDownPressed) {
        KeyUtil.simulateKeyPress(stage, false, Keyboard.PAGE_DOWN);
        KeyUtil.simulateKeyPress(stage, false, Keyboard.Q);
        cameraKeyPageDownPressed = false;
      }
    }

    [Inline]
    private final function getButtonAt(stageX:Number, stageY:Number):ControlButton {
      for each(var button:ControlButton in allButtons) {
        if (button.visible && button.parent != null && button.parent.visible && button.hitTestPoint(stageX, stageY, false)) {
          return button;
        }
      }
      return null;
    }

    private function createControls():void {
      // 1. Virtual Joystick
      joystick = new VirtualJoystick(stage);
      joystick.setJoystickSens(joystickSens);
      var joyPos:Point = defaultPositions['JOYSTICK'];
      joystick.x = joyPos.x;
      joystick.y = joyPos.y;
      joystick.setBaseAlpha(buttonsAlpha);
      joystick.addEventListener(MouseEvent.MOUSE_DOWN, startDragControl);
      addChild(joystick);

      // 2. Action Buttons (Shoot, Chat, Flag, Consumables 1-5, Turret Z/X/C)
      createControl(this, 'SPACE', Keyboard.SPACE, 0, DPI.scale(85), buttonSizes[2]);
      createControl(this, 'ENTER', Keyboard.ENTER, 0, DPI.scale(60), buttonSizes[0]);
      createControl(this, 'TAB', Keyboard.TAB, 0, DPI.scale(55), buttonSizes[0]);
      createControl(this, 'F', Keyboard.F, 0, buttonSizes[0], buttonSizes[0]);

      createControl(this, '1', Keyboard.NUMBER_1, 0, buttonSizes[0], buttonSizes[0]);
      createControl(this, '2', Keyboard.NUMBER_2, 0, buttonSizes[0], buttonSizes[0]);
      createControl(this, '3', Keyboard.NUMBER_3, 0, buttonSizes[0], buttonSizes[0]);
      createControl(this, '4', Keyboard.NUMBER_4, 0, buttonSizes[0], buttonSizes[0]);
      createControl(this, '5', Keyboard.NUMBER_5, 0, buttonSizes[0], buttonSizes[0]);

      // Combined 2+3+4 supplies button
      combinedSuppliesBtn = createControl(this, 'COMBINED_234', Keyboard.NUMBER_2, 0, DPI.scale(65), buttonSizes[0], '2+3+4');
      combinedSuppliesBtn.visible = false;

      createControl(this, 'Z', Keyboard.Z, 0, buttonSizes[1], buttonSizes[1]);
      createControl(this, 'X', Keyboard.X, 0, buttonSizes[1], buttonSizes[1]);
      createControl(this, 'C', Keyboard.C, 0, buttonSizes[0], buttonSizes[0]);
      createControl(this, 'Q', Keyboard.Q, 0, buttonSizes[1], buttonSizes[1]);
      createControl(this, 'E', Keyboard.E, 0, buttonSizes[1], buttonSizes[1]);

      // Secondary Fire button (above joystick, fires SPACE)
      createControl(this, 'FIRE2', Keyboard.SPACE, 0, buttonSizes[1], buttonSizes[1], 'FIRE');

      // 3. Movement D-Pad (W, A, S, D, diagonals)
      movementGroup = new Sprite();
      createControl(movementGroup, 'W', Keyboard.W);
      createControl(movementGroup, 'A', Keyboard.A);
      createControl(movementGroup, 'S', Keyboard.S);
      createControl(movementGroup, 'D', Keyboard.D);
      createControl(movementGroup, 'WA', Keyboard.W, Keyboard.A);
      createControl(movementGroup, 'WD', Keyboard.W, Keyboard.D);
      createControl(movementGroup, 'SA', Keyboard.S, Keyboard.A);
      createControl(movementGroup, 'SD', Keyboard.S, Keyboard.D);
      movementGroup.alpha = buttonsAlpha;
      addChild(movementGroup);
      movementGroup.visible = false;
    }

    private function createControl(group:Sprite, label:String, keyCode1:uint, keyCode2:uint = 0, width:Number = 0, height:Number = 0, displayText:String = null):ControlButton {
      var position:Point = defaultPositions[label];
      var btnW:Number = width > 0 ? width : buttonSizes[1];
      var btnH:Number = height > 0 ? height : btnW;
      if (width <= 0) {
        if (keyCode1 == Keyboard.SPACE) {
          btnW = btnH = buttonSizes[2];
        } else if (keyCode2 != 0 || keyCode1 == Keyboard.ENTER || keyCode1 == Keyboard.F || keyCode1 == Keyboard.C || (keyCode1 >= Keyboard.NUMBER_0 && keyCode1 <= Keyboard.NUMBER_9)) {
          btnW = btnH = buttonSizes[0];
        }
      }
      var button:ControlButton = new ControlButton(label, (keyCode2 << 16) | (keyCode1 & 0xFFFF), btnW, btnH, 0x1e1e1e, displayText);
      if (position != null) {
        button.x = position.x;
        button.y = position.y;
      }
      button.setBaseAlpha(buttonsAlpha);
      button.addEventListener(MouseEvent.MOUSE_DOWN, startDragControl);
      group.addChild(button);
      allButtons.push(button);
      activeControls[label] = false;
      return button;
    }

    private function setButtonState(button:ControlButton, pressed:Boolean):void {
      var label:String = button.getLabel();
      if (activeControls[label] == pressed) {
        return;
      }
      activeControls[label] = pressed;
      button.setPressed(pressed);

      if (label == 'COMBINED_234') {
        KeyUtil.simulateKeyPress(stage, pressed, Keyboard.NUMBER_2);
        KeyUtil.simulateKeyPress(stage, pressed, Keyboard.NUMBER_3);
        KeyUtil.simulateKeyPress(stage, pressed, Keyboard.NUMBER_4);
        return;
      }

      var keyCodes:uint = button.getKeyCodes();
      var keyCode1:uint = keyCodes & 0xFFFF;
      var keyCode2:uint = keyCodes >> 16;
      KeyUtil.simulateKeyPress(stage, pressed, keyCode1);
      if (keyCode2 != 0) {
        KeyUtil.simulateKeyPress(stage, pressed, keyCode2);
      }
    }

    private function releaseAllButtons():void {
      for each(var button:ControlButton in allButtons) {
        setButtonState(button, false);
      }
      touchStates = new Dictionary();
    }

    public function selectElement(element:Sprite):void {
      if (selectedElement != null) {
        if (selectedElement is ControlButton) {
          (selectedElement as ControlButton).setSelected(false);
        } else if (selectedElement is VirtualJoystick) {
          (selectedElement as VirtualJoystick).setSelected(false);
        }
      }
      selectedElement = element;
      if (selectedElement != null) {
        if (selectedElement is ControlButton) {
          (selectedElement as ControlButton).setSelected(true);
        } else if (selectedElement is VirtualJoystick) {
          (selectedElement as VirtualJoystick).setSelected(true);
        }
      }
      if (settingsMenu != null) {
        settingsMenu.onElementSelected(selectedElement);
      }
    }

    public function getSelectedElement():Sprite {
      return selectedElement;
    }

    public function setSingleButtonScale(button:ControlButton, scale:Number):void {
      if (button == null) return;
      button.setScale(scale);
      buttonScales[button.getLabel()] = scale;
      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.buttonScales = buttonScales;
      storage.flush();
    }

    public function getSingleButtonScale(button:ControlButton):Number {
      if (button == null) return buttonScale;
      return button.getScale();
    }

    public function setButtonScale(scale:Number):void {
      buttonScale = scale;
      for each(var button:ControlButton in allButtons) {
        button.setScale(scale);
      }
      buttonScales = {};
      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.buttonScale = scale;
      storage.data.buttonScales = buttonScales;
      storage.flush();
    }

    public function setJoystickScale(scale:Number):void {
      joystickScale = scale;
      if (joystick != null) {
        joystick.scaleX = scale;
        joystick.scaleY = scale;
      }
      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.joystickScale = scale;
      storage.flush();
    }

    public function setButtonsAlpha(alpha:Number):void {
      buttonsAlpha = Math.max(0.1, Math.min(1.0, alpha));
      for each(var button:ControlButton in allButtons) {
        button.setBaseAlpha(buttonsAlpha);
      }
      if (movementGroup != null) {
        movementGroup.alpha = buttonsAlpha;
      }
      if (joystick != null) {
        joystick.setBaseAlpha(buttonsAlpha);
      }
      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.buttonsAlpha = buttonsAlpha;
      storage.flush();
    }

    public function getButtonsAlpha():Number {
      return buttonsAlpha;
    }

    public function setCombineSupplies(enabled:Boolean):void {
      isCombineSuppliesEnabled = enabled;
      updateControlsVisibility();
      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.combineSupplies = enabled;
      storage.flush();
    }

    public function getCombineSupplies():Boolean {
      return isCombineSuppliesEnabled;
    }

    public function addCustomButton(label:String, keyCode:uint):ControlButton {
      var cleanLabel:String = label.toUpperCase();
      if (cleanLabel.length == 0) cleanLabel = 'K';

      var btn:ControlButton = new ControlButton(cleanLabel, keyCode, buttonSizes[0], buttonSizes[0]);
      btn.isCustom = true;
      btn.x = stage.stageWidth * 0.5 - btn.getBtnWidth() / 2;
      btn.y = stage.stageHeight * 0.5 - btn.getBtnHeight() / 2;
      btn.setBaseAlpha(buttonsAlpha);
      btn.setScale(buttonScale);
      btn.addEventListener(MouseEvent.MOUSE_DOWN, startDragControl);
      addChild(btn);

      allButtons.push(btn);
      customButtons.push(btn);
      activeControls[btn.getLabel()] = false;

      selectElement(btn);
      saveCustomButtons();
      savePositions();
      return btn;
    }

    public function removeCustomButton(btn:ControlButton):void {
      if (btn == null || !btn.isCustom) return;

      if (btn.parent != null) {
        btn.parent.removeChild(btn);
      }
      var idx:int = allButtons.indexOf(btn);
      if (idx != -1) allButtons.splice(idx, 1);
      var cIdx:int = customButtons.indexOf(btn);
      if (cIdx != -1) customButtons.splice(cIdx, 1);

      delete activeControls[btn.getLabel()];
      delete buttonScales[btn.getLabel()];

      if (selectedElement == btn) {
        selectElement(null);
      }
      saveCustomButtons();
      savePositions();
    }

    private function saveCustomButtons():void {
      var storage:SharedObject = SharedObject.getLocal('storage');
      var list:Array = [];
      for each(var btn:ControlButton in customButtons) {
        list.push({
          label: btn.getLabel(),
          keyCode: btn.getKeyCodes() & 0xFFFF,
          x: btn.x,
          y: btn.y,
          scale: btn.getScale()
        });
      }
      storage.data.customButtons = list;
      storage.flush();
    }

    public function setTouchCameraEnabled(enabled:Boolean):void {
      isTouchCameraEnabled = enabled;
      if (!enabled) {
        releaseCameraKeys();
        cameraTouchId = -1;
      }
      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.touchCamera = enabled;
      storage.flush();
    }

    public function savePositions():void {
      var storage:SharedObject = SharedObject.getLocal('storage');
      var positions:Object = {};
      for each(var button:ControlButton in allButtons) {
        var parent:DisplayObjectContainer = button.parent;
        if (parent != null) {
          positions[button.getLabel()] = new Point(parent.x + button.x, parent.y + button.y);
        }
      }
      if (joystick != null) {
        positions['JOYSTICK'] = new Point(joystick.x, joystick.y);
      }
      if (settingsButton != null) {
        positions['SETTINGS_BTN'] = new Point(settingsButton.x, settingsButton.y);
      }
      if (settingsMenu != null) {
        positions['SETTINGS_MENU'] = new Point(settingsMenu.x, settingsMenu.y);
      }
      storage.data.positions = positions;
      storage.data.buttonScales = buttonScales;
      storage.data.joystickSens = joystickSens;
      storage.flush();
    }

    private function loadPositions():void {
      var storage:SharedObject = SharedObject.getLocal('storage');

      // Load saved custom buttons first
      if (storage.data.customButtons is Array) {
        var list:Array = storage.data.customButtons as Array;
        for each(var item:Object in list) {
          if (item != null && item.label != null && item.keyCode != null) {
            var cBtn:ControlButton = new ControlButton(item.label, uint(item.keyCode), buttonSizes[0], buttonSizes[0]);
            cBtn.isCustom = true;
            cBtn.x = item.x != null ? Number(item.x) : stage.stageWidth * 0.5;
            cBtn.y = item.y != null ? Number(item.y) : stage.stageHeight * 0.5;
            if (item.scale != null) {
              cBtn.setScale(Number(item.scale));
            }
            cBtn.setBaseAlpha(buttonsAlpha);
            cBtn.addEventListener(MouseEvent.MOUSE_DOWN, startDragControl);
            addChild(cBtn);
            allButtons.push(cBtn);
            customButtons.push(cBtn);
            activeControls[cBtn.getLabel()] = false;
          }
        }
      }

      var positions:Object = storage.data.positions;
      if (positions != null) {
        for each(var button:ControlButton in allButtons) {
          var label:String = button.getLabel();
          var position:Object = positions[label];
          if (position == null) {
            continue;
          }
          button.x = position.x;
          button.y = position.y;
        }
        if (joystick != null && positions['JOYSTICK'] != null) {
          joystick.x = positions['JOYSTICK'].x;
          joystick.y = positions['JOYSTICK'].y;
        }
        if (settingsButton != null && positions['SETTINGS_BTN'] != null) {
          settingsButton.x = Math.max(0, Math.min(stage.stageWidth - settingsButton.width, positions['SETTINGS_BTN'].x));
          settingsButton.y = Math.max(0, Math.min(stage.stageHeight - settingsButton.height, positions['SETTINGS_BTN'].y));
        }
        if (settingsMenu != null && positions['SETTINGS_MENU'] != null) {
          settingsMenu.x = Math.max(0, Math.min(stage.stageWidth - DPI.scale(80), positions['SETTINGS_MENU'].x));
          settingsMenu.y = Math.max(0, Math.min(stage.stageHeight - DPI.scale(80), positions['SETTINGS_MENU'].y));
        }
      }

      // Load saved scales
      if (storage.data.buttonScale != undefined) {
        buttonScale = storage.data.buttonScale;
      }
      if (storage.data.buttonScales != null) {
        buttonScales = storage.data.buttonScales;
      }
      for each(var b:ControlButton in allButtons) {
        var s:Object = buttonScales[b.getLabel()];
        if (s != null) {
          b.setScale(Number(s));
        } else {
          b.setScale(buttonScale);
        }
      }

      if (storage.data.joystickScale != undefined) {
        setJoystickScale(storage.data.joystickScale);
      }

      if (storage.data.buttonsAlpha != undefined) {
        setButtonsAlpha(storage.data.buttonsAlpha);
      }

      if (storage.data.combineSupplies != undefined) {
        setCombineSupplies(storage.data.combineSupplies);
      }

      if (storage.data.disableVerticalCamera != undefined) {
        setVerticalCameraDisabled(storage.data.disableVerticalCamera);
      }

      if (storage.data.joystickSens != undefined) {
        setJoystickSens(Number(storage.data.joystickSens));
      }

      if (storage.data.showQEButtons != undefined) {
        setQEButtonsEnabled(storage.data.showQEButtons);
      }

      if (storage.data.aimWhileShooting != undefined) {
        setAimWhileShooting(storage.data.aimWhileShooting);
      }
    }

    public function resetPositions():void {
      defaultPositions = getDefaultPositions();
      for each(var button:ControlButton in allButtons) {
        var position:Point = defaultPositions[button.getLabel()];
        if (position != null) {
          if (button.parent != this) {
            button.parent.x = 0;
            button.parent.y = 0;
          }
          button.x = position.x;
          button.y = position.y;
        }
      }
      if (joystick != null) {
        var joyPos:Point = defaultPositions['JOYSTICK'];
        if (joyPos != null) {
          joystick.x = joyPos.x;
          joystick.y = joyPos.y;
        }
      }
      if (settingsButton != null) {
        settingsButton.x = Math.max(Screen.mainScreen.safeArea.x, DPI.scale(10));
        settingsButton.y = DPI.scale(10);
      }
      if (settingsMenu != null) {
        settingsMenu.x = settingsButton != null ? settingsButton.x : DPI.scale(10);
        settingsMenu.y = settingsButton != null ? settingsButton.y + settingsButton.height + DPI.scale(4) : DPI.scale(50);
      }
      setButtonScale(1.0);
      setJoystickScale(1.0);
      savePositions();
    }

    public function setControlsEnabled(enabled:Boolean):void {
      controlsEnabled = enabled;
      if (enabled) {
        addStageListeners();
      } else {
        removeStageListeners();
        if (joystick != null) joystick.reset();
        releaseAllButtons();
        releaseCameraKeys();
      }
      updateControlsVisibility();

      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.showControls = enabled;
      storage.flush();
    }

    public function setJoystickEnabled(enabled:Boolean):void {
      isJoystickEnabled = enabled;
      if (!enabled && joystick != null) {
        joystick.reset();
      }
      updateControlsVisibility();

      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.showJoystick = enabled;
      storage.flush();
    }

    public function setDpadEnabled(enabled:Boolean):void {
      isDpadEnabled = enabled;
      updateControlsVisibility();

      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.showDpad = enabled;
      storage.flush();
    }

    public function setTurretButtonsEnabled(enabled:Boolean):void {
      isTurretButtonsEnabled = enabled;
      updateControlsVisibility();

      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.showTurretButtons = enabled;
      storage.flush();
    }

    public function setFire2Enabled(enabled:Boolean):void {
      isFire2Enabled = enabled;
      updateControlsVisibility();

      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.showFire2 = enabled;
      storage.flush();
    }

    public function setCameraSensH(sens:Number):void {
      cameraSensH = sens;
      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.cameraSensH = sens;
      storage.flush();
    }

    public function setCameraSensV(sens:Number):void {
      cameraSensV = sens;
      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.cameraSensV = sens;
      storage.flush();
    }

    public function setVerticalCameraDisabled(disabled:Boolean):void {
      isVerticalCameraDisabled = disabled;
      if (disabled) {
        if (cameraKeyPageDownPressed) {
          KeyUtil.simulateKeyPress(stage, false, Keyboard.PAGE_DOWN);
          KeyUtil.simulateKeyPress(stage, false, Keyboard.Q);
          cameraKeyPageDownPressed = false;
        }
        if (cameraKeyPageUpPressed) {
          KeyUtil.simulateKeyPress(stage, false, Keyboard.PAGE_UP);
          KeyUtil.simulateKeyPress(stage, false, Keyboard.E);
          cameraKeyPageUpPressed = false;
        }
        cameraBudgetY = 0;
      }
      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.disableVerticalCamera = disabled;
      storage.flush();
    }

    public function getVerticalCameraDisabled():Boolean {
      return isVerticalCameraDisabled;
    }

    public function setQEButtonsEnabled(enabled:Boolean):void {
      isQEButtonsEnabled = enabled;
      updateControlsVisibility();
      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.showQEButtons = enabled;
      storage.flush();
    }

    public function getQEButtonsEnabled():Boolean {
      return isQEButtonsEnabled;
    }

    public function setAimWhileShooting(enabled:Boolean):void {
      isAimWhileShootingEnabled = enabled;
      if (!enabled && fireAimTouchId != -1) {
        if (fireAimButton != null) {
          setButtonState(fireAimButton, false);
          fireAimButton = null;
        }
        fireAimTouchId = -1;
      }
      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.aimWhileShooting = enabled;
      storage.flush();
    }

    public function getAimWhileShooting():Boolean {
      return isAimWhileShootingEnabled;
    }

    public function getControlsEnabled():Boolean { return controlsEnabled; }
    public function getJoystickEnabled():Boolean { return isJoystickEnabled; }
    public function getDpadEnabled():Boolean { return isDpadEnabled; }
    public function getTouchCameraEnabled():Boolean { return isTouchCameraEnabled; }
    public function getTurretButtonsEnabled():Boolean { return isTurretButtonsEnabled; }
    public function getFire2Enabled():Boolean { return isFire2Enabled; }
    public function getCameraSensH():Number { return cameraSensH; }
    public function getCameraSensV():Number { return cameraSensV; }
    public function getButtonScale():Number { return buttonScale; }
    public function getJoystickScale():Number { return joystickScale; }
    public function getJoystickSens():Number { return joystickSens; }

    public function setJoystickSens(sens:Number):void {
      this.joystickSens = sens;
      if (joystick != null) {
        joystick.setJoystickSens(sens);
      }
      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.joystickSens = sens;
      storage.flush();
    }

    public function exportSettingsJson():String {
      var sw:Number = stage.stageWidth;
      var sh:Number = stage.stageHeight;

      var posExport:Object = {};
      for each(var btn:ControlButton in allButtons) {
        if (btn.parent != null) {
          posExport[btn.getLabel()] = {
            rx: Number(((btn.parent.x + btn.x) / sw).toFixed(4)),
            ry: Number(((btn.parent.y + btn.y) / sh).toFixed(4))
          };
        }
      }
      if (joystick != null) {
        posExport['JOYSTICK'] = {
          rx: Number((joystick.x / sw).toFixed(4)),
          ry: Number((joystick.y / sh).toFixed(4))
        };
      }
      if (settingsButton != null) {
        posExport['SETTINGS_BTN'] = {
          rx: Number((settingsButton.x / sw).toFixed(4)),
          ry: Number((settingsButton.y / sh).toFixed(4))
        };
      }

      var customList:Array = [];
      for each(var cBtn:ControlButton in customButtons) {
        customList.push({
          label: cBtn.getLabel(),
          keyCode: cBtn.getKeyCodes() & 0xFFFF,
          rx: Number((cBtn.x / sw).toFixed(4)),
          ry: Number((cBtn.y / sh).toFixed(4)),
          scale: Number(cBtn.getScale().toFixed(2))
        });
      }

      var exportObj:Object = {
        v: 1,
        positions: posExport,
        buttonScales: buttonScales,
        buttonScale: Number(buttonScale.toFixed(2)),
        joystickScale: Number(joystickScale.toFixed(2)),
        joystickSens: Number(joystickSens.toFixed(2)),
        buttonsAlpha: Number(buttonsAlpha.toFixed(2)),
        cameraSensH: Number(cameraSensH.toFixed(2)),
        cameraSensV: Number(cameraSensV.toFixed(2)),
        disableVertCam: isVerticalCameraDisabled,
        combineSupplies: isCombineSuppliesEnabled,
        showControls: controlsEnabled,
        showJoystick: isJoystickEnabled,
        showDpad: isDpadEnabled,
        touchCamera: isTouchCameraEnabled,
        showTurret: isTurretButtonsEnabled,
        showQE: isQEButtonsEnabled,
        showFire2: isFire2Enabled,
        aimWhileShooting: isAimWhileShootingEnabled,
        customButtons: customList
      };

      return JSON.stringify(exportObj);
    }

    public function importSettingsJson(jsonStr:String):Boolean {
      if (jsonStr == null || jsonStr.length == 0) return false;
      try {
        var data:Object = JSON.parse(jsonStr);
        if (data == null) return false;

        var sw:Number = stage.stageWidth;
        var sh:Number = stage.stageHeight;

        // 1. Remove existing custom buttons and recreate from import
        while (customButtons.length > 0) {
          removeCustomButton(customButtons[0]);
        }
        if (data.customButtons is Array) {
          for each(var cItem:Object in data.customButtons) {
            if (cItem != null && cItem.label != null && cItem.keyCode != null) {
              var nBtn:ControlButton = addCustomButton(String(cItem.label), uint(cItem.keyCode));
              if (cItem.rx != null && cItem.ry != null) {
                nBtn.x = Number(cItem.rx) * sw;
                nBtn.y = Number(cItem.ry) * sh;
              }
              if (cItem.scale != null) {
                nBtn.setScale(Number(cItem.scale));
              }
            }
          }
        }

        // 2. Positions
        if (data.positions != null) {
          for each(var btn:ControlButton in allButtons) {
            var pObj:Object = data.positions[btn.getLabel()];
            if (pObj != null) {
              if (pObj.rx != null && pObj.ry != null) {
                btn.x = Number(pObj.rx) * sw;
                btn.y = Number(pObj.ry) * sh;
              } else if (pObj.x != null && pObj.y != null) {
                btn.x = Number(pObj.x);
                btn.y = Number(pObj.y);
              }
            }
          }
          if (joystick != null && data.positions['JOYSTICK'] != null) {
            var jPos:Object = data.positions['JOYSTICK'];
            if (jPos.rx != null && jPos.ry != null) {
              joystick.x = Number(jPos.rx) * sw;
              joystick.y = Number(jPos.ry) * sh;
            } else if (jPos.x != null && jPos.y != null) {
              joystick.x = Number(jPos.x);
              joystick.y = Number(jPos.y);
            }
          }
          if (settingsButton != null && data.positions['SETTINGS_BTN'] != null) {
            var sPos:Object = data.positions['SETTINGS_BTN'];
            if (sPos.rx != null && sPos.ry != null) {
              settingsButton.x = Number(sPos.rx) * sw;
              settingsButton.y = Number(sPos.ry) * sh;
            }
          }
        }

        // 3. Scales
        if (data.buttonScale != null) setButtonScale(Number(data.buttonScale));
        if (data.joystickScale != null) setJoystickScale(Number(data.joystickScale));
        if (data.buttonScales != null) {
          buttonScales = data.buttonScales;
          for each(var b:ControlButton in allButtons) {
            if (buttonScales[b.getLabel()] != null) {
              b.setScale(Number(buttonScales[b.getLabel()]));
            }
          }
        }

        // 4. Alpha & Sensitivity
        if (data.buttonsAlpha != null) setButtonsAlpha(Number(data.buttonsAlpha));
        if (data.joystickSens != null) setJoystickSens(Number(data.joystickSens));
        if (data.cameraSensH != null) setCameraSensH(Number(data.cameraSensH));
        if (data.cameraSensV != null) setCameraSensV(Number(data.cameraSensV));
        if (data.disableVertCam != null) setVerticalCameraDisabled(Boolean(data.disableVertCam));

        // 5. Checkbox toggles
        if (data.combineSupplies != null) setCombineSupplies(Boolean(data.combineSupplies));
        if (data.showControls != null) setControlsEnabled(Boolean(data.showControls));
        if (data.showJoystick != null) setJoystickEnabled(Boolean(data.showJoystick));
        if (data.showDpad != null) setDpadEnabled(Boolean(data.showDpad));
        if (data.touchCamera != null) setTouchCameraEnabled(Boolean(data.touchCamera));
        if (data.showTurret != null) setTurretButtonsEnabled(Boolean(data.showTurret));
        if (data.showQE != null) setQEButtonsEnabled(Boolean(data.showQE));
        if (data.showFire2 != null) setFire2Enabled(Boolean(data.showFire2));
        if (data.aimWhileShooting != null) setAimWhileShooting(Boolean(data.aimWhileShooting));

        savePositions();
        saveCustomButtons();
        if (settingsMenu != null) {
          settingsMenu.refreshUI();
        }
        return true;
      } catch (err:Error) {
        return false;
      }
      return false;
    }

    private function updateControlsVisibility():void {
      if (joystick != null) {
        joystick.visible = controlsEnabled && isJoystickEnabled;
      }
      if (movementGroup != null) {
        movementGroup.visible = controlsEnabled && isDpadEnabled;
      }
      for each(var button:ControlButton in allButtons) {
        var label:String = button.getLabel();
        if (button.parent == movementGroup) {
          button.visible = isDpadEnabled;
        } else if (label == 'Z' || label == 'X' || label == 'C') {
          button.visible = controlsEnabled && isTurretButtonsEnabled;
        } else if (label == 'Q' || label == 'E') {
          button.visible = controlsEnabled && isQEButtonsEnabled;
        } else if (label == 'FIRE2') {
          button.visible = controlsEnabled && isFire2Enabled;
        } else if (label == '2' || label == '3' || label == '4') {
          button.visible = controlsEnabled && !isCombineSuppliesEnabled;
        } else if (label == 'COMBINED_234') {
          button.visible = controlsEnabled && isCombineSuppliesEnabled;
        } else {
          button.visible = controlsEnabled;
        }
      }
    }

    private var draggedElement:Sprite;

    private function startDragControl(event:MouseEvent):void {
      if (!settingsMenu.visible) {
        return;
      }
      var target:Sprite = event.currentTarget as Sprite;
      if (target == null) {
        return;
      }
      selectElement(target);

      draggedElement = target;
      if (draggedElement.parent != this && draggedElement.parent != null) {
        draggedElement = draggedElement.parent as Sprite;
      }
      draggedElement.startDrag();
      if (stage != null) {
        stage.addEventListener(MouseEvent.MOUSE_UP, stopDragControl);
        stage.addEventListener(TouchEvent.TOUCH_END, stopDragControlTouch);
      }
    }

    private function stopDragControlTouch(event:TouchEvent):void {
      stopDragControl(null);
    }

    private function stopDragControl(event:MouseEvent):void {
      if (draggedElement != null) {
        draggedElement.stopDrag();
        draggedElement = null;
      }
      if (stage != null) {
        stage.removeEventListener(MouseEvent.MOUSE_UP, stopDragControl);
        stage.removeEventListener(TouchEvent.TOUCH_END, stopDragControlTouch);
      }
      savePositions();
    }

  }
}
