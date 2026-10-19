import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show DriveItemView, UuidValue;
import 'package:wonky_slides_core/interfaces.dart';
import 'package:wonky_slides_core/model.dart' show DeckModel;
import 'package:wonky_slides_core/pdf.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../commands/slides_command.dart' show editorOfServices;
import '../../config/slides_features.dart';
import '../../l10n/slides_l10n.dart';
import '../editor_screen/deck_editor_controller.dart';
import 'package:wonky_app/platform.dart' show PdfView, printPdf;
import 'print_controller.dart';
import 'print_settings_panel.dart';
import 'slides_client_export.dart';
import '../uploads/slides_image_service.dart';

/// What the print commands reach while the preview is open
/// (`slides.print.print`, `slides.file.download` inside the route).
abstract interface class SlidesPrintActions {
  /// The preview's state (options, PDF, page count).
  SlidesPrintController? get controller;

  /// Opens the browser print dialog for the PDF.
  Future<bool> print();

  /// Downloads the PDF.
  Future<bool> download();
}

/// The open print preview, if any.
final ValueNotifier<SlidesPrintActions?> activeSlidesPrint = ValueNotifier(
  null,
);

/// The print / PDF preview route `/slides/p/:uuid/print` (Slides 10 §12):
/// the PDF rendered by the client exporter shown in the browser's viewer
/// inside the app (no new tab or window), the §11.1 options in a settings
/// column (below the preview behind a toggle at narrow widths), *Download
/// PDF* and *Print* (browser print dialog of the frame). Settings changes
/// regenerate the PDF after 300 ms. `Esc` goes back to the deck, `Mod+P`
/// prints. The deck editor stays mounted underneath
/// (`WonkyAppConfig.editorRoutes`), so the open session is reused.
class PrintPreviewScreen extends StatefulWidget {
  const PrintPreviewScreen({
    super.key,
    required this.services,
    required this.itemUuid,
    this.initialLayout,
    this.renderer,
    this.screenLayout = true,
  });

  final ShellServices services;
  final String itemUuid;

  /// `?layout=` of the route (`slides.print.open {layout}`).
  final SlidesPdfLayout? initialLayout;

  /// Replaces the client exporter (tests).
  final SlidesPdfRenderFn? renderer;

  /// Lay text out with the Flutter engine (false: the core TTF layout).
  final bool screenLayout;

  @override
  State<PrintPreviewScreen> createState() => _PrintPreviewScreenState();
}

class _PrintPreviewScreenState extends State<PrintPreviewScreen>
    implements SlidesPrintActions {
  DeckEditorController? _editor;
  Listenable? _doc;
  SlidesPrintController? _controller;
  DriveItemView? _item;
  bool _showSettings = false;

  ShellServices get s => widget.services;

  @override
  SlidesPrintController? get controller => _controller;

  @override
  void initState() {
    super.initState();
    s.activeDocument.addListener(_attach);
    activeSlidesPrint.value = this;
    unawaited(_loadItem());
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
  }

  @override
  void dispose() {
    s.activeDocument.removeListener(_attach);
    _doc?.removeListener(_attach);
    _controller?.dispose();
    if (activeSlidesPrint.value == this) activeSlidesPrint.value = null;
    super.dispose();
  }

  Future<void> _loadItem() async {
    try {
      final item = await s.drive.get(UuidValue.withValidation(widget.itemUuid));
      if (mounted) setState(() => _item = item);
    } on Object {
      // Offline or unknown: the deck's own data is enough to print.
    }
  }

  void _attach() {
    if (!mounted) return;
    // The document controller forwards its editor's notifications (the
    // editor attaches once the deck session is open).
    final doc = s.activeDocument.value;
    if (!identical(doc, _doc)) {
      _doc?.removeListener(_attach);
      _doc = doc;
      doc?.addListener(_attach);
    }
    final ed = editorOfServices(s);
    _editor = ed;
    if (_controller == null && ed != null && ed.isReady) {
      final l = slidesL10nOf(s);
      final locale = Localizations.maybeLocaleOf(context)?.toLanguageTag();
      var options = SlidesClientExport.lastUsed(s, locale: locale);
      if (widget.initialLayout case final layout?) {
        options = options.withLayout(layout, locale: locale);
      }
      final c = SlidesPrintController(
        deck: ed.model,
        options: options,
        currentSlideId: ed.currentSlideId,
        selectedSlideIds: ed.selectedSlideIds.toList(),
        locale: locale,
        render:
            widget.renderer ??
            (deck, o, cancelled) => SlidesClientExport.render(
              deck,
              o,
              images: SlidesImageService.of(ed),
              l: l,
              info: _info(deck, locale),
              screenLayout: widget.screenLayout,
              isCancelled: cancelled,
            ),
      );
      c.addListener(_onController);
      _controller = c;
      unawaited(c.refresh());
    }
    setState(() {});
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  SlidesPdfDocumentInfo _info(DeckModel deck, String? locale) {
    final item = _item;
    final modified = item?.modifiedAt;
    return SlidesPdfDocumentInfo(
      title: _title,
      author: item?.owner.displayName,
      subject: item?.description,
      modified: modified,
      dateLabel: modified == null
          ? null
          : DateFormat.yMMMd(locale).format(modified.toLocal()),
    );
  }

  String get _title {
    final l = slidesL10nOf(s);
    final t = _editor?.model.deck?.title ?? _item?.name ?? '';
    return t.isEmpty ? l.pdfUntitledPresentation : t;
  }

  bool get _canExport {
    final item = _item;
    if (item != null) return item.canDownload;
    return true;
  }

  void _back() => s.router.go(s.config.itemPath(widget.itemUuid));

  String get _fileName {
    final o = _controller?.options;
    return '${o?.fileName ?? SlidesPdfOptionsCodec.sanitizeFileName(_title)}.pdf';
  }

  @override
  Future<bool> download() async {
    final c = _controller;
    final pdf = c?.pdf;
    if (c == null || pdf == null || !_canExport) return false;
    final l = slidesL10nOf(s);
    final name = _fileName;
    final saved = await SlidesClientExport.save(pdf, fileName: name);
    if (!saved) return false;
    unawaited(SlidesClientExport.remember(s, c.options));
    final warnings = c.warningTexts(l);
    s.toasts.show(
      l.exportedToast(name),
      description: warnings.isEmpty ? null : warnings.join('\n'),
    );
    return true;
  }

  @override
  Future<bool> print() async {
    final pdf = _controller?.pdf;
    if (pdf == null || !_canExport) return false;
    final l = slidesL10nOf(s);
    final ok = await printPdf(pdf, title: _title);
    if (!ok) {
      s.toasts.show(
        l.printUnavailableTitle,
        description: l.printUnavailableBody,
        actionLabel: l.printDownloadPdf,
        onAction: () => unawaited(download()),
      );
    } else {
      unawaited(SlidesClientExport.remember(s, _controller!.options));
    }
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _back,
        const SingleActivator(LogicalKeyboardKey.keyP, meta: true): () =>
            unawaited(print()),
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): () =>
            unawaited(print()),
      },
      child: Focus(
        autofocus: true,
        child: ColoredBox(
          key: const ValueKey<String>('slides.print'),
          color: cs.background,
          child: LayoutBuilder(
            builder: (context, box) {
              final narrow = box.maxWidth < 720;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(context, narrow),
                  const ShadSeparator.horizontal(margin: EdgeInsets.zero),
                  Expanded(
                    child: narrow
                        ? (_showSettings
                              ? _settings(context)
                              : _preview(context))
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _preview(context)),
                              Container(width: 1, color: cs.border),
                              SizedBox(width: 300, child: _settings(context)),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, bool narrow) {
    final theme = ShadTheme.of(context);
    final l = slidesL10n(context);
    final c = _controller;
    final ready = c?.pdf != null && _canExport;
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            ShadTooltip(
              builder: (_) => Text(l.printBack),
              child: ShadIconButton.ghost(
                key: const ValueKey<String>('slides.print.back'),
                semanticLabel: l.printBack,
                icon: const Icon(LucideIcons.arrowLeft, size: 16),
                onPressed: _back,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  narrow
                      ? l.printPreviewTitle
                      : l.printPreviewTitleWithName(_title),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: theme.textTheme.large,
                ),
              ),
            ),
            if (c?.busy ?? false)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Semantics(
                  label: l.printUpdatingPreview,
                  liveRegion: true,
                  child: const ShadSpinner(size: 16),
                ),
              ),
            if (narrow)
              ShadTooltip(
                builder: (_) =>
                    Text(_showSettings ? l.printShowPreview : l.printSettings),
                child: ShadIconButton.ghost(
                  key: const ValueKey<String>('slides.print.toggleSettings'),
                  semanticLabel: _showSettings
                      ? l.printShowPreview
                      : l.printSettings,
                  icon: Icon(
                    _showSettings
                        ? LucideIcons.fileText
                        : LucideIcons.settings2,
                    size: 16,
                  ),
                  onPressed: () =>
                      setState(() => _showSettings = !_showSettings),
                ),
              ),
            const SizedBox(width: 4),
            if (narrow)
              ShadTooltip(
                builder: (_) => Text(l.printDownloadPdf),
                child: ShadIconButton.outline(
                  key: const ValueKey<String>('slides.print.download'),
                  semanticLabel: l.printDownloadPdf,
                  enabled: ready,
                  icon: const Icon(LucideIcons.download, size: 16),
                  onPressed: () => unawaited(download()),
                ),
              )
            else
              ShadButton.outline(
                key: const ValueKey<String>('slides.print.download'),
                enabled: ready,
                leading: const Icon(LucideIcons.download, size: 16),
                onPressed: () => unawaited(download()),
                child: Text(l.printDownloadPdf),
              ),
            const SizedBox(width: 8),
            if (narrow)
              ShadTooltip(
                builder: (_) => Text(l.printPrint),
                child: ShadIconButton(
                  key: const ValueKey<String>('slides.print.print'),
                  semanticLabel: l.printPrint,
                  enabled: ready,
                  icon: const Icon(LucideIcons.printer, size: 16),
                  onPressed: () => unawaited(print()),
                ),
              )
            else
              ShadButton(
                key: const ValueKey<String>('slides.print.print'),
                enabled: ready,
                leading: const Icon(LucideIcons.printer, size: 16),
                onPressed: () => unawaited(print()),
                child: Text(l.printPrint),
              ),
          ],
        ),
      ),
    );
  }

  Widget _preview(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final l = slidesL10n(context);
    final c = _controller;
    if (!_canExport) {
      return WonkyEmptyState(
        illustration: EmptyIllustration.noAccess,
        title: l.printDownloadsDisabledTitle,
        description: l.printDownloadsDisabledBody,
      );
    }
    final error = c?.error;
    if (error != null) {
      return WonkyEmptyState(
        illustration: isOfflineError(error)
            ? EmptyIllustration.offline
            : EmptyIllustration.error,
        title: l.printPreviewFailed,
        description: errorMessage(error),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('slides.print.retry'),
            onPressed: () => unawaited(c!.refresh()),
            child: Text(l.printTryAgain),
          ),
        ],
      );
    }
    final pdf = c?.pdf;
    if (pdf == null) {
      return ColoredBox(
        color: cs.muted,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ShadSpinner(),
              const SizedBox(height: 12),
              Text(
                c == null ? l.printLoadingDeck : l.printUpdatingPreview,
                style: ShadTheme.of(context).textTheme.muted,
              ),
            ],
          ),
        ),
      );
    }
    return ColoredBox(
      color: cs.muted,
      child: Semantics(
        label: l.printPdfPreviewLabel,
        container: true,
        child: PdfView(
          key: const ValueKey<String>('slides.print.preview'),
          bytes: pdf,
          desktopTitle: c!.pageCount == null
              ? l.printPdfReady
              : l.printPdfReadyPages(c.pageCount!),
          desktopHint: l.printPdfDesktopHint,
          thumbnails: true,
          fitPage: true,
        ),
      ),
    );
  }

  Widget _settings(BuildContext context) {
    final c = _controller;
    if (c == null) return const SizedBox.shrink();
    return PrintSettingsPanel(
      controller: c,
      canPrintBuilds: SlidesFeatures.isOn(SlidesFeature.printBuilds),
      hasSelection: (_editor?.selectedSlideIds.length ?? 0) > 1,
    );
  }
}
