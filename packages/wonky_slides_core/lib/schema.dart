/// The schema of Wonky Slides (Slides 02 §3): table and column names and
/// the undo table hooks (coupled columns, P4). The RevLog table schema is
/// `revlog.dart`; the deterministic ids (`SlidesIds`) are in
/// `wonky_sync_models`.
library;

export 'src/schema/slides_schema.dart';
export 'src/schema/slides_undo_hooks.dart';
