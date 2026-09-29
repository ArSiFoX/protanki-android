package controls {
  import flash.desktop.Clipboard;
  import flash.desktop.ClipboardFormats;
  import flash.display.DisplayObject;
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.MouseEvent;
  import flash.events.TouchEvent;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  import flash.net.SharedObject;
  import flash.text.TextField;
  import flash.text.TextFieldType;
  import flash.text.TextFormat;
  import flash.ui.Keyboard;
  import flash.utils.getTimer;
  import lang.t;

  public class SettingsMenu extends Sprite {

    private var settingsButton:SettingsButton;
    private var onScreenControls:OnScreenControlsLayer;

    private var menuW:Number;
    private var menuH:Number;
    private var titleH:Number;
    private var tabH:Number;
    private var viewportH:Number;

    private var titleBar:Sprite;
    private var isDraggingMenu:Boolean = false;
    private var lastCloseTime:int = 0;

    // Tabs
    private var tabButtons:Vector.<Sprite> = new Vector.<Sprite>();
    private var tabContainers:Vector.<Sprite> = new Vector.<Sprite>();
    private var currentTabIndex:int = 0;

    // Viewport & Scroll
    private var viewportHolder:Sprite;
    private var activeScrollContainer:Sprite;
    private var scrollbars:Vector.<Sprite> = new Vector.<Sprite>();
    private var scrollY:Number = 0;
    private var maxScroll:Number = 0;
    private var isScrolling:Boolean = false;
    private var scrollStartMouseY:Number = 0;
    private var scrollStartScrollY:Number = 0;

    // Tab 1: Controls
    private var showControlsCheckbox:Checkbox;
    private var showJoystickCheckbox:Checkbox;
    private var showDpadCheckbox:Checkbox;
    private var touchCameraCheckbox:Checkbox;
    private var showTurretCheckbox:Checkbox;
    private var showFire2Checkbox:Checkbox;
    private var combineSuppliesCheckbox:Checkbox;

    // Tab 2: Sizes
    private var selectedButtonLabel:TextLabel;
    private var buttonSizeSlider:NormalSlider;
    private var allButtonsBtn:Sprite;
    private var joystickSizeLabel:TextLabel;
    private var joystickSizeSlider:NormalSlider;
    private var buttonsAlphaLabel:TextLabel;
    private var buttonsAlphaSlider:NormalSlider;
    private var alphaLabel:TextLabel;
    private var alphaSlider:NormalSlider;

    // Tab 3: Camera
    private var disableVertCamCheckbox:Checkbox;
    private var sensHLabel:TextLabel;
    private var sensHSlider:NormalSlider;
    private var sensVLabel:TextLabel;
    private var sensVSlider:NormalSlider;

    // Tab 4: Custom buttons
    private var customKeyInput:TextField;
    private var deleteCustomBtn:Sprite;

    // Tab 5: Profile (Import / Export / Reset)
    private var codeTextArea:TextField;
    private var statusLabel:TextField;

    private var selectedElement:Sprite = null;

    public function SettingsMenu(button:SettingsButton, touchControls:OnScreenControlsLayer) {
      super();
      this.settingsButton = button;
      this.onScreenControls = touchControls;
      createUI();
      loadSettings();
    }

    private function createUI():void {
      menuW = DPI.scale(330);
      menuH = DPI.scale(275);
      titleH = DPI.scale(34);
      tabH = DPI.scale(28);
      viewportH = menuH - titleH - tabH - DPI.scale(6);

      // Window background
      graphics.beginFill(0x202020, 0.96);
      graphics.lineStyle(DPI.scale(1.5), 0x4F4F4F, 0.95);
      graphics.drawRoundRect(0, 0, menuW, menuH, DPI.scale(10), DPI.scale(10));
      graphics.endFill();

      // Title bar (draggable header)
      titleBar = new Sprite();
      titleBar.graphics.beginFill(0x2D2D2D, 0.98);
      titleBar.graphics.drawRoundRect(0, 0, menuW, titleH, DPI.scale(10), DPI.scale(10));
      titleBar.graphics.drawRect(0, titleH - DPI.scale(8), menuW, DPI.scale(8));
      titleBar.graphics.endFill();
      titleBar.buttonMode = true;
      titleBar.addEventListener(MouseEvent.MOUSE_DOWN, onTitleBarDown);
      titleBar.addEventListener(TouchEvent.TOUCH_BEGIN, onTitleBarTouchDown);
      addChild(titleBar);

      var title:TextField = new TextLabel('⚙ ' + t('settings'), DPI.scale(13));
      title.x = DPI.scale(10);
      title.y = DPI.scale(7);
      title.mouseEnabled = false;
      titleBar.addChild(title);

      // Close 'X' button in title bar
      var closeBtn:Sprite = new Sprite();
      closeBtn.graphics.beginFill(0x000000, 0.01);
      closeBtn.graphics.drawRect(0, 0, DPI.scale(32), DPI.scale(32));
      closeBtn.graphics.endFill();
      var closeLabel:TextField = new TextLabel('✕', DPI.scale(15), 0xCCCCCC);
      closeLabel.x = (DPI.scale(32) - closeLabel.width) / 2;
      closeLabel.y = (DPI.scale(32) - closeLabel.height) / 2;
      closeBtn.addChild(closeLabel);
      closeBtn.x = menuW - DPI.scale(34);
      closeBtn.y = DPI.scale(1);
      closeBtn.buttonMode = true;
      closeBtn.addEventListener(MouseEvent.CLICK, onCloseClick);
      closeBtn.addEventListener(TouchEvent.TOUCH_TAP, onCloseClick);
      addChild(closeBtn);

      // Category Tab Bar
      createTabBar();

      // Viewport container
      viewportHolder = new Sprite();
      viewportHolder.x = 0;
      viewportHolder.y = titleH + tabH;
      addChild(viewportHolder);

      // Create tabs content
      createTabControls();
      createTabSizes();
      createTabCamera();
      createTabCustom();
      createTabProfile();

      // Viewport scroll events
      viewportHolder.addEventListener(MouseEvent.MOUSE_DOWN, onContentMouseDown);
      viewportHolder.addEventListener(TouchEvent.TOUCH_BEGIN, onContentTouchBegin);
      addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);

      switchTab(0);
    }

    private function createTabBar():void {
      var bar:Sprite = new Sprite();
      bar.x = DPI.scale(6);
      bar.y = titleH;
      addChild(bar);

      var tabNames:Array = [
        t('tab_controls'),
        t('tab_sizes'),
        t('tab_camera'),
        t('tab_custom'),
        t('tab_profile')
      ];

      var totalW:Number = menuW - DPI.scale(12);
      var tabW:Number = totalW / tabNames.length;

      for (var i:int = 0; i < tabNames.length; i++) {
        var btn:Sprite = new Sprite();
        btn.x = i * tabW;
        btn.buttonMode = true;
        btn.mouseChildren = false;

        var lbl:TextLabel = new TextLabel(tabNames[i], DPI.scale(9.5), 0xAAAAAA);
        lbl.x = (tabW - lbl.width) / 2;
        lbl.y = (tabH - lbl.height) / 2;
        btn.addChild(lbl);

        var idx:int = i;
        btn.addEventListener(MouseEvent.CLICK, makeTabClickHandler(idx));

        bar.addChild(btn);
        tabButtons.push(btn);
      }
    }

    private function makeTabClickHandler(index:int):Function {
      return function(e:Event):void {
        switchTab(index);
      };
    }

    private function switchTab(index:int):void {
      currentTabIndex = index;
      var totalW:Number = menuW - DPI.scale(12);
      var tabW:Number = totalW / tabButtons.length;

      for (var i:int = 0; i < tabButtons.length; i++) {
        var btn:Sprite = tabButtons[i];
        btn.graphics.clear();
        var lbl:TextField = btn.getChildAt(0) as TextField;

        if (i == index) {
          btn.graphics.beginFill(0x3D3D3D, 0.95);
          btn.graphics.drawRoundRect(0, 0, tabW - DPI.scale(2), tabH, DPI.scale(4), DPI.scale(4));
          btn.graphics.beginFill(0x0088FF, 1.0);
          btn.graphics.drawRect(DPI.scale(4), tabH - DPI.scale(2.5), tabW - DPI.scale(10), DPI.scale(2.5));
          btn.graphics.endFill();
          if (lbl != null) lbl.textColor = 0xFFFFFF;
        } else {
          btn.graphics.beginFill(0x262626, 0.7);
          btn.graphics.drawRoundRect(0, 0, tabW - DPI.scale(2), tabH, DPI.scale(4), DPI.scale(4));
          btn.graphics.endFill();
          if (lbl != null) lbl.textColor = 0x888888;
        }

        if (i < tabContainers.length) {
          tabContainers[i].visible = (i == index);
        }
      }

      scrollY = 0;
      activeScrollContainer = tabContainers[index];
      updateScroll();
    }

    // --- TAB 1: CONTROLS ---
    private function createTabControls():void {
      var cont:Sprite = new Sprite();
      var cbX:Number = DPI.scale(12);
      var curY:Number = DPI.scale(8);
      var rowGap:Number = DPI.scale(23);

      var hint:TextField = new TextLabel(t('drag_buttons_hint'), DPI.scale(10), 0x888888);
      hint.x = cbX;
      hint.y = curY;
      cont.addChild(hint);
      curY += DPI.scale(18);

      showControlsCheckbox = new Checkbox();
      showControlsCheckbox.x = cbX;
      showControlsCheckbox.y = curY;
      showControlsCheckbox.addEventListener(MouseEvent.CLICK, onShowControlsChange);
      cont.addChild(showControlsCheckbox);
      var lbl1:TextLabel = new TextLabel(t('show_controls'), DPI.scale(11));
      lbl1.x = showControlsCheckbox.x + showControlsCheckbox.width + DPI.scale(8);
      lbl1.y = showControlsCheckbox.y + DPI.scale(2);
      cont.addChild(lbl1);
      curY += rowGap;

      showJoystickCheckbox = new Checkbox();
      showJoystickCheckbox.x = cbX;
      showJoystickCheckbox.y = curY;
      showJoystickCheckbox.addEventListener(MouseEvent.CLICK, onShowJoystickChange);
      cont.addChild(showJoystickCheckbox);
      var lbl2:TextLabel = new TextLabel(t('show_joystick'), DPI.scale(11));
      lbl2.x = showJoystickCheckbox.x + showJoystickCheckbox.width + DPI.scale(8);
      lbl2.y = showJoystickCheckbox.y + DPI.scale(2);
      cont.addChild(lbl2);
      curY += rowGap;

      showDpadCheckbox = new Checkbox();
      showDpadCheckbox.x = cbX;
      showDpadCheckbox.y = curY;
      showDpadCheckbox.addEventListener(MouseEvent.CLICK, onShowDpadChange);
      cont.addChild(showDpadCheckbox);
      var lbl3:TextLabel = new TextLabel(t('show_dpad'), DPI.scale(11));
      lbl3.x = showDpadCheckbox.x + showDpadCheckbox.width + DPI.scale(8);
      lbl3.y = showDpadCheckbox.y + DPI.scale(2);
      cont.addChild(lbl3);
      curY += rowGap;

      touchCameraCheckbox = new Checkbox();
      touchCameraCheckbox.x = cbX;
      touchCameraCheckbox.y = curY;
      touchCameraCheckbox.addEventListener(MouseEvent.CLICK, onTouchCameraChange);
      cont.addChild(touchCameraCheckbox);
      var lbl4:TextLabel = new TextLabel(t('touch_camera'), DPI.scale(11));
      lbl4.x = touchCameraCheckbox.x + touchCameraCheckbox.width + DPI.scale(8);
      lbl4.y = touchCameraCheckbox.y + DPI.scale(2);
      cont.addChild(lbl4);
      curY += rowGap;

      showTurretCheckbox = new Checkbox();
      showTurretCheckbox.x = cbX;
      showTurretCheckbox.y = curY;
      showTurretCheckbox.addEventListener(MouseEvent.CLICK, onShowTurretChange);
      cont.addChild(showTurretCheckbox);
      var lbl5:TextLabel = new TextLabel(t('show_turret_buttons'), DPI.scale(11));
      lbl5.x = showTurretCheckbox.x + showTurretCheckbox.width + DPI.scale(8);
      lbl5.y = showTurretCheckbox.y + DPI.scale(2);
      cont.addChild(lbl5);
      curY += rowGap;

      showFire2Checkbox = new Checkbox();
      showFire2Checkbox.x = cbX;
      showFire2Checkbox.y = curY;
      showFire2Checkbox.addEventListener(MouseEvent.CLICK, onShowFire2Change);
      cont.addChild(showFire2Checkbox);
      var lbl6:TextLabel = new TextLabel(t('show_fire2_button'), DPI.scale(11));
      lbl6.x = showFire2Checkbox.x + showFire2Checkbox.width + DPI.scale(8);
      lbl6.y = showFire2Checkbox.y + DPI.scale(2);
      cont.addChild(lbl6);
      curY += rowGap;

      combineSuppliesCheckbox = new Checkbox();
      combineSuppliesCheckbox.x = cbX;
      combineSuppliesCheckbox.y = curY;
      combineSuppliesCheckbox.addEventListener(MouseEvent.CLICK, onCombineSuppliesChange);
      cont.addChild(combineSuppliesCheckbox);
      var lbl7:TextLabel = new TextLabel(t('combine_supplies'), DPI.scale(11), 0x55CCFF);
      lbl7.x = combineSuppliesCheckbox.x + combineSuppliesCheckbox.width + DPI.scale(8);
      lbl7.y = combineSuppliesCheckbox.y + DPI.scale(2);
      cont.addChild(lbl7);
      curY += rowGap + DPI.scale(12);

      registerTabContainer(cont, curY);
    }

    // --- TAB 2: SIZES & OPACITY ---
    private function createTabSizes():void {
      var cont:Sprite = new Sprite();
      var cbX:Number = DPI.scale(12);
      var curY:Number = DPI.scale(8);
      var sliderWidthUnscaled:Number = 296;

      selectedButtonLabel = new TextLabel(t('button_size') + ' (' + t('all_buttons') + '): 100%', DPI.scale(11), 0xFFD700);
      selectedButtonLabel.x = cbX;
      selectedButtonLabel.y = curY;
      cont.addChild(selectedButtonLabel);

      allButtonsBtn = createMiniButton(t('all_buttons'), 0x334455);
      allButtonsBtn.x = menuW - allButtonsBtn.width - DPI.scale(14);
      allButtonsBtn.y = curY - DPI.scale(2);
      allButtonsBtn.addEventListener(MouseEvent.CLICK, onAllButtonsClick);
      cont.addChild(allButtonsBtn);

      curY += DPI.scale(18);
      buttonSizeSlider = new NormalSlider(sliderWidthUnscaled);
      buttonSizeSlider.x = cbX;
      buttonSizeSlider.y = curY;
      buttonSizeSlider.value = 0.4;
      buttonSizeSlider.addEventListener(Event.CHANGE, onButtonSizeChange);
      cont.addChild(buttonSizeSlider);
      curY += DPI.scale(22);

      joystickSizeLabel = new TextLabel(t('joystick_size') + ': 100%', DPI.scale(11));
      joystickSizeLabel.x = cbX;
      joystickSizeLabel.y = curY;
      cont.addChild(joystickSizeLabel);

      curY += DPI.scale(16);
      joystickSizeSlider = new NormalSlider(sliderWidthUnscaled);
      joystickSizeSlider.x = cbX;
      joystickSizeSlider.y = curY;
      joystickSizeSlider.value = 0.4;
      joystickSizeSlider.addEventListener(Event.CHANGE, onJoystickSizeChange);
      cont.addChild(joystickSizeSlider);
      curY += DPI.scale(22);

      buttonsAlphaLabel = new TextLabel(t('buttons_opacity') + ': 100%', DPI.scale(11));
      buttonsAlphaLabel.x = cbX;
      buttonsAlphaLabel.y = curY;
      cont.addChild(buttonsAlphaLabel);

      curY += DPI.scale(16);
      buttonsAlphaSlider = new NormalSlider(sliderWidthUnscaled);
      buttonsAlphaSlider.x = cbX;
      buttonsAlphaSlider.y = curY;
      buttonsAlphaSlider.value = 1.0;
      buttonsAlphaSlider.addEventListener(Event.CHANGE, onButtonsAlphaChange);
      cont.addChild(buttonsAlphaSlider);
      curY += DPI.scale(22);

      alphaLabel = new TextLabel(t('settings_button_opacity') + ': 100%', DPI.scale(11));
      alphaLabel.x = cbX;
      alphaLabel.y = curY;
      cont.addChild(alphaLabel);

      curY += DPI.scale(16);
      alphaSlider = new NormalSlider(sliderWidthUnscaled);
      alphaSlider.x = cbX;
      alphaSlider.y = curY;
      alphaSlider.value = 1.0;
      alphaSlider.addEventListener(Event.CHANGE, onAlphaChange);
      cont.addChild(alphaSlider);
      curY += DPI.scale(24);

      registerTabContainer(cont, curY);
    }

    // --- TAB 3: CAMERA ---
    private function createTabCamera():void {
      var cont:Sprite = new Sprite();
      var cbX:Number = DPI.scale(12);
      var curY:Number = DPI.scale(8);
      var sliderWidthUnscaled:Number = 296;

      disableVertCamCheckbox = new Checkbox();
      disableVertCamCheckbox.x = cbX;
      disableVertCamCheckbox.y = curY;
      disableVertCamCheckbox.addEventListener(MouseEvent.CLICK, onDisableVertCamChange);
      cont.addChild(disableVertCamCheckbox);
      var lblVert:TextLabel = new TextLabel(t('disable_vertical_camera'), DPI.scale(11), 0xFFA07A);
      lblVert.x = disableVertCamCheckbox.x + disableVertCamCheckbox.width + DPI.scale(8);
      lblVert.y = disableVertCamCheckbox.y + DPI.scale(2);
      cont.addChild(lblVert);
      curY += DPI.scale(26);

      sensHLabel = new TextLabel(t('camera_sens_h') + ': 100%', DPI.scale(11));
      sensHLabel.x = cbX;
      sensHLabel.y = curY;
      cont.addChild(sensHLabel);

      curY += DPI.scale(17);
      sensHSlider = new NormalSlider(sliderWidthUnscaled);
      sensHSlider.x = cbX;
      sensHSlider.y = curY;
      sensHSlider.value = 0.21;
      sensHSlider.addEventListener(Event.CHANGE, onSensHChange);
      cont.addChild(sensHSlider);
      curY += DPI.scale(23);

      sensVLabel = new TextLabel(t('camera_sens_v') + ': 100%', DPI.scale(11));
      sensVLabel.x = cbX;
      sensVLabel.y = curY;
      cont.addChild(sensVLabel);

      curY += DPI.scale(17);
      sensVSlider = new NormalSlider(sliderWidthUnscaled);
      sensVSlider.x = cbX;
      sensVSlider.y = curY;
      sensVSlider.value = 0.21;
      sensVSlider.addEventListener(Event.CHANGE, onSensVChange);
      cont.addChild(sensVSlider);
      curY += DPI.scale(25);

      registerTabContainer(cont, curY);
    }

    // --- TAB 4: CUSTOM BUTTONS ---
    private function createTabCustom():void {
      var cont:Sprite = new Sprite();
      var cbX:Number = DPI.scale(12);
      var curY:Number = DPI.scale(8);

      var titleLbl:TextLabel = new TextLabel('✦ ' + t('custom_buttons'), DPI.scale(12), 0xFFCC00);
      titleLbl.x = cbX;
      titleLbl.y = curY;
      cont.addChild(titleLbl);
      curY += DPI.scale(19);

      var quickRow:Sprite = new Sprite();
      quickRow.x = cbX;
      quickRow.y = curY;
      var qX:Number = 0;
      var presets:Array = [
        { label: 'R', key: Keyboard.R },
        { label: 'Shift', key: Keyboard.SHIFT },
        { label: 'Del', key: Keyboard.DELETE },
        { label: 'P', key: Keyboard.P },
        { label: '6', key: Keyboard.NUMBER_6 },
        { label: '7', key: Keyboard.NUMBER_7 }
      ];
      for each(var p:Object in presets) {
        var pBtn:Sprite = createMiniButton('+ ' + p.label, 0x383838);
        pBtn.x = qX;
        pBtn.addEventListener(MouseEvent.CLICK, makePresetHandler(p.label, p.key));
        quickRow.addChild(pBtn);
        qX += pBtn.width + DPI.scale(4);
      }
      cont.addChild(quickRow);
      curY += DPI.scale(32);

      // Custom input row
      var inputRow:Sprite = new Sprite();
      inputRow.x = cbX;
      inputRow.y = curY;

      customKeyInput = new TextField();
      customKeyInput.type = TextFieldType.INPUT;
      customKeyInput.maxChars = 4;
      customKeyInput.defaultTextFormat = new TextFormat('_sans', DPI.scale(12), 0xFFFFFF, true);
      customKeyInput.border = true;
      customKeyInput.borderColor = 0x666666;
      customKeyInput.background = true;
      customKeyInput.backgroundColor = 0x151515;
      customKeyInput.width = DPI.scale(48);
      customKeyInput.height = DPI.scale(23);
      inputRow.addChild(customKeyInput);

      var addBtn:Sprite = createMiniButton('➕ ' + t('add_button'), 0x236E33);
      addBtn.x = customKeyInput.x + customKeyInput.width + DPI.scale(6);
      addBtn.addEventListener(MouseEvent.CLICK, onAddCustomBtnClick);
      inputRow.addChild(addBtn);

      deleteCustomBtn = createMiniButton('🗑 ' + t('delete_button'), 0x882222);
      deleteCustomBtn.x = addBtn.x + addBtn.width + DPI.scale(6);
      deleteCustomBtn.visible = false;
      deleteCustomBtn.addEventListener(MouseEvent.CLICK, onDeleteCustomBtnClick);
      inputRow.addChild(deleteCustomBtn);

      cont.addChild(inputRow);
      curY += DPI.scale(32);

      registerTabContainer(cont, curY);
    }

    // --- TAB 5: PROFILE (IMPORT / EXPORT / RESET) ---
    private function createTabProfile():void {
      var cont:Sprite = new Sprite();
      var cbX:Number = DPI.scale(12);
      var curY:Number = DPI.scale(8);

      var rowBtns:Sprite = new Sprite();
      rowBtns.x = cbX;
      rowBtns.y = curY;

      var exportBtn:Sprite = createMiniButton('📤 ' + t('export_settings'), 0x0066AA);
      exportBtn.x = 0;
      exportBtn.addEventListener(MouseEvent.CLICK, onExportClick);
      rowBtns.addChild(exportBtn);

      var pasteBtn:Sprite = createMiniButton('📋 ' + t('paste_here'), 0x444444);
      pasteBtn.x = exportBtn.width + DPI.scale(6);
      pasteBtn.addEventListener(MouseEvent.CLICK, onPasteClipboardClick);
      rowBtns.addChild(pasteBtn);

      var applyBtn:Sprite = createMiniButton('✓ ' + t('apply'), 0x227733);
      applyBtn.x = pasteBtn.x + pasteBtn.width + DPI.scale(6);
      applyBtn.addEventListener(MouseEvent.CLICK, onApplyImportClick);
      rowBtns.addChild(applyBtn);

      cont.addChild(rowBtns);
      curY += DPI.scale(28);

      codeTextArea = new TextField();
      codeTextArea.type = TextFieldType.INPUT;
      codeTextArea.multiline = true;
      codeTextArea.wordWrap = true;
      codeTextArea.defaultTextFormat = new TextFormat('_sans', DPI.scale(9.5), 0xDDDDDD);
      codeTextArea.border = true;
      codeTextArea.borderColor = 0x555555;
      codeTextArea.background = true;
      codeTextArea.backgroundColor = 0x121212;
      codeTextArea.width = menuW - DPI.scale(24);
      codeTextArea.height = DPI.scale(64);
      codeTextArea.x = cbX;
      codeTextArea.y = curY;
      cont.addChild(codeTextArea);
      curY += DPI.scale(70);

      statusLabel = new TextLabel('', DPI.scale(10.5), 0x00FF88);
      statusLabel.x = cbX;
      statusLabel.y = curY;
      cont.addChild(statusLabel);
      curY += DPI.scale(22);

      // Reset positions button
      var resetBtn:Sprite = new Sprite();
      var resetLabel:TextLabel = new TextLabel('<u>↺ ' + t('reset_buttons_position') + '</u>', DPI.scale(11), 0x66B2FF);
      resetLabel.htmlText = resetLabel.text;
      resetLabel.mouseEnabled = false;
      resetBtn.addChild(resetLabel);
      resetBtn.x = cbX;
      resetBtn.y = curY;
      resetBtn.buttonMode = true;
      resetBtn.addEventListener(MouseEvent.CLICK, onResetButtons);
      resetBtn.addEventListener(TouchEvent.TOUCH_TAP, onResetButtons);
      cont.addChild(resetBtn);

      curY += DPI.scale(28);
      registerTabContainer(cont, curY);
    }

    private function registerTabContainer(cont:Sprite, totalHeight:Number):void {
      cont.visible = false;
      viewportHolder.addChild(cont);
      tabContainers.push(cont);

      var scrollbar:Sprite = new Sprite();
      scrollbar.x = menuW - DPI.scale(7);
      scrollbar.y = titleH + tabH + DPI.scale(2);
      addChild(scrollbar);
      scrollbars.push(scrollbar);
    }

    // --- Import / Export Handlers ---
    private function onExportClick(event:MouseEvent):void {
      var jsonStr:String = onScreenControls.exportSettingsJson();
      codeTextArea.text = jsonStr;
      try {
        Clipboard.generalClipboard.clear();
        Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, jsonStr);
        showStatus(t('copied_to_clipboard'), 0x00FF88);
      } catch(e:Error) {
        showStatus(t('copied_to_clipboard'), 0x00FF88);
      }
    }

    private function onPasteClipboardClick(event:MouseEvent):void {
      try {
        if (Clipboard.generalClipboard.hasFormat(ClipboardFormats.TEXT_FORMAT)) {
          var clip:String = Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT) as String;
          if (clip != null && clip.length > 0) {
            codeTextArea.text = clip;
          }
        }
      } catch(e:Error) {}
    }

    private function onApplyImportClick(event:MouseEvent):void {
      var code:String = codeTextArea.text;
      if (code == null || code.length == 0) return;
      var success:Boolean = onScreenControls.importSettingsJson(code);
      if (success) {
        showStatus(t('imported_success'), 0x00FF88);
      } else {
        showStatus(t('import_error'), 0xFF4444);
      }
    }

    private function showStatus(msg:String, color:uint):void {
      statusLabel.text = msg;
      statusLabel.textColor = color;
    }

    public function refreshUI():void {
      loadSettings();
    }

    private function onDisableVertCamChange(event:MouseEvent):void {
      onScreenControls.setVerticalCameraDisabled(disableVertCamCheckbox.checked);
      saveSettings();
    }

    private function makePresetHandler(lbl:String, key:uint):Function {
      return function(e:MouseEvent):void {
        onScreenControls.addCustomButton(lbl, key);
      };
    }

    private function onAddCustomBtnClick(event:MouseEvent):void {
      var raw:String = customKeyInput.text;
      if (raw == null || raw.length == 0) return;
      var clean:String = raw.toUpperCase().replace(/\s+/g, '');
      if (clean.length == 0) return;

      var keyCode:uint = clean.charCodeAt(0);
      if (clean == 'SHIF' || clean == 'SHFT') keyCode = Keyboard.SHIFT;
      else if (clean == 'DEL') keyCode = Keyboard.DELETE;
      else if (clean == 'ENT') keyCode = Keyboard.ENTER;
      else if (clean == 'SPC') keyCode = Keyboard.SPACE;

      onScreenControls.addCustomButton(clean, keyCode);
      customKeyInput.text = '';
    }

    private function onDeleteCustomBtnClick(event:MouseEvent):void {
      if (selectedElement is ControlButton) {
        var btn:ControlButton = selectedElement as ControlButton;
        if (btn.isCustom) {
          onScreenControls.removeCustomButton(btn);
        }
      }
    }

    private function onAllButtonsClick(event:MouseEvent):void {
      onScreenControls.selectElement(null);
    }

    public function onElementSelected(element:Sprite):void {
      selectedElement = element;
      if (element is ControlButton) {
        var btn:ControlButton = element as ControlButton;
        var btnName:String = btn.getLabel();
        if (btnName == 'COMBINED_234') btnName = '2+3+4';
        selectedButtonLabel.text = t('selected_button') + ' [' + btnName + ']: ' + Math.round(btn.getScale() * 100) + '%';
        buttonSizeSlider.value = (btn.getScale() - 0.5) / 1.5;
        deleteCustomBtn.visible = btn.isCustom;
      } else if (element is VirtualJoystick) {
        selectedButtonLabel.text = t('show_joystick') + ': ' + Math.round(joystickSizeSlider.value * 100 + 60) + '%';
        deleteCustomBtn.visible = false;
      } else {
        selectedButtonLabel.text = t('button_size') + ' (' + t('all_buttons') + '): ' + Math.round((0.6 + buttonSizeSlider.value * 1.0) * 100) + '%';
        deleteCustomBtn.visible = false;
      }
    }

    // --- Scrolling Logic ---
    private function onMouseWheel(event:MouseEvent):void {
      scrollBy(-event.delta * DPI.scale(16));
    }

    private function onContentMouseDown(event:MouseEvent):void {
      if (isInteractiveChild(event.target as DisplayObject)) return;
      startScrolling(mouseY);
    }

    private function onContentTouchBegin(event:TouchEvent):void {
      if (isInteractiveChild(event.target as DisplayObject)) return;
      var pt:Point = globalToLocal(new Point(event.stageX, event.stageY));
      startScrolling(pt.y);
    }

    private function isInteractiveChild(target:DisplayObject):Boolean {
      var curr:DisplayObject = target;
      while (curr != null && curr != viewportHolder && curr != this) {
        if (curr is NormalSlider || curr is Checkbox || curr == customKeyInput || curr == codeTextArea || curr == allButtonsBtn) {
          return true;
        }
        curr = curr.parent;
      }
      return false;
    }

    private function startScrolling(startY:Number):void {
      isScrolling = true;
      scrollStartMouseY = startY;
      scrollStartScrollY = scrollY;
      if (stage != null) {
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageScrollMove);
        stage.addEventListener(MouseEvent.MOUSE_UP, onStageScrollEnd);
        stage.addEventListener(TouchEvent.TOUCH_MOVE, onStageTouchScrollMove);
        stage.addEventListener(TouchEvent.TOUCH_END, onStageTouchScrollEnd);
      }
    }

    private function onStageScrollMove(event:MouseEvent):void {
      if (isScrolling) {
        var dy:Number = mouseY - scrollStartMouseY;
        setScrollY(scrollStartScrollY - dy);
      }
    }

    private function onStageTouchScrollMove(event:TouchEvent):void {
      if (isScrolling) {
        var pt:Point = globalToLocal(new Point(event.stageX, event.stageY));
        var dy:Number = pt.y - scrollStartMouseY;
        setScrollY(scrollStartScrollY - dy);
      }
    }

    private function onStageScrollEnd(event:MouseEvent):void {
      stopScrolling();
    }

    private function onStageTouchScrollEnd(event:TouchEvent):void {
      stopScrolling();
    }

    private function stopScrolling():void {
      if (!isScrolling) return;
      isScrolling = false;
      if (stage != null) {
        stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageScrollMove);
        stage.removeEventListener(MouseEvent.MOUSE_UP, onStageScrollEnd);
        stage.removeEventListener(TouchEvent.TOUCH_MOVE, onStageTouchScrollMove);
        stage.removeEventListener(TouchEvent.TOUCH_END, onStageTouchScrollEnd);
      }
    }

    private function scrollBy(delta:Number):void {
      setScrollY(scrollY + delta);
    }

    private function setScrollY(newY:Number):void {
      if (activeScrollContainer == null) return;
      var totalH:Number = activeScrollContainer.height;
      maxScroll = Math.max(0, totalH - viewportH);
      scrollY = Math.max(0, Math.min(maxScroll, newY));
      updateScroll();
    }

    private function updateScroll():void {
      if (activeScrollContainer == null) return;
      var totalH:Number = activeScrollContainer.height;
      maxScroll = Math.max(0, totalH - viewportH);
      activeScrollContainer.scrollRect = new Rectangle(0, scrollY, menuW - DPI.scale(10), viewportH);

      if (currentTabIndex < scrollbars.length) {
        var sb:Sprite = scrollbars[currentTabIndex];
        sb.graphics.clear();
        if (maxScroll > 0) {
          sb.visible = true;
          // Track
          sb.graphics.beginFill(0x333333, 0.6);
          sb.graphics.drawRoundRect(0, 0, DPI.scale(4), viewportH, DPI.scale(2), DPI.scale(2));
          sb.graphics.endFill();

          // Thumb
          var thumbH:Number = Math.max(DPI.scale(18), (viewportH / totalH) * viewportH);
          var ratio:Number = scrollY / maxScroll;
          var thumbY:Number = ratio * (viewportH - thumbH);
          sb.graphics.beginFill(0x888888, 0.9);
          sb.graphics.drawRoundRect(0, thumbY, DPI.scale(4), thumbH, DPI.scale(2), DPI.scale(2));
          sb.graphics.endFill();
        } else {
          sb.visible = false;
        }
      }
    }

    // --- Window Dragging ---
    private function onTitleBarDown(event:MouseEvent):void {
      startMenuDrag();
    }

    private function onTitleBarTouchDown(event:TouchEvent):void {
      startMenuDrag();
    }

    private function startMenuDrag():void {
      if (isDraggingMenu) return;
      isDraggingMenu = true;
      startDrag();
      if (stage != null) {
        stage.addEventListener(MouseEvent.MOUSE_UP, onTitleBarUp);
        stage.addEventListener(TouchEvent.TOUCH_END, onTitleBarTouchUp);
      }
    }

    private function onTitleBarTouchUp(event:TouchEvent):void {
      stopMenuDrag();
    }

    private function onTitleBarUp(event:MouseEvent):void {
      stopMenuDrag();
    }

    private function stopMenuDrag():void {
      if (!isDraggingMenu) return;
      isDraggingMenu = false;
      stopDrag();
      if (stage != null) {
        stage.removeEventListener(MouseEvent.MOUSE_UP, onTitleBarUp);
        stage.removeEventListener(TouchEvent.TOUCH_END, onTitleBarTouchUp);
      }
      if (onScreenControls != null) {
        onScreenControls.savePositions();
      }
    }

    private function onCloseClick(event:Event):void {
      var now:int = getTimer();
      if (now - lastCloseTime < 250) {
        return;
      }
      lastCloseTime = now;
      if (onScreenControls != null) {
        onScreenControls.toggleSettings();
      }
    }

    private function onShowControlsChange(event:MouseEvent):void {
      onScreenControls.setControlsEnabled(showControlsCheckbox.checked);
      saveSettings();
    }

    private function onShowJoystickChange(event:MouseEvent):void {
      onScreenControls.setJoystickEnabled(showJoystickCheckbox.checked);
      saveSettings();
    }

    private function onShowDpadChange(event:MouseEvent):void {
      onScreenControls.setDpadEnabled(showDpadCheckbox.checked);
      saveSettings();
    }

    private function onTouchCameraChange(event:MouseEvent):void {
      onScreenControls.setTouchCameraEnabled(touchCameraCheckbox.checked);
      saveSettings();
    }

    private function onShowTurretChange(event:MouseEvent):void {
      onScreenControls.setTurretButtonsEnabled(showTurretCheckbox.checked);
      saveSettings();
    }

    private function onShowFire2Change(event:MouseEvent):void {
      onScreenControls.setFire2Enabled(showFire2Checkbox.checked);
      saveSettings();
    }

    private function onCombineSuppliesChange(event:MouseEvent):void {
      onScreenControls.setCombineSupplies(combineSuppliesCheckbox.checked);
      saveSettings();
    }

    private function onButtonSizeChange(event:Event):void {
      if (selectedElement is ControlButton) {
        var singleScale:Number = 0.5 + buttonSizeSlider.value * 1.5;
        var btn:ControlButton = selectedElement as ControlButton;
        onScreenControls.setSingleButtonScale(btn, singleScale);
        var lbl:String = btn.getLabel();
        if (lbl == 'COMBINED_234') lbl = '2+3+4';
        selectedButtonLabel.text = t('selected_button') + ' [' + lbl + ']: ' + Math.round(singleScale * 100) + '%';
      } else {
        var scale:Number = 0.6 + buttonSizeSlider.value * 1.0;
        selectedButtonLabel.text = t('button_size') + ' (' + t('all_buttons') + '): ' + Math.round(scale * 100) + '%';
        onScreenControls.setButtonScale(scale);
      }
      saveSettings();
    }

    private function onJoystickSizeChange(event:Event):void {
      var scale:Number = 0.6 + joystickSizeSlider.value * 1.0;
      joystickSizeLabel.text = t('joystick_size') + ': ' + Math.round(scale * 100) + '%';
      onScreenControls.setJoystickScale(scale);
      saveSettings();
    }

    private function onButtonsAlphaChange(event:Event):void {
      var a:Number = 0.15 + buttonsAlphaSlider.value * 0.85;
      buttonsAlphaLabel.text = t('buttons_opacity') + ': ' + Math.round(a * 100) + '%';
      onScreenControls.setButtonsAlpha(a);
      saveSettings();
    }

    private function onSensHChange(event:Event):void {
      var mult:Number = 0.2 + sensHSlider.value * 3.8;
      sensHLabel.text = t('camera_sens_h') + ': ' + Math.round(mult * 100) + '%';
      onScreenControls.setCameraSensH(mult);
      saveSettings();
    }

    private function onSensVChange(event:Event):void {
      var mult:Number = 0.2 + sensVSlider.value * 3.8;
      sensVLabel.text = t('camera_sens_v') + ': ' + Math.round(mult * 100) + '%';
      onScreenControls.setCameraSensV(mult);
      saveSettings();
    }

    private function onAlphaChange(event:Event):void {
      var newAlpha:Number = alphaSlider.value;
      settingsButton.alpha = newAlpha;
      alphaLabel.text = t('settings_button_opacity') + ': ' + Math.round(newAlpha * 100) + '%';
      saveSettings();
    }

    private function onResetButtons(event:Event):void {
      onScreenControls.resetPositions();

      buttonSizeSlider.value = 0.4;
      selectedButtonLabel.text = t('button_size') + ' (' + t('all_buttons') + '): 100%';
      onScreenControls.setButtonScale(1.0);

      joystickSizeSlider.value = 0.4;
      joystickSizeLabel.text = t('joystick_size') + ': 100%';
      onScreenControls.setJoystickScale(1.0);

      buttonsAlphaSlider.value = 1.0;
      buttonsAlphaLabel.text = t('buttons_opacity') + ': 100%';
      onScreenControls.setButtonsAlpha(1.0);

      sensHSlider.value = 0.21;
      sensHLabel.text = t('camera_sens_h') + ': 100%';
      onScreenControls.setCameraSensH(1.0);

      sensVSlider.value = 0.21;
      sensVLabel.text = t('camera_sens_v') + ': 100%';
      onScreenControls.setCameraSensV(1.0);

      disableVertCamCheckbox.checked = false;
      onScreenControls.setVerticalCameraDisabled(false);

      showStatus(t('reset_buttons_position'), 0x66B2FF);
      saveSettings();
    }

    private function loadSettings():void {
      var storage:SharedObject = SharedObject.getLocal('storage');
      var showControls:Boolean = storage.data.showControls ?? true;
      var showJoystick:Boolean = storage.data.showJoystick ?? true;
      var showDpad:Boolean = storage.data.showDpad ?? false;
      var touchCamera:Boolean = storage.data.touchCamera ?? true;
      var showTurret:Boolean = storage.data.showTurretButtons ?? true;
      var showFire2:Boolean = storage.data.showFire2 ?? true;
      var combineSupplies:Boolean = storage.data.combineSupplies ?? false;
      var disableVertCam:Boolean = storage.data.disableVerticalCamera ?? false;

      showControlsCheckbox.checked = showControls;
      showJoystickCheckbox.checked = showJoystick;
      showDpadCheckbox.checked = showDpad;
      touchCameraCheckbox.checked = touchCamera;
      showTurretCheckbox.checked = showTurret;
      showFire2Checkbox.checked = showFire2;
      combineSuppliesCheckbox.checked = combineSupplies;
      disableVertCamCheckbox.checked = disableVertCam;

      var btnScale:Number = storage.data.buttonScale ?? 1.0;
      var joyScale:Number = storage.data.joystickScale ?? 1.0;
      var bAlpha:Number = storage.data.buttonsAlpha ?? 1.0;
      var sensH:Number = storage.data.cameraSensH ?? 1.0;
      var sensV:Number = storage.data.cameraSensV ?? 1.0;

      buttonSizeSlider.value = (btnScale - 0.6) / 1.0;
      selectedButtonLabel.text = t('button_size') + ' (' + t('all_buttons') + '): ' + Math.round(btnScale * 100) + '%';
      onScreenControls.setButtonScale(btnScale);

      joystickSizeSlider.value = (joyScale - 0.6) / 1.0;
      joystickSizeLabel.text = t('joystick_size') + ': ' + Math.round(joyScale * 100) + '%';
      onScreenControls.setJoystickScale(joyScale);

      buttonsAlphaSlider.value = (bAlpha - 0.15) / 0.85;
      buttonsAlphaLabel.text = t('buttons_opacity') + ': ' + Math.round(bAlpha * 100) + '%';
      onScreenControls.setButtonsAlpha(bAlpha);

      sensHSlider.value = (sensH - 0.2) / 3.8;
      sensHLabel.text = t('camera_sens_h') + ': ' + Math.round(sensH * 100) + '%';
      onScreenControls.setCameraSensH(sensH);

      sensVSlider.value = (sensV - 0.2) / 3.8;
      sensVLabel.text = t('camera_sens_v') + ': ' + Math.round(sensV * 100) + '%';
      onScreenControls.setCameraSensV(sensV);

      onScreenControls.setTurretButtonsEnabled(showTurret);
      onScreenControls.setFire2Enabled(showFire2);
      onScreenControls.setTouchCameraEnabled(touchCamera);
      onScreenControls.setJoystickEnabled(showJoystick);
      onScreenControls.setDpadEnabled(showDpad);
      onScreenControls.setCombineSupplies(combineSupplies);
      onScreenControls.setVerticalCameraDisabled(disableVertCam);
      onScreenControls.setControlsEnabled(showControls);

      if (storage.data.settingButtonAlpha != undefined) {
        alphaSlider.value = storage.data.settingButtonAlpha;
        settingsButton.alpha = alphaSlider.value;
        alphaLabel.text = t('settings_button_opacity') + ': ' + Math.round(alphaSlider.value * 100) + '%';
      }
    }

    private function saveSettings():void {
      var storage:SharedObject = SharedObject.getLocal('storage');
      storage.data.showControls = showControlsCheckbox.checked;
      storage.data.showJoystick = showJoystickCheckbox.checked;
      storage.data.showDpad = showDpadCheckbox.checked;
      storage.data.touchCamera = touchCameraCheckbox.checked;
      storage.data.showTurretButtons = showTurretCheckbox.checked;
      storage.data.showFire2 = showFire2Checkbox.checked;
      storage.data.combineSupplies = combineSuppliesCheckbox.checked;
      storage.data.disableVerticalCamera = disableVertCamCheckbox.checked;
      storage.data.buttonScale = 0.6 + buttonSizeSlider.value * 1.0;
      storage.data.joystickScale = 0.6 + joystickSizeSlider.value * 1.0;
      storage.data.buttonsAlpha = 0.15 + buttonsAlphaSlider.value * 0.85;
      storage.data.cameraSensH = 0.2 + sensHSlider.value * 3.8;
      storage.data.cameraSensV = 0.2 + sensVSlider.value * 3.8;
      storage.data.settingButtonAlpha = alphaSlider.value;
      storage.flush();
    }

    private function createMiniButton(text:String, color:uint = 0x383838):Sprite {
      var btn:Sprite = new Sprite();
      var lbl:TextLabel = new TextLabel(text, DPI.scale(10.5), 0xFFFFFF);
      var w:Number = lbl.width + DPI.scale(14);
      var h:Number = DPI.scale(22);
      btn.graphics.beginFill(color, 0.95);
      btn.graphics.lineStyle(DPI.scale(1), 0x666666, 0.8);
      btn.graphics.drawRoundRect(0, 0, w, h, DPI.scale(5), DPI.scale(5));
      btn.graphics.endFill();
      lbl.x = (w - lbl.width) / 2;
      lbl.y = (h - lbl.height) / 2;
      btn.addChild(lbl);
      btn.buttonMode = true;
      btn.mouseChildren = false;
      return btn;
    }

  }
}
