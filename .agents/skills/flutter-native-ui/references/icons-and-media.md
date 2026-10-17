# Icons and media

Official: [Icons](https://api.flutter.dev/flutter/material/Icons-class.html), [Icons.adaptive](https://api.flutter.dev/flutter/material/PlatformAdaptiveIcons-class.html), [CupertinoIcons](https://api.flutter.dev/flutter/cupertino/CupertinoIcons-class.html), [Image](https://api.flutter.dev/flutter/widgets/Image-class.html).

## Icons

```dart
Icon(Icons.adaptive.arrow_back)
Icon(Icons.adaptive.share)
Icon(Icons.adaptive.more) // horizontal dots on iOS, vertical on Android
```

- Material surfaces: `Icons.*` outlined at rest, filled when selected (`Icons.home_outlined` / `Icons.home`).
- Cupertino surfaces: `CupertinoIcons.*`.
- Sizes: 20, 24, 32. Color from `ColorScheme.onSurface` / `onSurfaceVariant`, not a hardcoded grey.
- Do not use FontAwesome, Ionicons, or SF Symbol packages for app chrome.
- Material Symbols (`material_symbols_icons`) only if the project already adopted them.

`ImageIcon(..., useOriginalColors: true)` when the asset must keep its own colors (Flutter 3.47).

## Images

```dart
Image.network(
  url,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stack) => const Icon(Icons.broken_image_outlined),
  loadingBuilder: (context, child, progress) {
    if (progress == null) return child;
    return const Center(child: CircularProgressIndicator.adaptive());
  },
)
```

- `Image.asset` for bundled. `FadeInImage` for a placeholder fade.
- Use `cached_network_image` only if the project already depends on it.
- Give images an aspect ratio (`AspectRatio`, `SizedBox`) so lists do not jump.
- `Semantics(label: ...)` on informative images; `ExcludeSemantics` on decorative ones.

## Camera, gallery, files

Prefer first-party / `flutter.dev` packages already common in the tree:

| Job | Package |
| --- | --- |
| Pick photo/video | `image_picker` |
| Live camera preview | `camera` |
| Save to gallery / files | `image_picker` + `path_provider` (or the project's existing saver) |

Request permissions at the moment of use. Do not add a third camera plugin next to `image_picker`.

## Audio and video

| Job | Package |
| --- | --- |
| Video playback | `video_player` (+ `Chewie` only if the project already uses it) |
| Audio playback | `just_audio` if you need playlists/position; otherwise keep whatever is there |

Do not add `expo-av` equivalents. Pause when the route is covered (`RouteAware` / app lifecycle).

## Vector and lottie

- SVG: `flutter_svg` when the asset is actually SVG.
- Lottie: only when motion design shipped a `.json`. Do not decorate a settings row with Lottie.
