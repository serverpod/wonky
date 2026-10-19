/// Pure-Dart id helpers of Wonky Sheets (specs/wonky_sheets/02 §2) and Wonky
/// Slides (specs/wonky_slides/02 §2): deterministic UUIDv5 ids, fractional
/// indexing and the 22-character base-62 UUID codec.
library;

export 'package:wonky_revlog/base62.dart'
    show Base62Uuid, base62Digits, base62Value;
export 'src/ids/fractional_index.dart' show FractionalIndex;
export 'src/ids/sheets_ids.dart'
    show
        IdGenerator,
        SeededIdGenerator,
        SequentialIdGenerator,
        SheetsIds,
        UuidV7IdGenerator;
export 'src/ids/slides_ids.dart' show SlidesIds;
