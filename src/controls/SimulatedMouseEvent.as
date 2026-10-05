package controls {
  import flash.display.InteractiveObject;
  import flash.events.MouseEvent;

  public class SimulatedMouseEvent extends MouseEvent {

    private var _movementX:Number;
    private var _movementY:Number;

    public function SimulatedMouseEvent(
      type:String,
      bubbles:Boolean = true,
      cancelable:Boolean = false,
      localX:Number = 0,
      localY:Number = 0,
      relatedObject:InteractiveObject = null,
      ctrlKey:Boolean = false,
      altKey:Boolean = false,
      shiftKey:Boolean = false,
      buttonDown:Boolean = false,
      delta:int = 0,
      movementXVal:Number = 0,
      movementYVal:Number = 0
    ) {
      super(type, bubbles, cancelable, localX, localY, relatedObject, ctrlKey, altKey, shiftKey, buttonDown, delta);
      this._movementX = movementXVal;
      this._movementY = movementYVal;
    }

    override public function get movementX():Number {
      return _movementX;
    }

    override public function get movementY():Number {
      return _movementY;
    }

  }
}
