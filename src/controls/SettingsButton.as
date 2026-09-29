package controls {
  import flash.display.Sprite;
  import flash.events.MouseEvent;
  import flash.events.TouchEvent;
  import flash.geom.Point;
  import flash.utils.getTimer;

  public class SettingsButton extends Sprite {

    private var onScreenControls:OnScreenControlsLayer;
    private var isDragging:Boolean = false;
    private var isInteracting:Boolean = false;
    private var mouseDownPos:Point = new Point();
    private var lastActionTime:int = 0;

    public function SettingsButton(controls:OnScreenControlsLayer = null) {
      super();
      this.onScreenControls = controls;

      graphics.beginFill(0x000000, 0.5);
      graphics.drawRect(0, 0, DPI.scale(40), DPI.scale(40));
      graphics.endFill();

      var icon:TextLabel = new TextLabel('⚙', DPI.scale(25));
      icon.x = width / 2 - icon.width / 2;
      icon.y = height / 2 - icon.height / 2;
      addChild(icon);

      buttonMode = true;
      mouseChildren = false;

      addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
      addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
    }

    private function onTouchBegin(event:TouchEvent):void {
      startDragCheck(event.stageX, event.stageY);
    }

    private function onMouseDown(event:MouseEvent):void {
      startDragCheck(event.stageX, event.stageY);
    }

    private function startDragCheck(startX:Number, startY:Number):void {
      if (isInteracting) return;
      isInteracting = true;
      mouseDownPos.x = startX;
      mouseDownPos.y = startY;
      isDragging = false;

      if (stage != null) {
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
        stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);
      }
    }

    private function onTouchMove(event:TouchEvent):void {
      checkMove(event.stageX, event.stageY);
    }

    private function onMouseMove(event:MouseEvent):void {
      checkMove(event.stageX, event.stageY);
    }

    private function checkMove(curX:Number, curY:Number):void {
      if (!isDragging) {
        var dx:Number = curX - mouseDownPos.x;
        var dy:Number = curY - mouseDownPos.y;
        if (Math.sqrt(dx * dx + dy * dy) > DPI.scale(8)) {
          isDragging = true;
          startDrag();
        }
      }
    }

    private function onTouchEnd(event:TouchEvent):void {
      finishDragCheck();
    }

    private function onMouseUp(event:MouseEvent):void {
      finishDragCheck();
    }

    private function finishDragCheck():void {
      if (!isInteracting) return;
      isInteracting = false;
      if (stage != null) {
        stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        stage.removeEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
        stage.removeEventListener(TouchEvent.TOUCH_END, onTouchEnd);
      }
      var now:int = getTimer();
      if (now - lastActionTime < 250) {
        return;
      }
      lastActionTime = now;

      if (isDragging) {
        stopDrag();
        isDragging = false;
        if (onScreenControls != null) {
          onScreenControls.savePositions();
        }
      } else {
        if (onScreenControls != null) {
          onScreenControls.toggleSettings();
        }
      }
    }

  }
}
