import 'dart:async';

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets_script/wonky_sheets_script.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../../l10n/sheets_l10n.dart';
import '../../sheet_editor/sheet_editor_controller.dart';

/// Side panel id of script sidebars (09 §16.3 `scriptSidebar`).
const scriptSidebarPanelId = 'sheets.panel.scriptSidebar';

/// A shown script panel and the values typed into it.
class ScriptPanelState extends ChangeNotifier {
  ScriptPanelState(this.request) : panel = request.panel {
    _seed(panel);
  }

  final ScriptPanelRequest request;
  Map<String, Object?> panel;

  /// Input values by component id.
  final Map<String, Object?> values = {};

  String get id => request.id;
  String get title => '${panel['title'] ?? ''}';

  void _seed(Map<String, Object?> p) {
    void walk(Object? c) {
      if (c is! Map) return;
      final id = c['id'];
      if (id is String && id.isNotEmpty && !values.containsKey(id)) {
        values[id] = switch (c['type']) {
          'checkbox' => c['value'] == true,
          _ => c['value'] == null ? '' : '${c['value']}',
        };
      }
      for (final x in (c['children'] as List?) ?? const []) {
        walk(x);
      }
    }

    for (final c in (p['children'] as List?) ?? const []) {
      walk(c);
    }
  }

  /// Replaces the content (`UiPanelHandle.update`); typed values stay.
  void update(Map<String, Object?> next) {
    panel = next;
    _seed(next);
    notifyListeners();
  }

  void setValue(String id, Object? value) {
    values[id] = value;
    notifyListeners();
  }
}

/// The script panels of one open spreadsheet (09 §16.3): at most one
/// sidebar (the `scriptSidebar` side panel) and one dialog. Button clicks
/// run the named function with a `UiEvent` through [onButton].
class ScriptPanels extends ChangeNotifier {
  ScriptPanels._(this.editor);

  static final Expando<ScriptPanels> _of = Expando('ScriptPanels');

  /// The panels of [editor].
  static ScriptPanels of(SheetEditorController editor) =>
      _of[editor] ??= ScriptPanels._(editor);

  final SheetEditorController editor;

  /// Runs a button's function (`ScriptService.runPanelButton`).
  Future<void> Function(String function, UiEventData event)? onButton;

  ScriptPanelState? sidebar;
  ScriptPanelState? dialog;
  BuildContext? _dialogContext;

  ShellServices get _s => editor.services;

  /// Context for dialogs instead of the shell navigator (widget tests).
  @visibleForTesting
  static BuildContext? contextOverride;

  void show(ScriptPanelRequest r) {
    if (r.mode == ScriptPanelMode.sidebar) {
      if (sidebar?.id == r.id) {
        sidebar!.update(r.panel);
      } else {
        sidebar = ScriptPanelState(r);
      }
      notifyListeners();
      _s.panels.open(scriptSidebarPanelId);
      return;
    }
    final context = contextOverride ?? _s.navigatorContext;
    if (context == null || !context.mounted) return;
    if (dialog != null) _closeDialog();
    final state = dialog = ScriptPanelState(r);
    unawaited(
      showShadDialog<void>(
        context: context,
        builder: (c) {
          _dialogContext = c;
          return _ScriptPanelDialog(panels: this, state: state);
        },
      ).whenComplete(() {
        if (identical(dialog, state)) {
          dialog = null;
          _dialogContext = null;
        }
      }),
    );
  }

  void update(String panelId, Map<String, Object?> panel) {
    if (sidebar?.id == panelId) sidebar!.update(panel);
    if (dialog?.id == panelId) dialog!.update(panel);
  }

  void close(String panelId) {
    if (sidebar?.id == panelId) {
      sidebar = null;
      notifyListeners();
      if (_s.panels.isOpen(scriptSidebarPanelId)) {
        _s.panels.close(scriptSidebarPanelId);
      }
    }
    if (dialog?.id == panelId) _closeDialog();
  }

  void _closeDialog() {
    final c = _dialogContext;
    dialog = null;
    _dialogContext = null;
    if (c != null && c.mounted) Navigator.of(c).pop();
  }

  /// A button of [state] was pressed.
  Future<void> press(ScriptPanelState state, Map<Object?, Object?> button) {
    final fn = '${button['onClick'] ?? ''}';
    if (fn == '_close') {
      close(state.id);
      return Future.value();
    }
    final run = onButton;
    if (run == null) return Future.value();
    return run(
      fn,
      UiEventData(
        panelId: state.id,
        values: Map.of(state.values),
        button: '${button['caption'] ?? ''}',
      ),
    );
  }

  /// MCP description of a panel: inputs as fields, buttons by caption.
  static Map<String, Object?> describe(ScriptPanelState s) {
    final fields = <Map<String, Object?>>[];
    final buttons = <Map<String, Object?>>[];
    void walk(Object? c) {
      if (c is! Map) return;
      final type = c['type'];
      if (type == 'button') {
        buttons.add({'id': '${c['caption']}', 'label': '${c['caption']}'});
      } else if (c['id'] is String) {
        fields.add({
          'id': c['id'],
          'label': c['label'] ?? '',
          'type': switch (type) {
            'checkbox' => 'checkbox',
            'select' || 'radio' => 'select',
            _ => 'text',
          },
          'value': s.values[c['id']],
          if (c['options'] is List) 'options': c['options'],
        });
      }
      for (final x in (c['children'] as List?) ?? const []) {
        walk(x);
      }
    }

    for (final c in (s.panel['children'] as List?) ?? const []) {
      walk(c);
    }
    return {'title': s.title, 'fields': fields, 'buttons': buttons};
  }

  /// The button with [caption] in [s], or null.
  static Map<Object?, Object?>? buttonOf(ScriptPanelState s, String caption) {
    Map<Object?, Object?>? found;
    void walk(Object? c) {
      if (c is! Map || found != null) return;
      if (c['type'] == 'button' && c['caption'] == caption) found = c;
      for (final x in (c['children'] as List?) ?? const []) {
        walk(x);
      }
    }

    for (final c in (s.panel['children'] as List?) ?? const []) {
      walk(c);
    }
    return found;
  }
}

/// The `scriptSidebar` side panel.
SidePanelSpec scriptSidebarPanelSpec(
  BuildContext context,
  SheetEditorController editor,
) => SidePanelSpec(
  id: scriptSidebarPanelId,
  title:
      ScriptPanels.of(editor).sidebar?.title ??
      sheetsL10n(context).scriptSidebarTitle,
  icon: LucideIcons.panelRight,
  showAsTab: false,
  builder: (_) => ListenableBuilder(
    listenable: ScriptPanels.of(editor),
    builder: (context, _) {
      final panels = ScriptPanels.of(editor);
      final state = panels.sidebar;
      if (state == null) {
        return Center(
          child: Text(
            sheetsL10n(context).scriptSidebarEmpty,
            style: ShadTheme.of(context).textTheme.muted,
          ),
        );
      }
      return _McpPanel(
        panels: panels,
        state: state,
        child: SingleChildScrollView(
          key: const ValueKey<String>('script.sidebar'),
          padding: const EdgeInsets.all(12),
          child: ScriptPanelView(panels: panels, state: state),
        ),
      );
    },
  ),
);

/// Registers a shown sidebar with the MCP UI bridge while it is visible.
class _McpPanel extends StatefulWidget {
  const _McpPanel({
    required this.panels,
    required this.state,
    required this.child,
  });

  final ScriptPanels panels;
  final ScriptPanelState state;
  final Widget child;

  @override
  State<_McpPanel> createState() => _McpPanelState();
}

class _McpPanelState extends State<_McpPanel> implements McpDescribableDialog {
  ShellServices? _registeredIn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = ShellScope.maybeOf(context);
    _registeredIn = s;
    if (s != null && !s.openDialogs.contains(this)) s.openDialogs.add(this);
  }

  @override
  void dispose() {
    _registeredIn?.openDialogs.remove(this);
    super.dispose();
  }

  @override
  Map<String, Object?> describe() => ScriptPanels.describe(widget.state);

  @override
  bool setField(String id, Object? value) {
    if (!widget.state.values.containsKey(id)) return false;
    widget.state.setValue(id, value is bool ? value : '${value ?? ''}');
    return true;
  }

  @override
  bool press(String buttonId) {
    final b = ScriptPanels.buttonOf(widget.state, buttonId);
    if (b == null) return false;
    unawaited(widget.panels.press(widget.state, b));
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ScriptPanelDialog extends StatefulWidget {
  const _ScriptPanelDialog({required this.panels, required this.state});

  final ScriptPanels panels;
  final ScriptPanelState state;

  @override
  State<_ScriptPanelDialog> createState() => _ScriptPanelDialogState();
}

class _ScriptPanelDialogState extends State<_ScriptPanelDialog>
    implements McpDescribableDialog {
  ShellServices? _registeredIn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = ShellScope.maybeOf(context);
    _registeredIn = s;
    if (s != null && !s.openDialogs.contains(this)) s.openDialogs.add(this);
  }

  @override
  void dispose() {
    _registeredIn?.openDialogs.remove(this);
    super.dispose();
  }

  @override
  Map<String, Object?> describe() => {
    ...ScriptPanels.describe(widget.state),
    'title': widget.state.request.dialogTitle ?? widget.state.title,
  };

  @override
  bool setField(String id, Object? value) {
    if (!widget.state.values.containsKey(id)) return false;
    widget.state.setValue(id, value is bool ? value : '${value ?? ''}');
    return true;
  }

  @override
  bool press(String buttonId) {
    if (buttonId == 'close' || buttonId == 'cancel') {
      Navigator.of(context).pop();
      return true;
    }
    final b = ScriptPanels.buttonOf(widget.state, buttonId);
    if (b == null) return false;
    unawaited(widget.panels.press(widget.state, b));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = (size.width - 96).clamp(240.0, 560.0);
    final title = widget.state.request.dialogTitle ?? widget.state.title;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => press('close'),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.scriptPanel'),
        closeIcon: const WonkyDialogCloseButton(),
        constraints: BoxConstraints(maxWidth: width + 48),
        title: Text(title),
        child: SizedBox(
          width: width,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: size.height * 0.7),
            child: SingleChildScrollView(
              child: ScriptPanelView(
                panels: widget.panels,
                state: widget.state,
                showTitle: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders a UI DSL panel with shad widgets (09 §16.3).
class ScriptPanelView extends StatelessWidget {
  const ScriptPanelView({
    super.key,
    required this.panels,
    required this.state,
    this.showTitle = false,
  });

  final ScriptPanels panels;
  final ScriptPanelState state;
  final bool showTitle;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in (state.panel['children'] as List?) ?? const [])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _component(context, c),
            ),
        ],
      ),
    ),
  );

  Widget _component(BuildContext context, Object? raw) {
    if (raw is! Map) return const SizedBox.shrink();
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final id = '${raw['id'] ?? ''}';
    final label = '${raw['label'] ?? ''}';
    Widget labelled(Widget child) => label.isEmpty
        ? child
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: theme.textTheme.small),
              const SizedBox(height: 4),
              child,
            ],
          );
    final options = [
      for (final o in (raw['options'] as List?) ?? const []) '$o',
    ];
    switch (raw['type']) {
      case 'text':
        return Text.rich(
          markdownSpans('${raw['text'] ?? ''}', theme.textTheme.p),
          key: ValueKey<String>('script.panel.text.${raw['text']}'),
        );
      case 'textField':
      case 'textarea':
        final multi = raw['type'] == 'textarea';
        return labelled(
          _PanelInput(
            key: ValueKey<String>('script.panel.input.$id'),
            value: '${state.values[id] ?? ''}',
            placeholder: '${raw['placeholder'] ?? ''}',
            rows: multi ? ((raw['rows'] as num?)?.toInt() ?? 4) : 1,
            keyboard: switch (raw['inputType']) {
              'number' => TextInputType.number,
              'email' => TextInputType.emailAddress,
              'date' => TextInputType.datetime,
              _ => TextInputType.text,
            },
            onChanged: (v) => state.values[id] = v,
          ),
        );
      case 'select':
        final value = '${state.values[id] ?? ''}';
        return labelled(
          ShadSelect<String>(
            key: ValueKey<String>('script.panel.select.$id'),
            initialValue: options.contains(value) ? value : null,
            // Shown while nothing is selected (a select without a value
            // needs one).
            placeholder: const SizedBox.shrink(),
            options: [
              for (final o in options) ShadOption(value: o, child: Text(o)),
            ],
            selectedOptionBuilder: (context, v) => Text(v),
            onChanged: (v) => state.setValue(id, v ?? ''),
          ),
        );
      case 'radio':
        final value = '${state.values[id] ?? ''}';
        return labelled(
          ShadRadioGroup<String>(
            key: ValueKey<String>('script.panel.radio.$id'),
            initialValue: options.contains(value) ? value : null,
            items: [
              for (final o in options)
                ShadRadio<String>(value: o, label: Text(o)),
            ],
            onChanged: (v) => state.setValue(id, v ?? ''),
          ),
        );
      case 'checkbox':
        return ShadCheckbox(
          key: ValueKey<String>('script.panel.checkbox.$id'),
          value: state.values[id] == true,
          label: Text(label),
          onChanged: (v) => state.setValue(id, v),
        );
      case 'button':
        final caption = '${raw['caption'] ?? ''}';
        final key = ValueKey<String>('script.panel.button.$caption');
        void onPressed() => unawaited(panels.press(state, raw));
        final text = Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
        if (raw['destructive'] == true) {
          return ShadButton.destructive(
            key: key,
            onPressed: onPressed,
            child: Flexible(child: text),
          );
        }
        if (raw['primary'] == true) {
          return ShadButton(
            key: key,
            onPressed: onPressed,
            child: Flexible(child: text),
          );
        }
        return ShadButton.outline(
          key: key,
          onPressed: onPressed,
          child: Flexible(child: text),
        );
      case 'row':
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final c in (raw['children'] as List?) ?? const [])
              _component(context, c),
          ],
        );
      case 'column':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in (raw['children'] as List?) ?? const [])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _component(context, c),
              ),
          ],
        );
      case 'divider':
        return Container(height: 1, color: cs.border);
      case 'table':
        final headers = [
          for (final h in (raw['headers'] as List?) ?? const []) '$h',
        ];
        final rows = [
          for (final r in (raw['rows'] as List?) ?? const [])
            [for (final x in (r as List)) '$x'],
        ];
        final cols = [
          headers.length,
          for (final r in rows) r.length,
        ].fold<int>(0, (a, b) => b > a ? b : a);
        Widget cell(String t, {bool head = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            t,
            style: head
                ? theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)
                : theme.textTheme.small,
          ),
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(color: cs.border),
            children: [
              if (headers.isNotEmpty)
                TableRow(
                  decoration: BoxDecoration(color: cs.muted),
                  children: [
                    for (var i = 0; i < cols; i++)
                      cell(i < headers.length ? headers[i] : '', head: true),
                  ],
                ),
              for (final r in rows)
                TableRow(
                  children: [
                    for (var i = 0; i < cols; i++)
                      cell(i < r.length ? r[i] : ''),
                  ],
                ),
            ],
          ),
        );
      case 'progress':
        final v = (raw['value'] as num?)?.toDouble();
        return labelled(ShadProgress(value: v?.clamp(0.0, 1.0)));
    }
    return const SizedBox.shrink();
  }
}

/// A Markdown subset (`**bold**`, `*italic*`, `` `code` ``) as spans.
TextSpan markdownSpans(String text, TextStyle base) {
  final spans = <InlineSpan>[];
  final re = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)');
  var pos = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > pos) spans.add(TextSpan(text: text.substring(pos, m.start)));
    final t = m.group(0)!;
    if (t.startsWith('**')) {
      spans.add(
        TextSpan(
          text: t.substring(2, t.length - 2),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    } else if (t.startsWith('`')) {
      spans.add(
        TextSpan(
          text: t.substring(1, t.length - 1),
          style: const TextStyle(fontFamily: WonkyTheme.monoFamily),
        ),
      );
    } else {
      spans.add(
        TextSpan(
          text: t.substring(1, t.length - 1),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }
    pos = m.end;
  }
  if (pos < text.length) spans.add(TextSpan(text: text.substring(pos)));
  return TextSpan(style: base, children: spans);
}

class _PanelInput extends StatefulWidget {
  const _PanelInput({
    super.key,
    required this.value,
    required this.placeholder,
    required this.rows,
    required this.keyboard,
    required this.onChanged,
  });

  final String value;
  final String placeholder;
  final int rows;
  final TextInputType keyboard;
  final ValueChanged<String> onChanged;

  @override
  State<_PanelInput> createState() => _PanelInputState();
}

class _PanelInputState extends State<_PanelInput> {
  late final _c = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(_PanelInput old) {
    super.didUpdateWidget(old);
    if (widget.value != _c.text && widget.value != old.value) {
      _c.text = widget.value;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ShadInput(
    controller: _c,
    placeholder: widget.placeholder.isEmpty ? null : Text(widget.placeholder),
    minLines: widget.rows,
    maxLines: widget.rows,
    keyboardType: widget.rows > 1 ? TextInputType.multiline : widget.keyboard,
    onChanged: widget.onChanged,
  );
}
