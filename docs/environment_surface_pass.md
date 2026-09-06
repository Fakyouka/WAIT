# WAIT — first ground surface pass

The approved blockout is preserved. Only surface material assignments changed on existing nodes in `scenes/main/main.tscn`. All 64 original node blocks were compared against the pre-task snapshot, ignoring only surface material assignments; all original mesh resources were compared verbatim. Positions, rotations, scales, mesh sizes, player, props, buildings, trees, lights, environment and post-processing are unchanged. No runtime scripts were added.

## Existing surfaces

All paths below are relative to `Main/WorldViewport/Location`.

| Role | Existing mesh nodes |
| --- | --- |
| Road | `Road/Road` |
| Near sidewalk | `SideWalkNear/SideWalk`, `SideWalkNear/SideWalk2`, `SideWalkNear/SideWalk3` |
| Far sidewalk | `SideWalkFar/SideWalkFar` |
| Ground | `Ground/Ground`, `Ground/Ground2` |

The existing `Fence` meshes are tall blockout barriers, not curbs. They remain unchanged. In particular, the far barrier partially obscures the far sidewalk and ground from the seated camera.

## Added geometry

- `Curbs` with six MeshInstance3D children: `NearStop`, `NearLeft`, `NearRight`, `StopReturnLeft`, `StopReturnRight`, `Far`. They follow the actual stepped sidewalk boundary. Width is 0.16 m, top Y is 0.055 m, roughly 0.20 m above the asphalt. No second road or sidewalk was created.
- `Road/RoadMarkings` with 17 separate MeshInstance3D children `CenterDash01` through `CenterDash17`, sharing a PlaneMesh. Each dash is 3 × 0.14 m with a 3 m gap, follows X, and sits 5 mm above the road at Z = 2.0046163. Shadow casting is disabled on the paint.

## Changed and added project files

| File | Purpose |
| --- | --- |
| `scenes/main/main.tscn` | Assign five external materials and add curbs and dashes; remove two unused placeholder surface materials. |
| `resources/materials/environment/road_asphalt.tres` | Matte cool asphalt; world-space UV1 triplanar repeat every 4 m. |
| `resources/materials/environment/sidewalk.tres` | Worn cool concrete; 2.4 m repeat with 1.2 m slabs. |
| `resources/materials/environment/ground.tres` | Muted packed earth; 5 m repeat. |
| `resources/materials/environment/curb.tres` | Dirty light gray concrete. |
| `resources/materials/environment/road_marking.tres` | Faded gray beige paint. |
| `assets/textures/environment/road_asphalt.png` | Seamless 64 × 64 asphalt, 5 colors. |
| `assets/textures/environment/sidewalk.png` | Seamless 64 × 64 slab concrete, 6 colors. |
| `assets/textures/environment/ground.png` | Seamless 64 × 64 packed earth, 5 colors. |
| `assets/textures/environment/road_asphalt.png.import` | Lossless import; no mipmaps or automatic 3D compression. |
| `assets/textures/environment/sidewalk.png.import` | Same pixel-preserving import settings. |
| `assets/textures/environment/ground.png.import` | Same pixel-preserving import settings. |
| `docs/environment_surface_pass.md` | This handoff, material scales, validation and texture prompts. |

All materials use Metallic = 0, Roughness = 1, Specular = 0.12, Nearest filtering and Texture Repeat. Built-in world-space triplanar UV1 mapping keeps the same texel density on unequal block sizes without changing the existing BoxMesh UVs or transforms. No custom shader is needed. The stop's existing local lights brighten the near concrete; lighting settings were preserved.

## Validation

- Godot 4.7.2-stable Steam: headless editor import/load, exit 0, no errors in final run.
- Rendered the actual main scene using the existing active Player/Head/CameraEffects/Camera3D and existing post-process. Inspected forward, downward and sideways views using the existing seated look function in an external temporary validation script; no camera transforms were saved.
- Runtime checks: all five materials' roughness, metallic, Nearest and repeat settings; all texture dimensions, palette counts, absent mipmaps and world-space UV settings; six curb meshes and seventeen dashes.
- All pre-existing scene/script/shader/material/model files hashed against the pre-task snapshot: only main.tscn changed. All 64 original scene nodes and all original primitive mesh resources retain their properties, apart from the intended material assignments.
- git diff --check passed. No commit or push. Generated .godot state was not edited manually.

## Texture source prompts

Generated using the built-in image_gen tool. Final project PNGs were normalized to the requested 64 × 64 grid with nearest sampling, limited palettes and wrapped boundaries. Full-resolution generation outputs remain outside the repository; the game references only the three PNGs listed above.

### Asphalt

Use case: stylized-concept. Asset type: seamless repeating albedo texture for a Godot low-poly pixel-art game WAIT. Create ONE flat square orthographic asphalt texture tile, edge-to-edge with no border. Pixel art on an EXACT coarse 64 by 64 pixel grid (deliver 64x64 if possible, otherwise nearest-neighbor integer upscale of that grid). Muted dark cool gray-blue asphalt, base #444b55, only 5 closely related flat colors. Hand placed large irregular stepped pixel clusters, sparse darker worn patches and very rare lighter small stone clusters. Quiet mostly flat areas, no fine procedural noise, no photographic grain, no dithering, no antialiasing, no gradients, no baked lighting or shadows, no cracks, no road markings, no objects, no text. Truly seamless wrapping in both directions, no visible edge frame. Material swatch only, not a rendered street or preview. Pixels must be chunky square flat color shapes; low contrast.

### Sidewalk

Use case: stylized-concept. Asset type: seamless repeating albedo texture for a Godot low-poly pixel-art game WAIT. Create ONE square flat orthographic concrete sidewalk texture tile, edge-to-edge. Pixel art on an EXACT coarse 64 by 64 pixel grid (deliver 64x64 if possible, otherwise nearest-neighbor integer upscale of that grid). Four large 32x32 concrete slabs in a simple 2x2 aligned grid with narrow one-pixel dark muted joints at x=0,32 and y=0,32 so repeated tiles join seamlessly. Old modest city sidewalk, cold muted gray concrete base #81858a, small subtle differences between slabs, sparse large stepped dirt patches, a few chipped corners, no elaborate cracks. Limit to 6 flat closely related muted gray colors, joint #5c6269. Hand painted chunky pixel clusters and broad quiet areas. No photographic noise, no tiny procedural grain, no antialiasing, no dithering, no gradients, no directional lighting, no perspective, no bevel shading, no text, no border. Surface only, not a rendered street. Seamless in both directions.

### Ground

Use case: stylized-concept. Asset type: seamless flat albedo ground texture for WAIT, a low-poly pixel-art overcast old city game. ONE square top-down seamless packed earth tile, no perspective or lighting. Coarse 64x64 pixel grid (deliver at 64x64 if possible, otherwise integer nearest upscale). Sparse broad hand-placed stepped clusters on mostly flat dusty dull gray olive brown earth, base #62635a. Only 5 very close muted colors, flat pixel shapes, occasional darker compacted soil patches and very sparse muted olive moss patches. No grass blades, no photographic noise, no tiny random noise, no gradients or antialias, no cracks, no stones bigger than a few pixels, no objects, no borders or text. All edges wrap seamlessly; subdued low contrast matching dark gray-blue asphalt and old gray concrete.

