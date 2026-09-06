# WAIT — забор, деревья и фонарные столбы

## Результат

Первый pass уличных объектов на утверждённых местах. Забор и деревья — неподвижные Sprite3D в плоскости XY. Billboard отключён, автоматического поворота и скриптов нет. Спрайты двусторонние, получают существующее освещение, используют Alpha Cut / Discard, Nearest и PNG с бинарной прозрачностью. Фонари — простые 3D-меши без источников света и без emission.

## Размещение и сохранение композиции

В `Main/WorldViewport/Location/Environment` созданы группы `Fences`, `StreetLights`, `Trees`. Сам контейнер Environment заменён с пустого StaticBody3D на Node3D. Раньше у него не было CollisionShape3D.

- `SideWalkNear/Fence` → `Environment/Fences/NearRight`; `SideWalkNear/Fence2` → `Environment/Fences/NearLeft`; `SideWalkFar/Fence` → `Environment/Fences/Far`. Корневые Transform и unique_id сохранены буквально. Ближние отрезки содержат по 16 повторяемых секций, дальний — 36. Итого 68 Sprite3D. Длина каждого отрезка и высота исходного блока сохранены; ширина секций чуть подогнана дочерним Scale, без изменения исходных границ. Общий проём перед остановкой сохранён.
- Все `LampPost1`–`LampPost18` используют исходные Transform и unique_id под группой StreetLights. У каждой заготовки вместо меша теперь Node3D с экземпляром StreetLight. Только дочерняя модель привязана основанием к тротуару. Кронштейн дальнего ряда смотрит в −Z, ближнего — в +Z, к дороге. Модель около 4 м высотой, шестигранный столб, бетонное основание, короткий кронштейн и прямоугольная головка.
- Все 13 исходных `Tree*` перенесены в Trees с сохранением Transform и unique_id. Вместо узкого placeholder-меша — Node3D с одной из трёх tree scenes. Дочерняя модель имеет основание на поверхности существующего Ground: Y = 0.00408059. Высоты вариантов 6.8, 7.0 и 6.5 м. Позиции по X/Z, повороты и масштаб исходных узлов не изменены.

Все 94 исходных узла сохранили Transform и идентификаторы. Из них 35 — заменённые заготовки/контейнер; остальные 59 узлов сохранили все свойства и пути. Все 18 посторонних subresources сохранены. Удалены только четыре неиспользуемых меша старых заготовок. Player, Camera3D, Cigarette, BusStop, StickerBoard, освещение, поверхности улицы, здания, постобработка и существующий Traffic не изменены.

## Переиспользование

Корень каждой новой сцены находится у основания объекта. Для нового размещения достаточно добавить экземпляр нужной сцены. Забор имеет номинальный размер 2.4 × 0.78 м и повторяется по X. Спрайты смотрят фиксированной лицевой стороной в −Z; обратная сторона тоже видима. При взгляде почти вдоль плоскости они естественно сужаются — это выбранная техника плоского декора, не billboard.

Три внешних материала фонаря имеют Metallic = 0, Roughness = 1, Specular = 0.12. PNG для фонаря не нужен: его стиль задают простая геометрия и матовые цвета.

## Полный список файлов

Изменён:

| Файл | Изменение |
| --- | --- |
| `scenes/main/main.tscn` | Замена 34 placeholder-мешей на экземпляры сцен, три группы под Environment, удаление четырёх устаревших меш-ресурсов. |

Созданы:

| Файл | Назначение |
| --- | --- |
| `scenes/environment/fence/fence_segment.tscn` | Переиспользуемый неподвижный Sprite3D забора. |
| `scenes/environment/trees/tree_01.tscn` | Дерево с широкой округлой кроной. |
| `scenes/environment/trees/tree_02.tscn` | Более узкое высокое дерево. |
| `scenes/environment/trees/tree_03.tscn` | Асимметричное раскидистое дерево. |
| `scenes/environment/street_lights/street_light.tscn` | Low-poly фонарь без активного света. |
| `assets/textures/environment/fence/fence_segment.png` | Спрайт 128 × 48, 4 непрозрачных цвета + прозрачность. |
| `assets/textures/environment/fence/fence_segment.png.import` | Lossless, mipmaps off, automatic 3D compression off. |
| `assets/textures/environment/trees/tree_01.png` | Спрайт 96 × 128, 7 цветов + прозрачность. |
| `assets/textures/environment/trees/tree_01.png.import` | Импорт без потерь и размытия. |
| `assets/textures/environment/trees/tree_02.png` | Спрайт 96 × 128, 7 цветов + прозрачность. |
| `assets/textures/environment/trees/tree_02.png.import` | Импорт без потерь и размытия. |
| `assets/textures/environment/trees/tree_03.png` | Спрайт 96 × 128, 7 цветов + прозрачность. |
| `assets/textures/environment/trees/tree_03.png.import` | Импорт без потерь и размытия. |
| `resources/materials/environment/street_lights/painted_metal.tres` | Холодный серый матовый металл. |
| `resources/materials/environment/street_lights/base_concrete.tres` | Бетон основания. |
| `resources/materials/environment/street_lights/lamp_lens.tres` | Приглушённый серо-бежевый рассеиватель, без emission. |
| `docs/environment_props_pass.md` | Этот отчёт и точные промпты текстур. |

## Проверки

- Godot 4.7.2-stable Steam: headless editor import/load — exit 0, без ошибок проекта.
- main.tscn перезагружен в открытом редакторе и запущен через F5; игровой кадр проверен, тест остановлен через F8. Ошибок и предупреждений запуска нет.
- Runtime-проверка: 13 деревьев, 18 фонарей, 68 секций забора; у всех 81 Sprite3D billboard disabled, Nearest, shaded, double-sided и alpha discard; дополнительные Light3D отсутствуют.
- Импортированные PNG: нужные размеры, 4/7/7/7 непрозрачных цветов, только alpha 0 или 1, mipmaps отсутствуют.
- Четыре вида из существующей камеры игрока: прямо, вправо, влево, влево-вниз, с текущей постобработкой и освещением. Временный проверочный скрипт вызывал существующий seated mouse look; Transform каждого спрайта до и после поворотов совпал. Скрипт не добавлен в проект.
- Сравнение всех исходных узлов по unique_id и точному тексту Transform, сравнение защищённых ресурсов и SHA-256 всех прежних файлов. Из существовавших файлов изменён только main.tscn.
- git diff --check. Commit/push не выполнялись, .godot вручную не редактировалась.

## Источник текстур

Созданы встроенным image_gen. PNG нормализованы к низкому разрешению с Nearest, общей ограниченной палитрой и бинарным alpha для чётких краёв. Высокое разрешение исходной генерации осталось вне репозитория.

### fence_segment

Use case: stylized-concept. Asset: reusable world-space pixel-art sprite for WAIT, an overcast melancholic ordinary city low-poly game. Genuine transparent alpha background, isolated single asset, orthographic straight front elevation, not isometric. Crisp coarse pixel art, NO antialiasing, no fine texture or photographic noise, no gradients, no dithering, no cast shadow on ground, no text, no border. Limited subdued palette, broad flat clusters. A single horizontally repeatable short old metal pedestrian street railing segment, simple rectangular frame with TWO horizontal rails and FIVE widely spaced upright flat iron bars. Very open silhouette, 75 percent empty transparent space between bars. Low waist-high fence, width approximately 3 times height. Square blunt posts at both ends, each HALF a post at the left and right image edges so segments repeat without doubled posts. Rails reach exact left and right edges at matching heights. Muted gray teal metal #56615f, shadow #3e4948, dull worn highlight #727973, very sparse dull brown wear #686056. Metal bars at least 3 pixels thick on a 128x48 logical grid. No ornate shapes, spikes, chain link, grass, ground or scenery. Fill the canvas horizontally; tiny vertical clearance, straight tidy silhouette, visibly aged but not broken.

### tree_01

Use case: stylized-concept. Asset: reusable world-space pixel-art sprite for WAIT, an overcast melancholic ordinary city low-poly game. Genuine transparent alpha background, isolated single asset, orthographic straight front elevation, not isometric. Crisp coarse pixel art, NO antialiasing, no fine texture or photographic noise, no gradients, no dithering, no cast shadow on ground, no text, no border. Limited subdued palette, broad flat clusters. ONE mature deciduous city tree, broad irregular rounded crown, a slightly off-center warm dark brown trunk with two visible main branches. Hand drawn silhouette of 5 or 6 LARGE chunky connected canopy lobes, no individual leaves, minimal internal marks. About 7 meters tall in intended game scale, crown occupies upper 65 percent, trunk lower 35 percent. Full tree including flat trunk base, centered and wholly visible, only a narrow transparent margin. Logical pixel grid 96x128. Dark muted gray-green foliage palette #34443e #42554a #576b58 #6c7d64, trunk #463d35 #615044 #79634e. No roots sprawling widely. Calm solid clustered canopy with a few small transparent notches.

### tree_02

Use case: stylized-concept. Asset: reusable world-space pixel-art sprite for WAIT, an overcast melancholic ordinary city low-poly game. Genuine transparent alpha background, isolated single asset, orthographic straight front elevation, not isometric. Crisp coarse pixel art, NO antialiasing, no fine texture or photographic noise, no gradients, no dithering, no cast shadow on ground, no text, no border. Limited subdued palette, broad flat clusters. ONE mature deciduous city tree, TALLER NARROW oval crown with uneven stepped silhouette, upright trunk splitting high into two branches. Hand drawn silhouette of 4 or 5 LARGE chunky connected canopy lobes, no individual leaves, minimal internal marks. About 7 meters tall in intended game scale, crown occupies upper 70 percent, trunk lower 30 percent. Full tree including flat trunk base, centered and wholly visible, only a narrow transparent margin. Logical pixel grid 96x128. Dark muted gray-green foliage palette #34443e #42554a #576b58 #6c7d64, warm dark brown trunk #463d35 #615044 #79634e. Slightly asymmetric narrow upright crown, not a conifer. No roots sprawling widely.

### tree_03

Use case: stylized-concept. Asset: reusable world-space pixel-art sprite for WAIT, an overcast melancholic ordinary city low-poly game. Genuine transparent alpha background, isolated single asset, orthographic straight front elevation, not isometric. Crisp coarse pixel art, NO antialiasing, no fine texture or photographic noise, no gradients, no dithering, no cast shadow on ground, no text, no border. Limited subdued palette, broad flat clusters. ONE mature deciduous city tree, slightly shorter spreading ASYMMETRIC crown, left side wider and lower than right, a gently bent warm dark brown trunk splitting into a Y. Hand drawn silhouette of 5 or 6 LARGE chunky connected canopy lobes, no individual leaves, minimal internal marks. About 6.5 meters tall in intended game scale, crown occupies upper 65 percent, trunk lower 35 percent. Full tree including flat trunk base, centered and wholly visible, only a narrow transparent margin. Logical pixel grid 96x128. Dark muted gray-green foliage palette #34443e #42554a #576b58 #6c7d64, trunk #463d35 #615044 #79634e. No roots sprawling widely, broad calm silhouette with a few small transparent notches.

