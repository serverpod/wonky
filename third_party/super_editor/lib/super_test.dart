// WONKY PATCH (infra, SE-10): the golden helpers (`test_tools_goldens.dart`) moved to
// `test/`: they import the dev dependency `golden_toolkit` (CQ-45), which `lib/` can't.
export 'src/test/flutter_extensions/finders.dart'
    if (dart.library.js_interop) 'src/test/extensions/flutter_extensions_stub.dart';
export 'src/test/flutter_extensions/test_documents.dart'
    if (dart.library.js_interop) 'src/test/extensions/flutter_extensions_stub.dart';
export 'src/test/flutter_extensions/test_flutter_extensions.dart'
    if (dart.library.js_interop) 'src/test/extensions/flutter_extensions_stub.dart';
export 'src/test/flutter_extensions/test_tools_user_input.dart'
    if (dart.library.js_interop) 'src/test/extensions/flutter_extensions_stub.dart';
