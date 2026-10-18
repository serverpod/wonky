import 'package:wonky_revlog/schema.dart';

import 'sheets_schema.g.dart';

/// The RevLog schema of Wonky Sheets (RevLog spec 02 §4): 22 tables,
/// generated from the server models by `tool/gen_rev_schema.dart`.
final RevSchema sheetsSchema = RevSchema('sheets', sheetsRevTables);
