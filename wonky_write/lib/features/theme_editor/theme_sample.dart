import 'package:wonky_write_core/wonky_write_core.dart'
    show
        Delta,
        ImportOptions,
        MarkdownCodec,
        MarkdownFlavor,
        mentionTitlePrefix;

/// The theme preview's sample document (Write 06 §10.2): every element a
/// theme styles — headings, body text with inline styles, link, mention,
/// quote, code, lists at several levels, tasks, a rule, a table and the
/// Wonky Markdown elements (Write 11 §8; imported as Wonky Markdown).
const String themeSampleMarkdown =
    '''
# The quarterly field notes

A theme changes how a document *looks* — never what it **says**. This sample shows every element, so you can see your changes right away. Text can be **bold**, *italic*, ~~struck through~~ or `inline code`, and links look [like this](https://wonky.work). Ask [@Anna Berg](https://wonky.work/u/anna "${mentionTitlePrefix}00000000-0000-7000-8000-00000000a11a") if anything is unclear.

## Highlights of the season

The second paragraph follows a heading. Spacing after headings, line height and paragraph spacing all come from the theme.

> Good typography is invisible. Bad typography is everywhere.
> — A careful reader

### Plans and progress

- Ship the new garden map
  - Survey the north beds
    - Mark the old irrigation lines
- Publish the volunteer guide

1. Collect the soil samples
2. Send them to the lab
   1. Label every bag
   2. Note the depth

- [x] Order seeds
- [ ] Repair the greenhouse door

#### Measurements

| Bed | Soil pH | Moisture |
| --- | --- | --- |
| North | 6.4 | 31 % |
| South | 7.1 | 24 % |
| Herbs | 6.8 | 28 % |

##### Data pipeline

```dart
/// Averages the readings of one bed.
double average(List<double> readings) {
  if (readings.isEmpty) return 0; // nothing measured yet
  final total = readings.reduce((a, b) => a + b);
  return total / readings.length;
}
```

### (1) Prepare the beds

:::tip[Good to know]

Callouts, cards and grids follow the theme too. Tag beds as :chip[Organic], then :button[Join a work day](https://wonky.work) or :link[read the volunteer guide](https://wonky.work).

:::

:::details

### What do the beds need?

Compost, mulch and a good soak the day before planting.

:::

:::card

:::grid{columns=3 bullets=check}
- Compost
- Mulch
- Water
:::

:::

---

###### Footnote

Small print, captions and asides use the same theme as everything else.
''';

Delta? _sample;

/// The sample document as a Delta.
Delta themeSampleDelta() => _sample ??= const MarkdownCodec()
    .importMarkdown(
      themeSampleMarkdown,
      options: ImportOptions(flavor: MarkdownFlavor.wonky),
    )
    .delta;
