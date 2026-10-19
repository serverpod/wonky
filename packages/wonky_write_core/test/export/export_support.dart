import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:wonky_write_core/wonky_write_core.dart';

/// A 4×2 red PNG.
Uint8List pngBytes({int width = 4, int height = 2}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(255, 0, 0));
  return img.encodePng(image);
}

Delta md(String markdown) {
  var n = 0;
  return const MarkdownCodec()
      .importMarkdown(
        markdown,
        options: ImportOptions(idGenerator: () => 'e${n++}'),
      )
      .delta;
}

ExportInput input(
  Delta document, {
  Map<String, ResolvedImage> images = const {},
  PageSetup pageSetup = const PageSetup(),
  ThemeVariant variant = ThemeVariant.light,
  String theme = 'wonky-default',
  CancellationToken? cancel,
  ExportYielder? yielder,
}) => ExportInput(
  document: document,
  revision: 3,
  meta: DocMeta(
    documentUuid: '0192aaaa-0000-7000-8000-000000000001',
    title: 'Q3 planning',
    authorName: 'Anna',
    language: 'en',
    modifiedAt: DateTime.utc(2026, 10, 1, 12),
    frontMatter: 'tags: [plan, q3]',
  ),
  theme: BuiltinThemes.byKey(theme)!.theme,
  variant: variant,
  pageSetup: pageSetup,
  images: MapImageResolver(images),
  fonts: InMemoryFontProvider(const []),
  now: DateTime.utc(2026, 10, 12, 9),
  cancel: cancel,
  yielder: yielder,
);

const sample = '''# Q3 planning

Intro with **bold**, *italic*, ~~strike~~, `code` and a [link](https://example.com).

## Goals

1. First
2. Second
   - nested

- [x] done
- [ ] todo

> A quote

```dart
void main() => print('hi');
```

---

![Logo](https://img.example.com/logo.png "The logo")

| Name | Value |
| --- | ---: |
| a | 1 |
''';
