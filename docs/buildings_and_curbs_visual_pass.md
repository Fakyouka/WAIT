# WAIT — оформление зданий и бордюров

Выполнено 6 сентября 2026 на Godot 4.7.2.stable.steam.ed1daf0bf.

## Результат

- Существующие `Build_Shop1`, `Build2`, `Build3`, `Build4`, `Build6`, `Build7`, `Build8` оставлены основными объёмами. Их имена и родитель `WorldViewport/Location/Buldings` сохранены.
- Для каждого объёма добавлена дочерняя сцена `Visuals` с оформлением четырёх сторон. Это сохранённая статическая геометрия; генераторов и новых игровых скриптов в runtime нет.
- Дома получили штукатурку или кирпич, цоколи, карнизы, окна, подоконники, выборочные балконы, входные двери с козырьками, водостоки и небольшие технические блоки.
- Около 24% жилых окон имеют тёплое или нейтральное свечение. Рисунок включённых окон отличается между зданиями, сторонами и этажами. Для света используются отдельные материалы с emission-масками; тёмные рамы исключены из масок. Энергия тёплых окон — 0.65, нейтральных — 0.38.
- Магазин «РЯДОМ»: четыре широкие витрины, двойная стеклянная дверь, ручки, зелёная панель с вывеской, светлые фасадные панели, красная полоса и небольшие объявления, козырёк, табличка «24», боковые окна и служебная дверь. Вывески — Label3D с Nearest-фильтрацией, без брендового логотипа.
- Цвета магазина: зелёный RGB (0.12, 0.31, 0.23), светлый кремовый (0.78, 0.79, 0.72), приглушённый красный (0.53, 0.16, 0.14). Витрины используют emission 0.85. Материалы фасадов имеют слабую имитацию рассеянного света через emission 0.16; панель вывески — 0.9 с тёмным зелёным цветом. Это помогает читать детали в утверждённом ночном освещении.
- Добавлен ровно один OmniLight3D у входа: энергия 0.65, радиус 5 м, тёплый цвет, без теней. На жилых окнах дополнительных источников света нет.
- Все шесть MeshInstance3D в `Curbs` используют обновлённый общий материал: пиксельный бетон 64×64, проекция в мировых координатах, стыки через 1.2 м шириной 0.018 м, roughness 0.78. На длинных участках текстура сохраняет масштаб. Короткие возвраты используют тот же материал.
- Все 11 новых PNG имеют размер 64×64. Импорт — lossless, без mipmaps и автоматического переключения в VRAM compression; материалы и шейдер используют Nearest.

## Сохранность проекта

Сопоставлены все 240 исходных секций узлов и sub-resource в `main.tscn` с копией до работы: сохранены все исходные свойства, кроме добавленного назначения материалов семи зданий. Исходные Transform, размеры BoxMesh, layout улицы, игрок, камера, дорога, бордюры, остановка, доска, деревья, заборы и фонари не изменены. Новые элементы фасадов добавлены дочерними узлами.

Пользовательские незакоммиченные изменения в `main.tscn` сохранены. SHA-256 файлов `resources/environments/wait_night_rain.tres` и `scenes/weather/night_rain.tscn` совпадает с началом работы. Погода, звук, трафик и игровой ввод не изменялись. `project.godot` не имеет содержательных изменений. `.godot` вручную не редактировалась. Commit и push не выполнялись.

## Проверка

- Финальная headless-загрузка редактора завершилась с кодом 0; ошибок разбора GDScript, шейдера и новых ресурсов не обнаружено.
- Игра запущена через F5 в открытом редакторе; проверен вид из камеры сидящего игрока. Счётчики ошибок и предупреждений редактора при запуске — 0.
- Отдельно получены реальные GPU-кадры из Camera3D игрока вперёд, при наклоне вниз и поворотах влево/вправо. Проверены вывеска, окна, отсутствие пересвета ночной сцены, сочетание с окружением.
- Проверен светлый режим с существующим `wait_overcast_evening.tres` во временном процессе. Для отдельного крупного плана бордюра камера перемещалась только в одноразовом проверочном процессе; эти изменения не сохранялись.
- Автоматическая сверка подтвердила 7 сцен оформления, 11 текстур 64×64, корректные настройки импорта, существование ссылок на ресурсы и ровно один новый источник света.
- `git diff --check` прошёл.

Ограничения проверки: консольный запуск в sandbox выводит системные ошибки чтения хранилища сертификатов и сохранения настроек Steam-редактора в Program Files. GPU-проверка также сообщала о невозможности записи shader cache; при закрытии временного процесса со сменой окружения были два сообщения об утечке текстур окружения. Это не чистый консольный лог, хотя загрузка и рендер завершились успешно; штатный запуск из редактора не показал ошибок. Длительный игровой прогон, экспорт и измерение производительности на слабом GPU не проводились.

## Все файлы этой задачи

Пути ниже относительно корня WAIT. Существующие пользовательские изменения в погоде перечислены выше и не входят в изменения этой задачи.

| Файл | Статус и назначение |
|---|---|
| `scenes/main/main.tscn` | Изменён: назначены материалы и подключены семь дочерних сцен Visuals. |
| `resources/materials/environment/curb.tres` | Изменён: бетонная текстура и шейдер стыков вместо однотонного материала. |
| `shaders/curb.gdshader` | Создан: масштаб бетона и стыков в мировых координатах. |
| `shaders/curb.gdshader.uid` | Создан Godot: стабильный идентификатор шейдера. |
| `scenes/environment/buildings/build_2_visuals.tscn` | Создана: статические детали фасадов соответствующего исходного здания. |
| `scenes/environment/buildings/build_3_visuals.tscn` | Создана: статические детали фасадов соответствующего исходного здания. |
| `scenes/environment/buildings/build_4_visuals.tscn` | Создана: статические детали фасадов соответствующего исходного здания. |
| `scenes/environment/buildings/build_6_visuals.tscn` | Создана: статические детали фасадов соответствующего исходного здания. |
| `scenes/environment/buildings/build_7_visuals.tscn` | Создана: статические детали фасадов соответствующего исходного здания. |
| `scenes/environment/buildings/build_8_visuals.tscn` | Создана: статические детали фасадов соответствующего исходного здания. |
| `scenes/environment/buildings/build_shop_1_visuals.tscn` | Создана: статические детали фасадов соответствующего исходного здания. |
| `resources/materials/environment/buildings/brick_clay.tres` | Создан: кирпич. |
| `resources/materials/environment/buildings/concrete_trim.tres` | Создан: бетонные карнизы и подоконники. |
| `resources/materials/environment/buildings/dark_metal.tres` | Создан: металл, двери и технические детали. |
| `resources/materials/environment/buildings/entrance_light.tres` | Создан: световые полосы и плафоны. |
| `resources/materials/environment/buildings/plaster_sage.tres` | Создан: приглушённая серо-зелёная штукатурка. |
| `resources/materials/environment/buildings/plaster_warm.tres` | Создан: тёплая штукатурка. |
| `resources/materials/environment/buildings/shop_cream.tres` | Создан: светлые панели магазина. |
| `resources/materials/environment/buildings/shop_green.tres` | Создан: зелёная панель магазина. |
| `resources/materials/environment/buildings/shop_red.tres` | Создан: красные акценты. |
| `resources/materials/environment/buildings/shop_window.tres` | Создан: витрина. |
| `resources/materials/environment/buildings/window_dark.tres` | Создан: тёмное окно. |
| `resources/materials/environment/buildings/window_neutral.tres` | Создан: нейтральное окно. |
| `resources/materials/environment/buildings/window_warm.tres` | Создан: тёплое окно. |
| `assets/textures/environment/buildings/brick_clay.png` | Создана: кирпич, 64×64. |
| `assets/textures/environment/buildings/brick_clay.png.import` | Создан: настройки импорта lossless, без mipmaps, auto 3D compression выключено. |
| `assets/textures/environment/buildings/plaster_sage.png` | Создана: приглушённая серо-зелёная штукатурка, 64×64. |
| `assets/textures/environment/buildings/plaster_sage.png.import` | Создан: настройки импорта lossless, без mipmaps, auto 3D compression выключено. |
| `assets/textures/environment/buildings/plaster_warm.png` | Создана: тёплая штукатурка, 64×64. |
| `assets/textures/environment/buildings/plaster_warm.png.import` | Создан: настройки импорта lossless, без mipmaps, auto 3D compression выключено. |
| `assets/textures/environment/buildings/shop_window.png` | Создана: витрина, 64×64. |
| `assets/textures/environment/buildings/shop_window.png.import` | Создан: настройки импорта lossless, без mipmaps, auto 3D compression выключено. |
| `assets/textures/environment/buildings/shop_window_emission.png` | Создана: маска свечения витрина, 64×64. |
| `assets/textures/environment/buildings/shop_window_emission.png.import` | Создан: настройки импорта lossless, без mipmaps, auto 3D compression выключено. |
| `assets/textures/environment/buildings/window_dark.png` | Создана: тёмное окно, 64×64. |
| `assets/textures/environment/buildings/window_dark.png.import` | Создан: настройки импорта lossless, без mipmaps, auto 3D compression выключено. |
| `assets/textures/environment/buildings/window_neutral.png` | Создана: нейтральное окно, 64×64. |
| `assets/textures/environment/buildings/window_neutral.png.import` | Создан: настройки импорта lossless, без mipmaps, auto 3D compression выключено. |
| `assets/textures/environment/buildings/window_neutral_emission.png` | Создана: маска свечения нейтральное окно, 64×64. |
| `assets/textures/environment/buildings/window_neutral_emission.png.import` | Создан: настройки импорта lossless, без mipmaps, auto 3D compression выключено. |
| `assets/textures/environment/buildings/window_warm.png` | Создана: тёплое окно, 64×64. |
| `assets/textures/environment/buildings/window_warm.png.import` | Создан: настройки импорта lossless, без mipmaps, auto 3D compression выключено. |
| `assets/textures/environment/buildings/window_warm_emission.png` | Создана: маска свечения тёплое окно, 64×64. |
| `assets/textures/environment/buildings/window_warm_emission.png.import` | Создан: настройки импорта lossless, без mipmaps, auto 3D compression выключено. |
| `assets/textures/environment/curb_concrete.png` | Создана: бетон бордюра, 64×64. |
| `assets/textures/environment/curb_concrete.png.import` | Создан: настройки импорта lossless, без mipmaps, auto 3D compression выключено. |
| `docs/buildings_and_curbs_visual_pass.md` | Создан: этот отчёт, полный перечень файлов и запросы генерации. |

## Генерация текстур

Использован встроенный image_gen через навык imagegen, без API/CLI fallback. Два атласа подготовлены к использованию через Godot Image: извлечение четырёх тайлов из каждого и приведение к 64×64 методом Nearest; для трёх светящихся окон получены маски яркости, исключающие рамы. Итоговые PNG находятся в проекте, внешних runtime-зависимостей нет.

Запрос атласа поверхностей:

```text
Create a production game texture atlas, a single square PNG image divided into EXACTLY 2 columns and 2 rows of equal square tiles, no gutters, no labels, no borders around the atlas. Pixel art game WAIT, muted eastern European concrete street, restrained low-poly PS1 feeling. Strict pixel art logical grid 128x128 for whole atlas (each tile 64x64), upscaled nearest neighbor with large crisp pixels and only 12 muted colors, absolutely no blur, gradients, photographic noise, perspective, objects, windows or text. Upper LEFT quadrant: seamless pale warm gray concrete facade plaster, mostly quiet flat color with a few larger irregular weather stains and small chips, no seams. Upper RIGHT quadrant: seamless muted desaturated dusty olive gray facade plaster, mostly quiet with broad subtle wear, no seams. Lower LEFT quadrant: seamless muted faded clay brick wall with large staggered horizontal bricks, dark restrained mortar, each brick about 16 logical pixels wide by 8 tall. Lower RIGHT quadrant: seamless curb concrete stone texture, desaturated medium-light cool gray, sparse broad pixel chips and subtle concrete patches, no seams or lines (joints supplied by geometry separately). All tiles uniform unlit flat albedo colors, moderate lightness so the game can light them at night. No black-white painted stripes. This is a usable flat texture atlas, not a scene or presentation. Save output image.
```

Стыки бордюров в итоговой реализации сделаны шейдером, без дополнительной геометрии.

Запрос атласа окон:

```text
Production pixel art game texture atlas, one square image exactly 2x2 equal square tiles with NO gutters or labels. Each tile is one front-on flat orthographic eastern European apartment window filling its entire tile, identical simple dark gray outer frame 4 logical pixels thick, central vertical mullion and one upper horizontal mullion. Whole image logical resolution 128x128, 64x64 per tile, visibly square chunky pixel shapes, nearest-neighbor upscaled. Top left: unlit blue charcoal window, large subtle reflected blue shapes. Top right: dim warm cream window with blocky curtains, amber desaturated light, dark frame. Bottom left: muted neutral pale warm gray lit window with partially drawn curtain. Bottom right: grocery store glass display window, dark teal framing, interior warm muted cream, only three broad shelf silhouettes and a few large simple olive and ochre rectangular product shapes. Restrained muted palette matching a rainy melancholy stylized low-poly street, simple large readable forms with no small noise. Each tile is flat UV texture only, no perspective, no wall around windows, no shadows cast on surrounding wall, no text, no signage. No bloom, no glow halos, no gradients, no antialiasing. Frames must remain dark in all four tiles.
```
