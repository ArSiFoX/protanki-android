package controls {
  import flash.display.Shape;
  import flash.display.Sprite;

  public class ControlButton extends Sprite {

    private var label:String;
    private var keyCodes:uint;
    private var btnWidth:Number;
    private var btnHeight:Number;
    private var btnColor:uint;
    private var bg:Shape;

    private var isSelected:Boolean = false;
    private var baseAlpha:Number = 1.0;
    private var customScale:Number = 1.0;
    public var isCustom:Boolean = false;

    public function ControlButton(label:String, keyCodes:uint, width:Number, height:Number = 0, color:uint = 0x1e1e1e, displayText:String = null) {
      this.label = label;
      this.keyCodes = keyCodes;
      this.btnWidth = width;
      this.btnHeight = (height > 0) ? height : width;
      this.btnColor = color;

      bg = new Shape();
      drawBackground(btnColor, 0.6);
      addChild(bg);

      var textToShow:String = (displayText != null) ? displayText : label;
      var fontSize:Number;
      if (textToShow.length <= 1) {
        fontSize = Math.min(btnWidth, btnHeight) * 0.44;
      } else if (textToShow.length <= 2) {
        fontSize = Math.min(btnWidth, btnHeight) * 0.36;
      } else if (textToShow.length <= 3) {
        fontSize = Math.min(btnWidth, btnHeight) * 0.30;
      } else if (textToShow.length <= 5) {
        fontSize = Math.min(btnWidth, btnHeight) * 0.22;
      } else {
        fontSize = Math.min(btnWidth, btnHeight) * 0.18;
      }

      var tl:TextLabel = new TextLabel(textToShow, int(fontSize));
      tl.x = (btnWidth - tl.width) / 2;
      tl.y = (btnHeight - tl.height) / 2;
      addChild(tl);

      buttonMode = true;
      mouseChildren = false;
    }

    private function drawBackground(color:uint, alphaFill:Number):void {
      bg.graphics.clear();
      bg.graphics.beginFill(color, alphaFill);
      if (isSelected) {
        bg.graphics.lineStyle(DPI.scale(3), 0xFFD700, 1.0); // Gold outline when selected
      } else {
        bg.graphics.lineStyle(DPI.scale(2), 0xFFFFFF, 0.8);
      }
      var radius:Number = DPI.scale(8);
      bg.graphics.drawRoundRect(0, 0, btnWidth, btnHeight, radius, radius);
      bg.graphics.endFill();
    }

    public function setSelected(selected:Boolean):void {
      if (isSelected != selected) {
        isSelected = selected;
        drawBackground(btnColor, 0.6);
      }
    }

    public function getSelected():Boolean {
      return isSelected;
    }

    public function setBaseAlpha(a:Number):void {
      baseAlpha = a;
      alpha = baseAlpha;
    }

    public function getBaseAlpha():Number {
      return baseAlpha;
    }

    public function setPressed(pressed:Boolean):void {
      alpha = pressed ? baseAlpha * 0.5 : baseAlpha;
    }

    public function setScale(s:Number):void {
      customScale = s;
      scaleX = s;
      scaleY = s;
    }

    public function getScale():Number {
      return customScale;
    }

    public function getLabel():String {
      return label;
    }

    public function getKeyCodes():uint {
      return keyCodes;
    }

    public function getBtnWidth():Number {
      return btnWidth;
    }

    public function getBtnHeight():Number {
      return btnHeight;
    }
  }
}
