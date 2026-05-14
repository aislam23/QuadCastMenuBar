[English](README.md) | Русский

# QuadCast RGB

<img src="assets/icon.png" width="128" alt="QuadCast RGB icon" align="right">

Управляй подсветкой HyperX QuadCast S прямо из строки меню macOS — без лишних приложений и без HyperX NGENUITY.

> Требуется macOS 14 Sonoma или новее.

---

## Возможности

- **10 цветовых пресетов** — красный, оранжевый, жёлтый, зелёный, голубой, синий, фиолетовый, розовый, белый, выкл
- **Произвольный цвет** через системный color picker
- **5 режимов подсветки** — Solid, Blink, Cycle, Wave, Lightning
- **Яркость** — регулировка от 0 до 100%
- **Секции** — управляй верхней, нижней или всей подсветкой сразу
- **Автоприменение** — настройки применяются при подключении микрофона и пробуждении Mac
- **Запуск при старте** — опциональный автозапуск вместе с системой
- **Запоминает настройки** между запусками

![Screenshot](assets/screenshot.png)

---

## Установка

### Через Homebrew (рекомендуется)

```bash
brew tap aislam23/tap
brew install --cask quadcast-menubar
```

### Вручную

Скачай последний `.zip` со [страницы релизов](https://github.com/aislam23/QuadCastMenuBar/releases), распакуй и перенеси `QuadCastMenuBar.app` в папку `/Applications`.

---

## Использование

После запуска в строке меню появится иконка микрофона:

- **`mic.fill`** — микрофон подключён
- **`mic.slash`** — микрофон не найден

Кликни по иконке, чтобы открыть панель управления. Изменения применяются мгновенно.

---

## Сборка из исходников

**Требования:** macOS 14+, Xcode Command Line Tools

```bash
xcode-select --install   # если ещё не установлено
```

```bash
git clone https://github.com/aislam23/QuadCastMenuBar.git
cd QuadCastMenuBar
./build.sh
```

Готовый бандл появится в `build/QuadCastMenuBar.app`.

**Сборка с подписью Developer ID:**

```bash
SIGN_IDENTITY="Developer ID Application: Имя (TEAMID)" ./build.sh
```

---

## Структура проекта

| Файл | Назначение |
|------|-----------|
| `Sources/QuadCastMenuBarApp.swift` | Точка входа, `MenuBarExtra` |
| `Sources/ContentView.swift` | UI панели управления |
| `Sources/AppState.swift` | Состояние приложения, цветовые пресеты |
| `Sources/QuadCastService.swift` | Запуск `quadcastrgb`, управление процессом |
| `Sources/USBDeviceMonitor.swift` | Отслеживание подключения/отключения USB |
| `Sources/SystemEventMonitor.swift` | Реакция на пробуждение Mac |
| `Resources/Info.plist` | Метаданные бандла |
| `Resources/entitlements.plist` | Entitlements для hardened runtime |
| `build.sh` | Скрипт сборки |

---

## Лицензия

MIT © [Artem Islamov](https://github.com/aislam23)

Приложение включает [`quadcastrgb`](https://github.com/Ors1mer/QuadcastRGB) © Ors1mer, распространяется под [GNU GPL v2.0](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html). Подробности — в файле [NOTICES](NOTICES).
