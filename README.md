# ProTankiAndroid - Fork with internal controls

![Logo](icons/icon_96.png)
[![Version Badge](https://img.shields.io/github/v/release/ArSiFoX/protanki-android?style=plastic)](https://github.com/ArSiFoX/protanki-android/releases/latest)

Launcher to start [ProTanki](https://pro-tanki.online) on Android devices using Adobe AIR.

Forked from https://github.com/pngdrift/protanki-android/blob/main/LICENSE

[!NOTE]
This fork includes an on-screen keyboard, allowing you to play battles directly on Android devices without a physical keyboard.

You can also connect a gamepad and use the control mapping below.
## 🎮 Gamepad Controls Mapping

| Action              | Gamepad Button           |
|---------------------|--------------------------|
| Move tank forward   | D-Pad Up                 |
| Move tank backward  | D-Pad Down               |
| Turn tank left      | D-Pad Left               |
| Turn tank right     | D-Pad Right              |
| Shoot               | Right Trigger (RT / R2)  |
| Rotate turret left  | Right Stick Left         |
| Rotate turret right | Right Stick Right        |
| Center turret       | Right Stick Click (R3)   |
| Move camera up      | Right Stick Up           |
| Move camera down    | Right Stick Down         |
| Use First Aid       | Left Bumper (LB / L1)    |
| Use Double Armor    | Y / Triangle             |
| Use Double Damage   | A / Cross                |
| Use Nitro           | B / Circle               |
| Drop Mine           | X / Square               |
| Drop Flag           | Right Bumper (RB / R1)   |
| Self-destruct       | Left Trigger (LT / L2)   |
| View the statistics | Select                   |

## 📱 Minimum System Requirements

- **Android version**: 5.1 or higher
- **RAM**: 1 GB  
- **Storage**: 400 MB available space

## 📲 Download

Download the latest APK from the [Releases](https://github.com/ArSiFoX/protanki-android/releases/latest) page.

## 🛠️ Building from source

### Prerequisites
- Download and install [AIR SDK](https://airsdk.dev/docs/basics/getting-started).
- Install [asconfigc](https://github.com/BowlerHatLLC/asconfigc/blob/main/README.md).
- Generate a certificate (see [certs/README.md](certs/README.md)).

### Build
Use the following command to build APK:
```
asconfigc --sdk-path %AIR_HOME% --air android
```

You will be prompted for the certificate password during the build process.

================================================================================================================================================================

# ProTankiAndroid — форк с экранной клавиатурой

![Logo](icons/icon_96.png)

Лаунчер для запуска [ProTanki](https://pro-tanki.online) на Android-устройствах с использованием Adobe AIR.

> [!NOTE]
> Этот форк включает **экранную клавиатуру**, которая позволяет играть в бои непосредственно на Android-устройстве без использования физической клавиатуры.
>
> Также можно подключить геймпад и использовать его для управления игрой.

## 📱 Экранная клавиатура

Клиент включает встроенную **экранную клавиатуру**, специально предназначенную для игры в ProTanki на устройствах с сенсорным экраном.

Она предоставляет виртуальные кнопки для основных игровых действий, позволяя полностью управлять игрой с помощью сенсорного экрана.

## 🎮 Поддержка геймпада

Клиент поддерживает управление с помощью геймпада.

Доступны основные действия: управление движением танка, поворотом башни и камерой, стрельба, использование расходников, сброс мины и флага, самоуничтожение и просмотр статистики.

## 📱 Минимальные системные требования

- **Версия Android**: 5.1 или выше
- **Оперативная память**: 1 ГБ
- **Свободное место**: 400 МБ

## 📲 Скачать

Скачайте последнюю версию APK со страницы [Releases](https://github.com/pngdrift/protanki-android/releases/latest).

## 🛠️ Сборка из исходного кода

### Требования

- Установите [AIR SDK](https://airsdk.dev/docs/basics/getting-started).
- Установите [asconfigc](https://github.com/BowlerHatLLC/asconfigc/blob/main/README.md).
- Создайте сертификат для подписи приложения (см. [certs/README.md](certs/README.md)).

### Сборка

Для сборки APK выполните команду:

```bash
asconfigc --sdk-path %AIR_HOME% --air android
```

Во время сборки потребуется ввести пароль от сертификата.
