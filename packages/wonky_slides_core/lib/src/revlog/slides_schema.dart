import 'package:wonky_revlog/schema.dart';

import 'slides_schema.g.dart';

/// The RevLog schema of Wonky Slides (RevLog spec 02 §4): 12 tables,
/// generated from the server models by `tool/gen_rev_schema.dart`.
final RevSchema slidesSchema = RevSchema('slides', slidesRevTables);
