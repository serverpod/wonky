import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import '../../l10n/sheets_l10n.dart';
import '../sheet_editor/sheet_editor_controller.dart';

/// "Loading… 42 %" in the status area while a large spreadsheet's rows
/// still stream in after it opened (RevLog spec 17 part 6 §7.1, Sheets 02
/// §6); hidden once every row is loaded.
class RowLoadingStatus extends StatelessWidget {
  const RowLoadingStatus({super.key, required this.controller});

  final SheetEditorController controller;

  @override
  Widget build(BuildContext context) {
    final loading = controller.session.rowLoading;
    return ListenableBuilder(
      listenable: loading,
      builder: (context, _) {
        if (loading.complete) return const SizedBox.shrink();
        final theme = ShadTheme.of(context);
        return Padding(
          key: const ValueKey<String>('sheets.status.loadingRows'),
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(dimension: 12, child: ShadSpinner()),
              const SizedBox(width: 6),
              Text(
                sheetsL10n(
                  context,
                ).loadingRowsStatus((loading.progress * 100).floor()),
                style: theme.textTheme.muted.copyWith(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
