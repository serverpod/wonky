import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

/// Whether the platform shows PDFs inline (web: the browser's viewer).
const bool canPreviewPdfInline = false;

/// Desktop and tests: a summary of the generated PDF ([desktopTitle] and
/// [desktopHint]); the browser's viewer on the web (see the web file for
/// the other parameters).
class PdfView extends StatelessWidget {
  const PdfView({
    super.key,
    required this.bytes,
    required this.desktopTitle,
    required this.desktopHint,
    this.page,
    this.thumbnails = false,
    this.fitPage = false,
  });

  final Uint8List bytes;
  final String desktopTitle;
  final String desktopHint;
  final int? page;
  final bool thumbnails;
  final bool fitPage;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.fileText,
              size: 40,
              color: theme.colorScheme.mutedForeground,
            ),
            const SizedBox(height: 12),
            Text(
              desktopTitle,
              style: theme.textTheme.large,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              desktopHint,
              style: theme.textTheme.muted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Prints [bytes]: not available on desktop (download instead); false.
Future<bool> printPdf(Uint8List bytes, {required String title}) async => false;
