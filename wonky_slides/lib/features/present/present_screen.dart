import 'dart:async';

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_client/wonky_client.dart'
    show PresentationRole, UuidValue;
import 'package:wonky_charts_flutter/wonky_charts_flutter.dart'
    show Chart3DBackends;
import 'package:wonky_slides_core/scene.dart' show ScenePurpose;
import 'package:wonky_ui/wonky_ui.dart';

import '../../commands/slides_command.dart'
    show SlidesKeyScopes, editorOfServices;
import '../../l10n/slides_l10n.dart';
import '../collab/follow_presenter.dart' show FollowerBar;
import '../editor_screen/deck_editor_controller.dart';
import '../navigator/deck_renderer.dart';
import '../settings/slides_user_defaults.dart';
import '../stage/slide_renderer.dart';
import 'active_presentation.dart';
import 'open_on_device_dialog.dart';
import 'platform/present_platform.dart';
import 'present_controller.dart';
import 'present_ink.dart';
import 'present_overlays.dart';
import 'present_stage.dart';
import 'presentation_link.dart';
import 'presenter_view.dart';
import 'slide_picker.dart';
import 'tools/kiosk_exit.dart';

/// The present route `/slides/p/:uuid/present` (Slides 10 §1.1) over the
/// deck editor, which stays mounted underneath (its session, selection and
/// panels are restored when presenting ends):
///
/// - `view=` absent — **present mode**: the audience rendering in this
///   window, full screen (the full-window fallback shows a 4 s hint), no
///   session (no network needed);
/// - `view=presenter` — the **presenter view** in this window; it creates a
///   presentation session for the audience on another device or browser
///   (*Open on another device…*, `share=1` opens it at once);
/// - `view=audience&session=<id>` — the **audience view** on another device
///   or browser, following the presenter; its navigation is sent to the
///   presenter as commands.
///
/// Keys run in keymap scope `present` (digits + `Enter` = *Go to slide n*;
/// `Esc` closes the innermost overlay or tool first). The cursor hides
/// after 2 s without movement; the present toolbar shows when the pointer
/// moves near the bottom-left. Leaving full screen through the browser ends
/// present mode (unless `keepPresentingOutsideFullscreen`).
class PresentScreen extends StatefulWidget {
  const PresentScreen({
    super.key,
    required this.services,
    required this.itemUuid,
    this.view = PresentView.present,
    this.startSlideId,
    this.startStep = 0,
    this.sessionId,
    this.share = false,
    this.kiosk = false,
    this.nowMs,
  });

  final ShellServices services;
  final String itemUuid;
  final PresentView view;

  /// `?slide=` (null: the first presented slide).
  final String? startSlideId;
  final int startStep;

  /// `?session=` (audience views).
  final String? sessionId;

  /// `?share=1`: the presenter view opens *Open on another device…* once
  /// the session is ready.
  final bool share;

  /// `?kiosk=1`: self-running kiosk mode (10 §9).
  final bool kiosk;

  /// Clock (tests).
  final int Function()? nowMs;

  @override
  State<PresentScreen> createState() => _PresentScreenState();
}

class _PresentScreenState extends State<PresentScreen>
    implements PresentHandle {
  final _focus = FocusNode(debugLabel: 'slides.present');
  DeckEditorController? _editor;
  Listenable? _doc;
  SlideRenderer? _renderer;
  PresentController? _controller;
  PresentationLink? _link;
  void Function()? _unlistenFullscreen;
  void Function()? _releaseKeys;
  bool _wasFullscreen = false;
  bool _hint = false;
  Timer? _hintTimer;
  bool _startCardDismissed = false;
  bool _idle = false;
  Timer? _idleTimer;
  bool _toolbar = false;
  Timer? _toolbarTimer;
  bool _leaving = false;
  bool _shared = false;
  bool _askingTakeover = false;
  bool _pickerWasOpen = false;
  late final KioskExitGesture _kioskExit = KioskExitGesture(
    onExit: () => _controller?.end(),
    nowMs: widget.nowMs,
  );

  ShellServices get s => widget.services;

  @override
  PresentController? get controller => _controller;

  @override
  PresentationLink? get link => _link;

  @override
  PresentView get view => widget.view;

  @override
  void initState() {
    super.initState();
    activePresentation.value = this;
    s.activeDocument.addListener(_attach);
    final platform = PresentPlatform.instance;
    _unlistenFullscreen = platform.listenFullscreen(_onFullscreen);
    _releaseKeys = platform.captureReloadKeys();
    _wasFullscreen = platform.isFullscreen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attach();
      if (!mounted) return;
      if (widget.view == PresentView.present &&
          !PresentPlatform.instance.isFullscreen) {
        // Full screen was refused (or not asked for): full window + hint.
        setState(() => _hint = true);
        _hintTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _hint = false);
        });
      }
    });
    _bumpIdle();
  }

  @override
  void dispose() {
    s.activeDocument.removeListener(_attach);
    _doc?.removeListener(_attach);
    _unlistenFullscreen?.call();
    _releaseKeys?.call();
    _hintTimer?.cancel();
    _idleTimer?.cancel();
    _toolbarTimer?.cancel();
    _controller?.removeListener(_onController);
    _link?.removeListener(_onLink);
    final c = _controller;
    final link = _link;
    if (c != null && !c.ended && widget.view == PresentView.presenter) {
      // The route was left without *End* (back button, deep link): the
      // session ends for the audience too.
      unawaited(link?.end());
    }
    c?.dispose();
    link?.dispose();
    _kioskExit.dispose();
    final ed = _editor;
    final r = _renderer;
    if (ed != null && r != null) DeckThumbnails.release(ed, r);
    if (activePresentation.value == this) activePresentation.value = null;
    _focus.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- attach

  void _attach() {
    if (!mounted) return;
    final doc = s.activeDocument.value;
    if (!identical(doc, _doc)) {
      _doc?.removeListener(_attach);
      _doc = doc;
      doc?.addListener(_attach);
    }
    final ed = editorOfServices(s);
    if (_controller == null && ed != null && ed.isReady) _start(ed);
  }

  void _start(DeckEditorController ed) {
    _editor = ed;
    _renderer = DeckThumbnails.acquire(ed);
    final prefs = SlidesUserDefaults.of(s);
    PresentationLink? link;
    if (widget.view != PresentView.present) {
      final transport = presentationTransportOf(s);
      final member = widget.view.isMember;
      if (transport != null && (!member || widget.sessionId != null)) {
        link = PresentationLink(
          transport: transport,
          deckUuid: UuidValue.fromString(widget.itemUuid),
          role: switch (widget.view) {
            PresentView.audience => PresentationRole.audience,
            // Collaborators following along (SL-37, 10 §6.3).
            PresentView.follower => PresentationRole.follower,
            _ => PresentationRole.presenter,
          },
          deviceLabel: PresentPlatform.instance.deviceLabel,
          sessionId: widget.sessionId,
          nowMs: widget.nowMs,
        );
      }
    }
    final c = PresentController(
      model: ed.model,
      view: widget.view,
      startSlideId: widget.startSlideId,
      startStep: widget.startStep,
      link: link,
      nowMs: widget.nowMs,
      showSkipped:
          widget.view == PresentView.presenter &&
          prefs.presenterFlag(SlidesUserDefaults.keyShowSkippedInPresenter),
      notesSize: prefs
          .presenterInt(SlidesUserDefaults.keyNotesSize)
          .clamp(12, 48),
      reducedMotion: WonkyThemeScope.of(context).reduceMotion,
      scenesOf: (id) => _renderer?.scene(id, purpose: ScenePurpose.present),
      kiosk: widget.kiosk,
    );
    c.onEnd = _leave;
    c.onPrefetch3dChart = Chart3DBackends.ensureStarted;
    c.addListener(_onController);
    _controller = c;
    _link = link;
    link?.addListener(_onLink);
    link?.start();
    if (widget.view == PresentView.presenter) _extendedDisplayHint();
    setState(() {});
    _focus.requestFocus();
  }

  /// One-time hint with an extended display (10 §5.2).
  void _extendedDisplayHint() {
    if (!PresentPlatform.instance.screenIsExtended) return;
    const key = 'slides.present.extendedHintShown';
    unawaited(() async {
      try {
        if (await s.userStore.read(key) == true) return;
        await s.userStore.write(key, true);
      } on Object {
        return;
      }
      if (!mounted) return;
      final l = slidesL10nOf(s);
      s.toasts.show(
        l.presentExtendedHintTitle,
        description: l.presentExtendedHintBody,
      );
    }());
  }

  void _onController() {
    final c = _controller;
    if (c == null || !mounted) return;
    if (_pickerWasOpen && !c.pickerOpen) _focus.requestFocus();
    _pickerWasOpen = c.pickerOpen;
  }

  void _onLink() {
    final link = _link;
    if (link == null || !mounted) return;
    final l = slidesL10nOf(s);
    if (widget.view == PresentView.presenter) {
      if (link.status == PresentationLinkStatus.connected &&
          widget.share &&
          !_shared) {
        _shared = true;
        unawaited(openOnAnotherDevice());
      }
      if (link.status == PresentationLinkStatus.ended &&
          link.endedReason == 'presenterActive' &&
          !_askingTakeover) {
        unawaited(_askTakeover());
      }
      if (link.status == PresentationLinkStatus.ended &&
          link.endedReason == 'takenOver') {
        s.toasts.show(l.presentTakenOverToast);
        _leave();
      }
    } else if (link.status == PresentationLinkStatus.ended) {
      switch (link.endedReason) {
        case 'ended' || 'expired':
          s.toasts.show(l.presentAudienceEndedToast);
          _leave();
        default:
          setState(() {});
      }
    }
  }

  Future<void> _askTakeover() async {
    _askingTakeover = true;
    final l = slidesL10nOf(s);
    final ctx = s.navigatorKey.currentContext ?? context;
    final r = await showWonkyFormDialog(
      ctx,
      WonkyDialogSpec(
        title: l.presentTakeOverTitle,
        description: l.presentTakeOverBody,
        dialogKey: 'dialog.slides.takeOver',
        buttons: [
          DialogButtonSpec(id: 'cancel', label: l.presentTakeOverCancel),
          DialogButtonSpec(
            id: 'takeOver',
            label: l.presentTakeOver,
            primary: true,
          ),
        ],
      ),
    );
    _askingTakeover = false;
    if (!mounted) return;
    if (r?.buttonId == 'takeOver') {
      _link?.start(takeOver: true);
    } else {
      // Present alone in this window; the other window keeps the session.
      setState(() {});
    }
  }

  // --------------------------------------------------------- full screen

  void _onFullscreen(bool fullscreen) {
    if (!mounted) return;
    if (fullscreen) {
      _wasFullscreen = true;
      _hintTimer?.cancel();
      setState(() {
        _hint = false;
        _startCardDismissed = true;
      });
      return;
    }
    final c = _controller;
    if (_wasFullscreen &&
        widget.view == PresentView.present &&
        c != null &&
        !c.settings.keepPresentingOutsideFullscreen) {
      // Leaving full screen by the browser (Esc, F11) ends present mode at
      // the shown slide (10 §1.3).
      c.end();
      return;
    }
    _wasFullscreen = false;
    setState(() {});
  }

  @override
  Future<void> toggleFullscreen() async {
    final p = PresentPlatform.instance;
    if (p.isFullscreen) {
      // A deliberate toggle doesn't end present mode.
      _wasFullscreen = false;
      await p.exitFullscreen();
    } else {
      final ok = await p.requestFullscreen();
      if (ok) _wasFullscreen = true;
    }
    if (mounted) setState(() {});
  }

  // ------------------------------------------------------------ actions

  @override
  Future<void> openOnAnotherDevice() async {
    final link = _link;
    final id = link?.sessionId;
    final l = slidesL10nOf(s);
    if (link == null || id == null) {
      s.toasts.show(
        l.presentOfflineNoDevices,
        description: l.presentOfflineNoDevicesBody,
      );
      return;
    }
    final ctx = s.navigatorKey.currentContext ?? context;
    await showOpenOnDeviceDialog(
      ctx,
      link: audienceLink(s, widget.itemUuid, id),
      online: s.connectivity.online,
    );
    if (mounted) _focus.requestFocus();
  }

  /// Back to the editor at the shown slide (10 §1.3); ink is discarded.
  void _leave() {
    if (_leaving || !mounted) return;
    _leaving = true;
    final c = _controller;
    if (c != null && !c.ended) c.end();

    unawaited(PresentPlatform.instance.exitFullscreen());
    final ed = _editor;
    final shown = c?.position?.slideId;
    if (ed != null && shown != null && !widget.view.isMember) {
      ed.setCurrentSlide(shown);
    }
    s.router.go(s.config.itemPath(widget.itemUuid));
  }

  void _openContextMenu(Offset global) {
    final c = _controller;
    if (c == null) return;
    final ctx = _menuKey.currentContext;
    if (ctx == null) return;
    WonkyPopupMenuHost.maybeOf(ctx)?.show(
      global,
      () => presentContextMenu(ctx, s, c),
      onClosed: _focus.requestFocus,
    );
  }

  final _menuKey = GlobalKey();

  // ------------------------------------------------------------- input

  static final _digits = <LogicalKeyboardKey, int>{
    LogicalKeyboardKey.digit0: 0,
    LogicalKeyboardKey.digit1: 1,
    LogicalKeyboardKey.digit2: 2,
    LogicalKeyboardKey.digit3: 3,
    LogicalKeyboardKey.digit4: 4,
    LogicalKeyboardKey.digit5: 5,
    LogicalKeyboardKey.digit6: 6,
    LogicalKeyboardKey.digit7: 7,
    LogicalKeyboardKey.digit8: 8,
    LogicalKeyboardKey.digit9: 9,
    LogicalKeyboardKey.numpad0: 0,
    LogicalKeyboardKey.numpad1: 1,
    LogicalKeyboardKey.numpad2: 2,
    LogicalKeyboardKey.numpad3: 3,
    LogicalKeyboardKey.numpad4: 4,
    LogicalKeyboardKey.numpad5: 5,
    LogicalKeyboardKey.numpad6: 6,
    LogicalKeyboardKey.numpad7: 7,
    LogicalKeyboardKey.numpad8: 8,
    LogicalKeyboardKey.numpad9: 9,
  };

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final c = _controller;
    if (c == null) return KeyEventResult.ignored;
    final k = event.logicalKey;
    if (c.kiosk) {
      // Kiosk: only the exit gesture (10 §9).
      if (k == LogicalKeyboardKey.escape) {
        if (event is KeyDownEvent) {
          _kioskExit.down(hold: c.settings.kioskExitGesture == 'holdEsc');
        } else if (event is KeyUpEvent) {
          _kioskExit.cancel();
        }
      }
      return KeyEventResult.handled;
    }
    final kb = HardwareKeyboard.instance;
    final mod = kb.isMetaPressed || kb.isControlPressed;
    if (k == LogicalKeyboardKey.metaLeft ||
        k == LogicalKeyboardKey.metaRight ||
        k == LogicalKeyboardKey.controlLeft ||
        k == LogicalKeyboardKey.controlRight) {
      // Holding Mod shows the laser while the mouse moves (10 §2.1).
      c.setTemporaryLaser(event is! KeyUpEvent);
      _showToolbar();
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final digit = _digits[k];
    if (digit != null && !mod && !kb.isAltPressed && !kb.isShiftPressed) {
      c.typeDigit(digit);
      return KeyEventResult.handled;
    }
    if ((k == LogicalKeyboardKey.enter ||
            k == LogicalKeyboardKey.numpadEnter) &&
        c.numberEntry != null) {
      c.commitNumber();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape && c.escape()) {
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.question) {
      c.setHelp(!c.helpOpen);
      return KeyEventResult.handled;
    }
    if (c.helpOpen && k != LogicalKeyboardKey.escape) {
      // Any other key closes the help first.
      c.setHelp(false);
    }
    return KeyEventResult.ignored;
  }

  void _bumpIdle() {
    _idleTimer?.cancel();
    if (_idle) setState(() => _idle = false);
    _idleTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _idle = true);
    });
  }

  void _showToolbar() {
    _toolbarTimer?.cancel();
    if (!_toolbar && mounted) setState(() => _toolbar = true);
    _toolbarTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toolbar = false);
    });
  }

  void _onHover(PointerEvent e, Size size) {
    _bumpIdle();
    // The toolbar shows near the bottom-left (10 §4.1).
    if (e.localPosition.dy > size.height - 140 &&
        e.localPosition.dx < size.width * 0.6) {
      _showToolbar();
    }
  }

  // ------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final reduceMotion = WonkyThemeScope.of(context).reduceMotion;
    _controller?.reducedMotion = reduceMotion;
    return KeymapScope(
      scope: SlidesKeyScopes.present,
      keymap: s.keymap,
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Material(
          type: MaterialType.transparency,
          child: WonkyPopupMenuHost(
            child: KeyedSubtree(
              key: _menuKey,
              child: _body(context, reduceMotion),
            ),
          ),
        ),
      ),
    );
  }

  /// The mobile presenter mode (10 §1.6): the whole window, in the app
  /// theme's colors, with the presenter bar on top — close (`end`), back
  /// (`previous`) and forward (`next`) — over the slide (taps and swipes
  /// navigate as in present mode).
  Widget _mobilePresenter(
    BuildContext context,
    PresentController c,
    SlideRenderer r,
    bool reduceMotion,
    List<Widget> overlays,
  ) {
    final theme = ShadTheme.of(context);
    final (current, total) = c.counter;
    final p = c.position;
    final canGoBack =
        c.endScreen || (p != null && c.sequence.previous(p) != null);
    void run(String id) => unawaited(
      s.dispatcher.invoke(id, source: InvocationSource.ui, context: context),
    );
    return ColoredBox(
      key: const ValueKey<String>('slides.present.mobile'),
      color: theme.colorScheme.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WonkyPresenterBar(
              title: c.model.deck?.title ?? '',
              current: current,
              total: total,
              onClose: () => run('slides.present.end'),
              onPrevious: canGoBack
                  ? () => run('slides.present.previous')
                  : null,
              onNext: p != null || c.endScreen
                  ? () => run('slides.present.next')
                  : null,
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PresentStage(
                      key: const ValueKey<String>('slides.present.stage'),
                      controller: c,
                      renderer: r,
                      letterbox: theme.colorScheme.background,
                      onSecondaryTap: _openContextMenu,
                      reduceMotion: reduceMotion || c.settings.reduceMotion,
                    ),
                  ),
                  ...overlays,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, bool reduceMotion) {
    final l = slidesL10n(context);
    final c = _controller;
    final r = _renderer;
    if (widget.view.isMember &&
        (widget.sessionId == null ||
            (c != null && _link == null) ||
            const {'notFound', 'noAccess'}.contains(_link?.endedReason))) {
      return _AudienceUnavailable(
        reason: _link?.endedReason,
        offline: _link == null && widget.sessionId != null,
        onBack: _leave,
      );
    }
    if (c == null || r == null) {
      return ColoredBox(
        key: const ValueKey<String>('slides.present.loading'),
        color: const Color(0xff000000),
        child: Center(
          child: Semantics(
            label: l.deckLoading,
            child: const ShadSpinner(color: Color(0xffe5e7eb)),
          ),
        ),
      );
    }
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final narrow = MediaQuery.sizeOf(context).width < 600;
        final overlays = <Widget>[
          if (c.pickerOpen)
            Positioned.fill(
              child: SlidePicker(
                controller: c,
                renderer: r,
                services: s,
                deckId: _editor!.session.deckId,
              ),
            ),
          if (c.numberEntry != null)
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: Center(child: GoToNumberOverlay(number: c.numberEntry!)),
            ),
          if (c.helpOpen)
            Positioned.fill(
              child: PresentHelpOverlay(
                services: s,
                onClose: () => c.setHelp(false),
              ),
            ),
        ];
        if (widget.view == PresentView.presenter) {
          return Stack(
            key: const ValueKey<String>('slides.present.presenterView'),
            children: [
              Positioned.fill(
                child: PresenterView(
                  services: s,
                  controller: c,
                  renderer: r,
                  title: c.model.deck?.title ?? '',
                  onOpenOnDevice: () => unawaited(openOnAnotherDevice()),
                  onContextMenu: _openContextMenu,
                ),
              ),
              ...overlays,
            ],
          );
        }
        if (WonkyLayout.isMobile(context) &&
            widget.view == PresentView.present &&
            !c.kiosk) {
          return _mobilePresenter(context, c, r, reduceMotion, overlays);
        }
        final link = _link;
        final waiting =
            link != null &&
            (link.status == PresentationLinkStatus.reconnecting ||
                link.status == PresentationLinkStatus.connecting ||
                !link.presenterConnected);
        return LayoutBuilder(
          builder: (context, box) => MouseRegion(
            cursor: (_idle || c.kiosk) && c.tool == PresentTool.arrow
                ? SystemMouseCursors.none
                : MouseCursor.defer,
            onHover: (e) => _onHover(e, box.biggest),
            child: Listener(
              onPointerMove: (e) => _onHover(e, box.biggest),
              child: Stack(
                key: ValueKey<String>('slides.present.${widget.view.name}'),
                children: [
                  Positioned.fill(
                    child: PresentStage(
                      key: const ValueKey<String>('slides.present.stage'),
                      controller: c,
                      renderer: r,
                      onSecondaryTap: c.kiosk ? null : _openContextMenu,
                      interactive: !c.kiosk,
                      reduceMotion: reduceMotion || c.settings.reduceMotion,
                    ),
                  ),
                  if (c.kiosk)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 48,
                      child: Center(
                        child: KioskExitRing(
                          gesture: _kioskExit,
                          label: l.presentKioskExitHold,
                        ),
                      ),
                    ),
                  if (c.position == null && !c.catchingUp && !c.endScreen)
                    Positioned.fill(
                      child: Center(
                        child: Text(
                          widget.view.isMember
                              ? l.presentWaitingForPresenter
                              : l.reasonNoSlides,
                          style: const TextStyle(
                            color: Color(0xff9ca3af),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  if (waiting && c.position != null)
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _StatusPill(
                          text: link.status == PresentationLinkStatus.connected
                              ? l.presentPresenterAway
                              : l.presentConnecting,
                        ),
                      ),
                    ),
                  if (_hint)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Center(
                        child: FullscreenHint(
                          onFullscreen: () => unawaited(toggleFullscreen()),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    right: 16,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: IgnorePointer(
                        ignoring:
                            !_toolbar ||
                            c.kiosk ||
                            widget.view == PresentView.follower,
                        child: AnimatedOpacity(
                          opacity:
                              _toolbar &&
                                  !c.kiosk &&
                                  widget.view != PresentView.follower
                              ? 1
                              : 0,
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 150),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: PresentToolbar(
                              services: s,
                              controller: c,
                              compact: narrow,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Following a collaborator's presentation (SL-37).
                  if (widget.view == PresentView.follower)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Center(
                        child: FollowerBar(
                          services: s,
                          controller: c,
                          sessionId: widget.sessionId,
                          fullscreen: PresentPlatform.instance.isFullscreen,
                          onFullscreen: () {
                            unawaited(toggleFullscreen());
                            _focus.requestFocus();
                          },
                        ),
                      ),
                    ),
                  if (widget.view == PresentView.audience &&
                      !_startCardDismissed &&
                      !PresentPlatform.instance.isFullscreen)
                    Positioned.fill(
                      child: ColoredBox(
                        color: const Color(0x66000000),
                        child: AudienceStartCard(
                          presenterDevice: link?.presenterDevice,
                          onFullscreen: () {
                            setState(() => _startCardDismissed = true);
                            unawaited(toggleFullscreen());
                            _focus.requestFocus();
                          },
                          onStay: () {
                            setState(() => _startCardDismissed = true);
                            _focus.requestFocus();
                          },
                        ),
                      ),
                    ),
                  ...overlays,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        key: const ValueKey<String>('slides.present.status'),
        decoration: BoxDecoration(
          color: theme.colorScheme.popover.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.colorScheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(text, style: theme.textTheme.small),
        ),
      ),
    );
  }
}

/// The audience view can't follow: unknown session, no access, or no
/// server (10 §7: other devices need the server to join).
class _AudienceUnavailable extends StatelessWidget {
  const _AudienceUnavailable({
    required this.reason,
    required this.offline,
    required this.onBack,
  });

  final String? reason;
  final bool offline;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = slidesL10n(context);
    final theme = ShadTheme.of(context);
    return ColoredBox(
      key: const ValueKey<String>('slides.present.audienceUnavailable'),
      color: theme.colorScheme.background,
      child: WonkyEmptyState(
        illustration: offline
            ? EmptyIllustration.offline
            : reason == 'noAccess'
            ? EmptyIllustration.noAccess
            : EmptyIllustration.error,
        title: offline
            ? l.presentOfflineNoDevices
            : reason == 'noAccess'
            ? l.presentAudienceNoAccess
            : l.presentAudienceNotFound,
        description: offline
            ? l.presentOfflineNoDevicesBody
            : l.presentAudienceNotFoundBody,
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>(
              'slides.present.audienceUnavailable.back',
            ),
            onPressed: onBack,
            child: Text(l.backToPresentation),
          ),
        ],
      ),
    );
  }
}
