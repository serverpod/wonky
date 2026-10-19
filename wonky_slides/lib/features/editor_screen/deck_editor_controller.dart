import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/session.dart' show SlidesRowsUndoEntry;

import '../../config/slides_features.dart';
import '../model/deck_session.dart';
import '../settings/slides_user_defaults.dart';
import 'chrome_prefs.dart';

/// The editor's view modes (Slides 04 §2: Normal, Grid, Outline, Masters).
enum DeckViewMode {
  normal,
  grid,
  outline,
  masters;

  static DeckViewMode? fromName(Object? name) {
    for (final m in values) {
      if (m.name == name) return m;
    }
    return null;
  }
}

/// The docked inspector's tabs (04 §7.1).
enum InspectorTab {
  format,
  animate,
  slide,

  /// The theme editor (masters mode only, 05 §8.4; SL-28).
  theme;

  static InspectorTab? fromName(Object? name) {
    for (final t in values) {
      if (t.name == name) return t;
    }
    return null;
  }
}

/// What is selected, for the contextual toolbar (04 §6.2) and the
/// Format tab (04 §7.2).
enum DeckSelectionKind {
  none,
  text,
  shape,
  line,
  image,
  table,
  code,
  chart,
  icon,
  group,
  multiple,
}

/// The editor state of one open deck (Slides 04 §2, 03 §1.1): the session,
/// the role and Editing/Viewing mode, the **current slide** and the
/// navigator selection, the element selection (a minimal model SL-12
/// extends), the view mode, the chrome panes (navigator, inspector, notes),
/// zoom and the View › Show toggles. Commands read and change it through
/// `editorOf(ctx)`; every widget of the editor screen listens to it.
///
/// [apply] is the write path of every Slides command: it executes an
/// operation on the session and records the plan as one `slides.rows`
/// undo entry in the command's transaction.
class DeckEditorController extends ChangeNotifier {
  DeckEditorController({
    required this.services,
    required this.session,
    this._itemRole = Role.owner,
    SlidesChromePrefs? prefs,
    String? initialSlideId,
  }) : _prefs = prefs ?? SlidesChromePrefs() {
    _currentSlideId = _validSlide(initialSlideId) ?? _firstSlide();
    if (_currentSlideId != null) _selectedSlideIds.add(_currentSlideId!);
    session.model.addListener(_onBatch);
    session.role.addListener(_onRole);
    session.loadState.addListener(notifyListeners);
    services.prefs.addListener(notifyListeners);
  }

  final ShellServices services;
  final DeckSession session;

  /// Per-device chrome preferences (written when they change).
  final SlidesChromePrefs _prefs;

  DeckModel get model => session.model;

  /// The deck's slide order (presentation order, groups, numbers).
  SlideOrder get order => model.indexes.order;

  /// Resolves slides for the previews (memoized per slide revision).
  late final SlideResolver resolver = SlideResolver(model);

  /// The Slides settings (snap and guide preferences, defaults).
  SlidesUserDefaults get defaults => SlidesUserDefaults.of(services);

  bool _disposed = false;

  // ------------------------------------------------------------------ role

  Role _itemRole;

  /// The user's role on the drive item (the session's role can be lower
  /// while the deck opens).
  Role get itemRole => _itemRole;
  set itemRole(Role value) {
    if (value == _itemRole) return;
    _itemRole = value;
    if (!roleCanEdit) _viewMode = false;
    _leaveMastersIfReadOnly();
    notifyListeners();
  }

  /// The effective role (the lower of the item's and the deck space's).
  Role get role {
    final r = session.role.value;
    return r < _itemRole ? r : _itemRole;
  }

  bool _readOnlyView = false;

  /// The mobile read-only view (suite 02 §6.1, 04 §16): no editing
  /// whatever the role, and View › Mode › Editing is off.
  bool get readOnlyView => _readOnlyView;
  set readOnlyView(bool value) {
    if (value == _readOnlyView) return;
    _readOnlyView = value;
    if (value) {
      _viewMode = false;
      textEditing = false;
      _selectedElementIds.clear();
    }
    _leaveMastersIfReadOnly();
    notifyListeners();
  }

  /// Whether the role allows editing (independent of Viewing mode; never in
  /// the mobile read-only view).
  bool get roleCanEdit => !_readOnlyView && role >= Role.editor;

  bool get isReady => session.loadState.value is DeckReady;

  bool _viewMode = false;

  /// View › Mode › Viewing for editors (04 §4.3).
  bool get viewMode => _viewMode || !roleCanEdit;

  void setViewMode(bool viewing) {
    if (viewing == _viewMode || (!viewing && !roleCanEdit)) return;
    _viewMode = viewing;
    _leaveMastersIfReadOnly();
    notifyListeners();
  }

  /// Whether mutating commands are enabled (04 §0 `edit`).
  bool get canEdit => roleCanEdit && !_viewMode && isReady;

  void _onRole() {
    if (!roleCanEdit) _viewMode = false;
    _leaveMastersIfReadOnly();
    notifyListeners();
  }

  /// Masters mode edits layouts: viewers and Viewing mode leave it (05 §8).
  void _leaveMastersIfReadOnly() {
    if (_mode == DeckViewMode.masters && (!roleCanEdit || _viewMode)) {
      _mode = DeckViewMode.normal;
      _selectedElementIds.clear();
      textEditing = false;
    }
  }

  // --------------------------------------------------------- current slide

  String? _currentSlideId;
  final Set<String> _selectedSlideIds = {};
  final Set<String> _selectedGroupIds = {};

  /// The slide the canvas shows (null in an empty deck).
  String? get currentSlideId => _currentSlideId;

  /// The current slide's entry in the presentation order.
  SlideOrderEntry? get currentEntry =>
      _currentSlideId == null ? null : order.entry(_currentSlideId!);

  /// The navigator selection (04 §5.5): slides and group headers. The
  /// navigator (SL-16) drives it; the current slide is always selected.
  Set<String> get selectedSlideIds => Set.unmodifiable(_selectedSlideIds);
  Set<String> get selectedGroupIds => Set.unmodifiable(_selectedGroupIds);

  String? _validSlide(String? id) =>
      id != null && order.entry(id) != null ? id : null;

  String? _firstSlide() =>
      order.entries.isEmpty ? null : order.entries.first.id;

  /// Makes [slideId] the current slide; with [select] it becomes the only
  /// selected slide (a click in the navigator).
  void setCurrentSlide(String slideId, {bool select = true}) {
    if (order.entry(slideId) == null) return;
    final changed = slideId != _currentSlideId;
    _currentSlideId = slideId;
    _lastIndex = order.indexOf(slideId);
    if (select) {
      _selectedSlideIds
        ..clear()
        ..add(slideId);
      _selectedGroupIds.clear();
    } else {
      _selectedSlideIds.add(slideId);
    }
    if (changed) _selectedElementIds.clear();
    notifyListeners();
  }

  /// Sets the navigator selection (SL-16's navigator and grid view).
  void selectSlides(
    Iterable<String> slideIds, {
    Iterable<String> groups = const [],
  }) {
    _selectedSlideIds
      ..clear()
      ..addAll(slideIds.where((id) => order.entry(id) != null));
    _selectedGroupIds
      ..clear()
      ..addAll(groups);
    final cur = _currentSlideId;
    if (cur != null && !_selectedSlideIds.contains(cur)) {
      if (_selectedSlideIds.isNotEmpty) {
        _currentSlideId = _selectedSlideIds.last;
      } else {
        _selectedSlideIds.add(cur);
      }
    }
    notifyListeners();
  }

  /// Moves the current slide by [delta] positions in presentation order.
  /// Returns whether it moved.
  bool stepSlide(int delta) {
    final entries = order.entries;
    if (entries.isEmpty) return false;
    final i = _currentSlideId == null ? -1 : order.indexOf(_currentSlideId!);
    final next = (i < 0 ? 0 : i + delta).clamp(0, entries.length - 1);
    if (next == i) return false;
    setCurrentSlide(entries[next].id);
    return true;
  }

  // ----------------------------------------------------- element selection

  final List<String> _selectedElementIds = [];

  /// The selected elements of the current slide (SL-12's selection model
  /// replaces this minimal list; the chrome only needs ids and kinds).
  List<String> get selectedElementIds => List.unmodifiable(_selectedElementIds);

  /// Whether a text body is being edited (SL-13 sets it).
  bool textEditing = false;

  void selectElements(Iterable<String> ids) {
    _selectedElementIds
      ..clear()
      ..addAll(ids.where((id) => model.element(id) != null));
    notifyListeners();
  }

  void clearElementSelection() {
    if (_selectedElementIds.isEmpty && !textEditing) return;
    _selectedElementIds.clear();
    textEditing = false;
    notifyListeners();
  }

  /// The kind of the selection (04 §6.2).
  DeckSelectionKind get selectionKind {
    final ids = _selectedElementIds;
    if (ids.isEmpty) {
      return textEditing ? DeckSelectionKind.text : DeckSelectionKind.none;
    }
    if (ids.length > 1) return DeckSelectionKind.multiple;
    if (textEditing) return DeckSelectionKind.text;
    final e = model.element(ids.single);
    return switch (e?.kind) {
      null => DeckSelectionKind.none,
      ElementKind.text => DeckSelectionKind.text,
      ElementKind.shape => DeckSelectionKind.shape,
      ElementKind.line => DeckSelectionKind.line,
      ElementKind.image => DeckSelectionKind.image,
      ElementKind.table => DeckSelectionKind.table,
      ElementKind.icon => DeckSelectionKind.icon,
      ElementKind.code => DeckSelectionKind.code,
      ElementKind.chart => DeckSelectionKind.chart,
      ElementKind.group => DeckSelectionKind.group,
    };
  }

  // ------------------------------------------------------------------ tool

  String? _armedTool;

  /// The armed insert tool (`text`, `shape`, …; SL-12+), null = Select.
  String? get armedTool => _armedTool;

  void armTool(String? tool) {
    if (tool == _armedTool) return;
    _armedTool = tool;
    notifyListeners();
  }

  // ------------------------------------------------------------- view mode

  DeckViewMode _mode = DeckViewMode.normal;

  DeckViewMode get mode => _mode;

  /// Whether [mode] is offered (outline view and masters are hidden until
  /// SL-34/SL-28, [SlidesFeatures]).
  static bool offersMode(DeckViewMode mode) => switch (mode) {
    DeckViewMode.outline => SlidesFeatures.isOn(SlidesFeature.outlineView),
    DeckViewMode.masters => SlidesFeatures.isOn(SlidesFeature.masters),
    _ => true,
  };

  /// Switches the view mode. Entering masters mode edits [masterTarget]
  /// (a layout or master id), else the current slide's layout (05 §8.1).
  void setMode(DeckViewMode mode, {String? masterTarget}) {
    if (mode == DeckViewMode.masters &&
        _mode == DeckViewMode.masters &&
        masterTarget != null) {
      setMasterTarget(masterTarget);
      return;
    }
    if (mode == _mode || !offersMode(mode)) return;
    // Masters mode edits layouts: editors in Editing mode only (05 §8).
    if (mode == DeckViewMode.masters && (!roleCanEdit || _viewMode)) return;
    final leaving = _mode == DeckViewMode.masters;
    _mode = mode;
    if (mode == DeckViewMode.masters) {
      _masterTargetId =
          _validTarget(masterTarget) ??
          _defaultTarget() ??
          _validTarget(_masterTargetId);
      _selectedElementIds.clear();
      textEditing = false;
    } else if (leaving) {
      _selectedElementIds.clear();
      textEditing = false;
    }
    notifyListeners();
  }

  // ---------------------------------------------------- masters (SL-28)

  String? _masterTargetId;

  /// The layout or master edited in masters mode (05 §8.1), kept while
  /// the mode is left so returning shows it again.
  String? get masterTargetId => _masterTargetId;

  /// The surface the canvas shows and edits: the current slide, or in
  /// masters mode the layout or master being edited (null when there is
  /// nothing to show).
  String? get surfaceId => _mode == DeckViewMode.masters
      ? _validTarget(_masterTargetId)
      : _currentSlideId;

  /// The owner kind of [surfaceId] (inserted elements are owned by it).
  ElementOwnerKind get surfaceKind {
    if (_mode != DeckViewMode.masters) return ElementOwnerKind.slide;
    final id = _masterTargetId;
    if (id != null && model.layout(id) != null) return ElementOwnerKind.layout;
    return ElementOwnerKind.master;
  }

  /// Whether the canvas edits a layout or master (masters mode).
  bool get editsMasters => _mode == DeckViewMode.masters;

  /// Makes layout or master [id] the edited surface (the selection is
  /// cleared). Ignored for unknown ids.
  void setMasterTarget(String id) {
    if (_validTarget(id) == null) return;
    if (id == _masterTargetId) return;
    _masterTargetId = id;
    if (_mode == DeckViewMode.masters) {
      _selectedElementIds.clear();
      textEditing = false;
    }
    notifyListeners();
  }

  String? _validTarget(String? id) =>
      id != null && (model.layout(id) != null || model.master(id) != null)
      ? id
      : null;

  /// The current slide's layout, else the first layout (or master) of the
  /// default theme.
  String? _defaultTarget() {
    final slide = _currentSlideId == null
        ? null
        : model.slide(_currentSlideId!);
    final layout = slide == null
        ? null
        : model.indexes.themes.effectiveLayout(slide);
    if (layout != null) return layout.id;
    final theme = model.defaultTheme ?? model.themes.firstOrNull;
    if (theme == null) return null;
    for (final m in model.mastersOf(theme.id)) {
      final layouts = model.layoutsOf(m.id);
      return layouts.isEmpty ? m.id : layouts.first.id;
    }
    return null;
  }

  // ----------------------------------------------------------------- panes

  // Widths (04 §16): ≥ 1,200 px everything docked; 768–1,200 the
  // inspector overlays the canvas; < 768 the navigator is a drawer and the
  // notes pane starts collapsed (also below 1,024). The overlay/drawer
  // states are transient (not stored).
  double _layoutWidth = 1440;
  bool _navigatorDrawer = false;
  bool _inspectorOverlay = false;
  bool _notesOpen = false;

  /// The editor body's width (reported during layout).
  double get layoutWidth => _layoutWidth;

  /// Below 768 px: navigator drawer, overlays over a scrim (04 §16).
  bool get isNarrow => _layoutWidth < 768;

  /// Below 1,200 px the inspector overlays the canvas.
  bool get inspectorOverlays => _layoutWidth < 1200;

  bool get _notesTransient => _layoutWidth < 1024;

  /// Called by the editor body during layout; crossing a width threshold
  /// closes the transient drawer/overlays (no notification: the caller is
  /// building with the new values).
  void reportLayoutWidth(double width) {
    final was = (isNarrow, inspectorOverlays, _notesTransient);
    _layoutWidth = width;
    if (was.$1 != isNarrow) _navigatorDrawer = false;
    if (was.$2 != inspectorOverlays) _inspectorOverlay = false;
    if (was.$3 != _notesTransient) _notesOpen = false;
  }

  /// Whether the navigator shows (docked, or the drawer when narrow).
  bool get navigatorVisible =>
      isNarrow ? _navigatorDrawer : _prefs.navigatorVisible;

  /// Whether the inspector shows (docked, or the overlay below 1,200 px).
  bool get inspectorVisible =>
      inspectorOverlays ? _inspectorOverlay : _prefs.inspectorVisible;

  /// Whether the speaker notes body shows.
  bool get notesVisible => _notesTransient ? _notesOpen : _prefs.notesVisible;

  /// The inspector tab (a stored Animate tab reads as Format while
  /// animations are hidden, SL-23; the Theme tab as Slide outside masters
  /// mode, SL-28).
  InspectorTab get inspectorTab {
    final t = InspectorTab.fromName(_prefs.inspectorTab) ?? InspectorTab.format;
    if (t == InspectorTab.animate &&
        !SlidesFeatures.isOn(SlidesFeature.animations)) {
      return InspectorTab.format;
    }
    // The Theme tab exists in masters mode only (05 §8.1).
    if (t == InspectorTab.theme && _mode != DeckViewMode.masters) {
      return InspectorTab.slide;
    }
    return t;
  }

  double get navigatorWidth => _prefs.navigatorWidth;
  double get inspectorWidth => _prefs.inspectorWidth;
  double get notesHeight => _prefs.notesHeight;

  /// The inspector section to reveal (`arrange`, `code`, …), set by
  /// `slides.inspector.open {section}`; consumed by the inspector.
  String? inspectorSection;

  /// The Animate tab's sub-tab (`transition`, `build`, `order`; 06 §5).
  String animateTab = 'transition';

  void _savePrefs() => _prefs.write(services.userStore);

  void setNavigatorVisible(bool v) {
    if (v == navigatorVisible) return;
    if (isNarrow) {
      _navigatorDrawer = v;
    } else {
      _prefs.navigatorVisible = v;
      _savePrefs();
    }
    notifyListeners();
  }

  void setInspectorVisible(bool v) {
    if (v == inspectorVisible) return;
    if (inspectorOverlays) {
      _inspectorOverlay = v;
    } else {
      _prefs.inspectorVisible = v;
      _savePrefs();
    }
    notifyListeners();
  }

  void setNotesVisible(bool v) {
    if (v == notesVisible) return;
    if (_notesTransient) {
      _notesOpen = v;
    } else {
      _prefs.notesVisible = v;
      _savePrefs();
    }
    notifyListeners();
  }

  /// Resizes a pane (drag handles); stored on release with [commit].
  void resizePane(String pane, double size, {bool commit = false}) {
    switch (pane) {
      case 'navigator':
        _prefs.navigatorWidth = size.clamp(160, 400);
      case 'inspector':
        _prefs.inspectorWidth = size.clamp(260, 420);
      case 'notes':
        _prefs.notesHeight = size.clamp(48, 2000);
      default:
        return;
    }
    if (commit) _savePrefs();
    notifyListeners();
  }

  /// Opens the inspector on [tab] (and [section]).
  void openInspector(InspectorTab tab, {String? section, String? animateTab}) {
    _prefs.inspectorTab = tab.name;
    if (inspectorOverlays) {
      _inspectorOverlay = true;
    } else {
      _prefs.inspectorVisible = true;
    }
    inspectorSection = section;
    if (animateTab != null) this.animateTab = animateTab;
    _savePrefs();
    notifyListeners();
  }

  void setInspectorTab(InspectorTab tab) {
    if (tab.name == _prefs.inspectorTab) return;
    _prefs.inspectorTab = tab.name;
    inspectorSection = null;
    _savePrefs();
    notifyListeners();
  }

  // ---------------------------------------------------------- view toggles

  bool get rulers => _prefs.rulers;
  bool get guides => _prefs.guides;
  bool get commentPins => _prefs.commentPins;

  /// Flips a View › Show toggle (`rulers`, `guides`, `commentPins`).
  void toggleView(String name) {
    switch (name) {
      case 'rulers':
        _prefs.rulers = !_prefs.rulers;
      case 'guides':
        _prefs.guides = !_prefs.guides;
      case 'commentPins':
        _prefs.commentPins = !_prefs.commentPins;
      default:
        return;
    }
    _savePrefs();
    notifyListeners();
  }

  // ------------------------------------------------------------------ zoom

  /// Zoom steps of View › Zoom and the toolbar (03 §2.2).
  static const zoomSteps = <int>[25, 50, 75, 100, 125, 150, 200, 300, 400];

  bool _zoomFit = true;
  double _zoom = 1;

  double _fitScale = 1;

  /// The scale *Fit* resolves to (reported by the canvas after layout).
  double get fitScale => _fitScale;

  /// Called by the canvas during layout: listeners (status bar, toolbar)
  /// are told after the frame when the fitted zoom changed.
  void reportFitScale(double scale) {
    if ((scale - _fitScale).abs() < 1e-6) return;
    _fitScale = scale;
    if (_zoomFit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  /// Whether the canvas fits the slide to the viewport.
  bool get zoomFit => _zoomFit;

  /// The effective zoom (1 = 100 %: one slide unit per logical pixel).
  double get zoom => _zoomFit ? fitScale : _zoom;

  /// Sets a fixed zoom (0.1–4).
  void setZoom(double zoom) {
    _zoomFit = false;
    _zoom = zoom.clamp(0.1, 4.0);
    notifyListeners();
  }

  void setZoomFit() {
    if (_zoomFit) return;
    _zoomFit = true;
    notifyListeners();
  }

  /// The next zoom step above (or below) the effective zoom.
  void stepZoom(int direction) {
    final pct = zoom * 100;
    final steps = direction > 0 ? zoomSteps : zoomSteps.reversed;
    for (final s in steps) {
      if (direction > 0 ? s > pct + 0.5 : s < pct - 0.5) {
        setZoom(s / 100);
        return;
      }
    }
    setZoom((direction > 0 ? zoomSteps.last : zoomSteps.first) / 100);
  }

  // --------------------------------------------------------- focus scopes

  /// Focus of the canvas scope (`slidesCanvas`, 03 §1.2).
  final FocusNode canvasFocus = FocusNode(debugLabel: 'slides.canvas');

  /// Focus of the navigator scope (`slidesNavigator`).
  final FocusNode navigatorFocus = FocusNode(debugLabel: 'slides.navigator');

  /// Focus of the speaker notes scope (`slidesNotes`).
  final FocusNode notesFocus = FocusNode(debugLabel: 'slides.notes');

  // ----------------------------------------------------------------- write

  /// Executes [op] on the deck and records it as one `slides.rows` undo
  /// step in [ctx]'s transaction (the write path of every Slides command).
  /// Throws `PlanException` (nothing applied).
  SlidesPlan apply(CommandContext ctx, SlidesOperation op) {
    final plan = session.execute(op);
    if (!plan.isEmpty) {
      ctx.transaction?.record(
        SlidesRowsUndoEntry(
          plan.changes,
          label: plan.label,
          groupId: session.groupOf(plan),
        ),
      );
      for (final l in List.of(applyListeners)) {
        l(ctx, op, plan);
      }
    }
    return plan;
  }

  /// Called after every non-empty [apply], in the command's transaction
  /// (SL-38: comments move with cut & pasted elements, 09 §3.2).
  final List<
    void Function(CommandContext ctx, SlidesOperation op, SlidesPlan plan)
  >
  applyListeners = [];

  /// Invokes command [id] (dispatcher, with the editor's services).
  Future<CommandResult> invokeCommand(
    String id, [
    Map<String, Object?> args = const {},
    InvocationSource source = InvocationSource.ui,
    BuildContext? context,
  ]) => services.dispatcher.invoke(
    id,
    args: args,
    source: source,
    context: context,
  );

  // ----------------------------------------------------------- model sync

  void _onBatch(DeckChangeBatch batch) {
    if (_disposed) return;
    final cur = _currentSlideId;
    final entries = order.entries;
    if (cur == null || order.entry(cur) == null) {
      // The current slide was deleted (here or remotely): its neighbor.
      _currentSlideId = entries.isEmpty
          ? null
          : entries[math.min(_lastIndex, entries.length - 1)].id;
      _selectedSlideIds
        ..clear()
        ..addAll([?_currentSlideId]);
    } else {
      _lastIndex = order.indexOf(cur);
      _selectedSlideIds.removeWhere((id) => order.entry(id) == null);
    }
    _selectedGroupIds.removeWhere((id) => model.group(id) == null);
    _selectedElementIds.removeWhere((id) => model.element(id) == null);
    final target = _masterTargetId;
    if (target != null && _validTarget(target) == null) {
      // The edited layout/master was deleted (here or remotely).
      _masterTargetId = _mode == DeckViewMode.masters ? _defaultTarget() : null;
    }
    notifyListeners();
  }

  int _lastIndex = 0;

  // ----------------------------------------------------- selection (undo)

  /// The selection restored by undo/redo (current slide + elements).
  SelectionSnapshot captureSelection() => SelectionSnapshot('slides.editor', {
    'slideId': _currentSlideId,
    if (_mode == DeckViewMode.masters) 'masterTargetId': _masterTargetId,
    'elementIds': [..._selectedElementIds],
  });

  void restoreSelection(SelectionSnapshot s) {
    if (s.domain != 'slides.editor') return;
    final slide = s.data['slideId'];
    if (slide is String && order.entry(slide) != null) {
      setCurrentSlide(slide);
    }
    final target = s.data['masterTargetId'];
    if (_mode == DeckViewMode.masters && target is String) {
      setMasterTarget(target);
    }
    final ids = s.data['elementIds'];
    // Only elements of the surface the canvas shows (an undo of a layout
    // edit in Normal view doesn't select layout elements, SL-28).
    final surface = surfaceId;
    if (ids is List) {
      selectElements(
        ids.whereType<String>().where(
          (id) => model.element(id)?.ownerId == surface,
        ),
      );
    }
  }

  /// "Slide 4 of 24" or "2 objects on slide 4" (MCP `ui.get_state`).
  String describeSelection() {
    final e = currentEntry;
    if (e == null) return 'No slides';
    final pos = 'slide ${e.index + 1} of ${order.length}';
    final n = _selectedElementIds.length;
    return n == 0 ? pos : '$n object${n == 1 ? '' : 's'} on $pos';
  }

  /// Extra state for MCP `ui.get_state` (04 AC-2, 11).
  Map<String, Object?> describeState() => {
    'deckId': session.deckId,
    'loadState': switch (session.loadState.value) {
      DeckLoading() => 'loading',
      DeckReady() => 'ready',
      DeckUnavailable() => 'unavailable',
    },
    'role': role.name,
    'mode': viewMode ? 'viewing' : 'editing',
    'viewMode': _mode.name,
    if (_mode == DeckViewMode.masters) ...{
      'masterTargetId': surfaceId,
      'masterTargetKind': surfaceKind.name,
    },
    'slideCount': order.length,
    'currentSlideId': _currentSlideId,
    'currentSlideIndex': _currentSlideId == null
        ? null
        : order.indexOf(_currentSlideId!),
    'selectedSlideIds': [..._selectedSlideIds],
    'selectedGroupIds': [..._selectedGroupIds],
    'selectedElementIds': [..._selectedElementIds],
    'selectionKind': selectionKind.name,
    'navigator': navigatorVisible,
    'inspector': inspectorVisible ? inspectorTab.name : null,
    'notes': notesVisible,
    'zoom': zoomFit ? 'fit' : (zoom * 100).round(),
  };

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    session.model.removeListener(_onBatch);
    session.role.removeListener(_onRole);
    session.loadState.removeListener(notifyListeners);
    services.prefs.removeListener(notifyListeners);
    canvasFocus.dispose();
    navigatorFocus.dispose();
    notesFocus.dispose();
    super.dispose();
  }
}
