package controls {
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.MouseEvent;
  import flash.events.TouchEvent;
  import flash.geom.Point;

  public class NormalSlider extends Sprite {

    private var track:Sprite;
    private var handle:Sprite;

    private var _value:Number = 0.5;

    private var minX:Number;
    private var maxX:Number;
    private var isDragging:Boolean = false;

    private var startStageX:Number = 0;
    private var startStageY:Number = 0;
    private var gestureLocked:Boolean = false; // true if decided horizontal sliding vs vertical scrolling

    public function NormalSlider(width:Number) {
      var trackWidth:Number = DPI.scale(width);
      minX = 0;
      maxX = trackWidth;

      track = new Sprite();
      // Invisible extended hit area for track to make tapping easy
      track.graphics.beginFill(0x000000, 0.01);
      track.graphics.drawRect(-DPI.scale(5), -DPI.scale(6), trackWidth + DPI.scale(10), DPI.scale(20));
      track.graphics.endFill();

      // Visual track
      track.graphics.beginFill(0x555555, 0.9);
      track.graphics.drawRoundRect(0, 0, trackWidth, DPI.scale(8), DPI.scale(4), DPI.scale(4));
      track.graphics.endFill();

      track.graphics.beginFill(0x777777, 0.9);
      track.graphics.drawRect(0, DPI.scale(3), trackWidth, DPI.scale(2));
      track.graphics.endFill();

      track.buttonMode = true;
      track.addEventListener(MouseEvent.MOUSE_DOWN, onTrackDown);
      track.addEventListener(TouchEvent.TOUCH_BEGIN, onTrackTouchBegin);
      addChild(track);

      handle = new Sprite();
      // Generous invisible hit area for finger touch
      handle.graphics.beginFill(0x000000, 0.01);
      handle.graphics.drawCircle(0, DPI.scale(4), DPI.scale(16));
      handle.graphics.endFill();

      // Visual handle
      handle.graphics.beginFill(0xCCCCCC);
      handle.graphics.drawCircle(0, DPI.scale(4), DPI.scale(10));
      handle.graphics.endFill();
      handle.graphics.beginFill(0xFFFFFF);
      handle.graphics.drawCircle(0, DPI.scale(4), DPI.scale(7.5));
      handle.graphics.endFill();

      handle.buttonMode = true;
      handle.addEventListener(MouseEvent.MOUSE_DOWN, startDragHandle);
      handle.addEventListener(TouchEvent.TOUCH_BEGIN, startDragHandleTouch);
      addChild(handle);

      updateHandlePosition();
    }

    private function onTrackDown(event:MouseEvent):void {
      initGesture(event.stageX, event.stageY);
      setValueFromLocalX(mouseX);
      startDragHandle(event);
    }

    private function onTrackTouchBegin(event:TouchEvent):void {
      initGesture(event.stageX, event.stageY);
      var pt:Point = globalToLocal(new Point(event.stageX, event.stageY));
      setValueFromLocalX(pt.x);
      startDragHandleTouch(event);
    }

    private function initGesture(sX:Number, sY:Number):void {
      startStageX = sX;
      startStageY = sY;
      gestureLocked = false;
    }

    private function startDragHandle(event:MouseEvent):void {
      if (isDragging) return;
      isDragging = true;
      initGesture(event.stageX, event.stageY);
      if (stage != null) {
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
        stage.addEventListener(MouseEvent.MOUSE_UP, stopDragHandle);
        stage.addEventListener(TouchEvent.TOUCH_MOVE, onStageTouchMove);
        stage.addEventListener(TouchEvent.TOUCH_END, stopDragHandleTouch);
      }
    }

    private function startDragHandleTouch(event:TouchEvent):void {
      if (isDragging) return;
      isDragging = true;
      initGesture(event.stageX, event.stageY);
      if (stage != null) {
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
        stage.addEventListener(MouseEvent.MOUSE_UP, stopDragHandle);
        stage.addEventListener(TouchEvent.TOUCH_MOVE, onStageTouchMove);
        stage.addEventListener(TouchEvent.TOUCH_END, stopDragHandleTouch);
      }
    }

    private function onStageMouseMove(event:MouseEvent):void {
      if (isDragging) {
        if (checkVerticalScrollCancel(event.stageX, event.stageY)) return;
        setValueFromLocalX(mouseX);
      }
    }

    private function onStageTouchMove(event:TouchEvent):void {
      if (isDragging) {
        if (checkVerticalScrollCancel(event.stageX, event.stageY)) return;
        var pt:Point = globalToLocal(new Point(event.stageX, event.stageY));
        setValueFromLocalX(pt.x);
      }
    }

    private function checkVerticalScrollCancel(sX:Number, sY:Number):Boolean {
      if (!gestureLocked) {
        var dx:Number = Math.abs(sX - startStageX);
        var dy:Number = Math.abs(sY - startStageY);
        if (dy > DPI.scale(7) && dy > dx * 1.3) {
          // Gesture is vertical scroll -> cancel slider drag so parent container can scroll
          finishDrag();
          return true;
        }
        if (dx > DPI.scale(4)) {
          gestureLocked = true;
        }
      }
      return false;
    }

    private function stopDragHandle(event:MouseEvent):void {
      finishDrag();
    }

    private function stopDragHandleTouch(event:TouchEvent):void {
      finishDrag();
    }

    private function finishDrag():void {
      if (!isDragging) return;
      isDragging = false;
      gestureLocked = false;
      if (stage != null) {
        stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
        stage.removeEventListener(MouseEvent.MOUSE_UP, stopDragHandle);
        stage.removeEventListener(TouchEvent.TOUCH_MOVE, onStageTouchMove);
        stage.removeEventListener(TouchEvent.TOUCH_END, stopDragHandleTouch);
      }
    }

    private function setValueFromLocalX(localX:Number):void {
      var newValue:Number = (localX - minX) / (maxX - minX);
      newValue = Math.max(0, Math.min(1, newValue));
      if (Math.abs(newValue - _value) > 0.002) {
        _value = newValue;
        updateHandlePosition();
        dispatchEvent(new Event(Event.CHANGE));
      }
    }

    private function updateHandlePosition():void {
      handle.x = minX + (_value * (maxX - minX));
    }

    public function get value():Number {
      return _value;
    }

    public function set value(v:Number):void {
      var clamped:Number = Math.max(0, Math.min(1, v));
      _value = clamped;
      updateHandlePosition();
      dispatchEvent(new Event(Event.CHANGE));
    }

  }
}
