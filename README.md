<a id="top"></a>

# External iOS App

<p align="center">
  <a href="#english">English</a> |
  <a href="#russian">Русский</a>
</p>

---

<a id="english"></a>

## English

[Switch to Russian](#russian)

Archived Objective-C++ / Theos project for [TrollStore](https://github.com/opa334/TrollStore) iOS devices.

### Overview

This is an experimental low-level iOS project with a full-screen UI overlay, a mod menu, runtime helpers, and a build pipeline based on Theos. The codebase was originally mixed with Swift and SwiftUI, but was later fully rewritten in Objective-C++, C++, UIKit, Metal, and ImGui, since that made it more convenient to use private iOS frameworks and integrate C code.

This repository is published primarily as an archive and a technical reference. It is obviously not intended for App Store distribution and similar use cases.

### Credits

- notsofter
- scared

### Highlights

- Objective-C++ codebase and use of low-level dependencies
- Custom UI overlay on top of all of SpringBoard and a mod menu
- Custom UI components: switches, sliders, scroll, and segmented controls
- Rendering integration through Metal and ImGui
- Runtime memory helpers and code tailored for different device versions
- Build-time Objective-C symbol obfuscation
- `.tipa` build process based on Theos

### Demo

[demo.mp4](assets/demo.mp4)

### Project Structure

- `src/App` - application lifecycle and main screens
- `src/HUD` - full-screen overlay window, rendering, and interaction layer
- `src/Menu` - UI components for the mod menu
- `src/Helpers` - device, version, exploit, and other helper utilities
- `src/Cheat` - functionality used by the menu
- `dependencies` - low-level dependencies, copied from other projects
- `tools` - build and obfuscation tooling

### Build

#### Requirements

- Theos
- iOS toolchain with Objective-C / Objective-C++ support
- A device with the [TrollStore](https://github.com/opa334/TrollStore) (A9-A17/M1-M2, iOS 14 - 16.7 and 17.0, exact compatibility information is available on the developer's website)

#### Command

Inside the project directory:

```sh
make clean package
```

### Status

This project is archived. I no longer actively maintain it and I am publishing it in its current form as a reference, a learning resource, and a starting point that other developers can build on if they want to.

### History

This project was originally developed for a well-known project in the summer of 2024.

At the time, we had this idea for quite a while and worked on it mainly for experience and interest, especially after seeing another developer implement a similar idea faster than we did. Later, I decided to publish the project because that stage is already over for me, serious disagreements arose around the people managing the related community and the Telegram group chat, and the code quality itself leaves plenty of room for improvement by other developers.

I have outgrown this kind of work, and I am no longer interested in continuing it.

### Notes

- This code targets jailbreak / [TrollStore](https://github.com/opa334/TrollStore) and uses private APIs.
- The repository should be treated as experimental; some code has been removed, so it is not intended for a production release.
- If someone wants to improve it, it will require serious cleanup, refactoring, and better architectural separation between project parts.

[Back to top](#top)

---

<a id="russian"></a>

## Русский

[Switch to English](#english)

Архивный проект на Objective-C++ / Theos для [TrollStore](https://github.com/opa334/TrollStore) iOS устройств.

### Обзор

Это экспериментальный низкоуровневый iOS проект, где есть UI поверх всего экрана, мод меню, runtime хелперов и сборка на платформе Theos. Кодовая база изначально была смешана с Swift, SwiftUI, но после была полностью переписана на Objective-C++, C++, UIKit, Metal, ImGui, так как удобно использовать приватные iOS фреймворки и интегрировать Си код.

Этот репозиторий опубликован в первую очередь как архив и технический референс. Он само собой не предназначен для распространения через App Store и т.д.

### Кредиты

- notsofter
- scared

### Основные особенности

- Кодовая база на Objective-C++ и использование низкоуровневых зависимостей
- Собственный UI поверх всего Springboard и мод меню
- Кастомные UI компоненты: switches, sliders, scroll и segmented controls
- Интеграция рендера через Metal, ImGui
- Runtime memory helpers и код с учетом разных версий устройств
- Обфускация Objective-C-символов на этапе сборки
- Процесс сборки .tipa на основе Theos

### Демонстрация
[demo.mp4](assets/demo.mp4)

### Структура проекта

- `src/App` - жизненный цикл приложения и основные экраны
- `src/HUD` - overlay окно поверх всего экрана, рендер и слой взаимодействия
- `src/Menu` - UI компоненты мод меню
- `src/Helpers` - device, version, exploit и другие вспомогательные утилиты
- `src/Cheat` - функционал для меню
- `dependencies` - низкоуровневые зависимости, копипаста с других проектов
- `tools` - инструменты сборки и обфускации

### Сборка

#### Требования

- Theos
- iOS toolchain с поддержкой Objective-C / Objective-C++
- Устройство с установщиком приложений [TrollStore](https://github.com/opa334/TrollStore) (A9-A17/M1-M2, iOS 14 - 16.7 и 17.0, точная информация на сайте разработчика)

#### Команда
Внутри директории проекта:
```sh
make clean package
```

### Статус

Проект архивный. Я больше его активно не поддерживаю и публикую в текущем виде как референс, материал для изучения и точку, от которой другие разработчики при своем желании могут оттолкнуться.

### История проекта

Изначально этот проект разрабатывался для известного проекта еще летом 2024 года.

На тот момент у нас была давняя идея и мы делали его в первую очередь ради опыта и интереса, особенно после того, как увидели, что другой разработчик смог реализовать похожую идею быстрее нас. Позже я решил выложить этот проект, потому что этот этап для меня уже закончен, вокруг людей, управлявших связанным с ним сообществом и групповым чатом в телеграм, возникли серьезные разногласия, а качество самого кода оставляет много пространства для доработки со стороны других разработчиков.

Сейчас я уже вырос из такого рода работы, и продолжать этим заниматься мне неинтересно.

### Примечания

- Этот код рассчитан на jailbreak / [TrollStore](https://github.com/opa334/TrollStore) и использует приватные API.
- Репозиторий стоит воспринимать как экспериментальный, некоторый код вырезан поэтому не предназначен для прод релиза.
- Если кто-то захочет его улучшать, здесь потребуется серьезная чистка, рефакторинг и лучшая архитектурная изоляция частей проекта.

[Наверх](#top)
