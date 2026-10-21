import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import 'shell_scope.dart';
import 'shell_services.dart';

/// A dialog the MCP UI bridge can read and operate (suite 09 §6.2).
abstract class McpDescribableDialog {
  /// `{title, fields: [{id, label, type, value, options}], buttons: [...]}`.
  Map<String, Object?> describe();

  /// Sets a field; returns false for unknown ids or invalid values.
  bool setField(String id, Object? value);

  /// Presses a button; returns false for unknown ids.
  bool press(String buttonId);
}

/// (v2) Registers a custom dialog's [State] with the shell's open dialogs
/// (`ShellServices.openDialogs`, read by `ui.get_dialog`) while it is
/// mounted, so a custom dialog only implements [McpDescribableDialog]'s
/// three methods.
mixin McpDialogRegistration<T extends StatefulWidget> on State<T>
    implements McpDescribableDialog {
  ShellServices? _mcpRegisteredIn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = ShellScope.maybeOf(context);
    if (identical(s, _mcpRegisteredIn)) return;
    _mcpRegisteredIn?.openDialogs.remove(this);
    _mcpRegisteredIn = s;
    if (s != null && !s.openDialogs.contains(this)) s.openDialogs.add(this);
  }

  @override
  void dispose() {
    _mcpRegisteredIn?.openDialogs.remove(this);
    _mcpRegisteredIn = null;
    super.dispose();
  }
}

/// (v2) Registers [dialog] with the shell's open dialogs while [child] is
/// mounted: makes a dialog widget that can't implement
/// [McpDescribableDialog] itself (another package's, a stateless one)
/// MCP-operable from where it is shown.
class McpDialogScope extends StatefulWidget {
  const McpDialogScope({super.key, required this.dialog, required this.child});

  final McpDescribableDialog dialog;
  final Widget child;

  @override
  State<McpDialogScope> createState() => _McpDialogScopeState();
}

class _McpDialogScopeState extends State<McpDialogScope> {
  ShellServices? _services;
  McpDescribableDialog? _registered;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _register();
  }

  @override
  void didUpdateWidget(McpDialogScope old) {
    super.didUpdateWidget(old);
    if (!identical(old.dialog, widget.dialog)) _register();
  }

  void _register() {
    final s = ShellScope.maybeOf(context);
    if (identical(s, _services) && identical(_registered, widget.dialog)) {
      return;
    }
    final old = _registered;
    if (old != null) _services?.openDialogs.remove(old);
    _services = s;
    _registered = widget.dialog;
    if (s != null && !s.openDialogs.contains(widget.dialog)) {
      s.openDialogs.add(widget.dialog);
    }
  }

  @override
  void dispose() {
    final d = _registered;
    if (d != null) _services?.openDialogs.remove(d);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A field of a [WonkyDialogSpec].
sealed class DialogFieldSpec {
  const DialogFieldSpec({required this.id, required this.label});

  final String id;
  final String label;
}

class TextFieldSpec extends DialogFieldSpec {
  const TextFieldSpec({
    required super.id,
    required super.label,
    this.initial = '',
    this.placeholder,
    this.validator,
    this.selectAll = true,
    this.maxLength,
    this.multiline = false,
    this.obscure = false,
  });

  final String initial;
  final String? placeholder;

  /// Returns an error message or null.
  final String? Function(String value)? validator;
  final bool selectAll;
  final int? maxLength;
  final bool multiline;
  final bool obscure;
}

class CheckboxFieldSpec extends DialogFieldSpec {
  const CheckboxFieldSpec({
    required super.id,
    required super.label,
    this.initial = false,
  });

  final bool initial;
}

/// An item of a [ChecklistFieldSpec]: its [value], [label] and the
/// [group] it is listed under (a heading over the items that share it).
class ChecklistItem {
  const ChecklistItem({required this.value, required this.label, this.group});

  final String value;
  final String label;
  final String? group;
}

/// A list of checkboxes in a scrolling box (at most [maxHeight] high); the
/// value is the list of checked item values. Keys:
/// `<dialogKey>.<id>.<value>` per item.
class ChecklistFieldSpec extends DialogFieldSpec {
  const ChecklistFieldSpec({
    required super.id,
    required super.label,
    required this.items,
    this.description,
    this.initial,
    this.maxHeight = 240,
  });

  final List<ChecklistItem> items;
  final String? description;

  /// The values checked at first; null checks every item.
  final Set<String>? initial;
  final double maxHeight;
}

class SelectFieldSpec extends DialogFieldSpec {
  const SelectFieldSpec({
    required super.id,
    required super.label,
    required this.options,
    required this.initial,
  });

  /// value → label.
  final Map<String, String> options;
  final String initial;
}

/// What [ImageFieldSpec.pick] returns: the new value (an id) and its
/// thumbnail.
typedef ImageFieldPick = ({String value, ImageProvider? preview});

/// An image the user uploads in the dialog (e.g. a story's cover image,
/// specs/18 §4.2): a thumbnail with *Upload* (*Replace* once set) and
/// *Remove*. The value is an id, `''` for none. [pick] picks and uploads an
/// image and returns its id (null when cancelled; a throw shows
/// [errorLabel]); [preview] resolves the thumbnail of [initial]. Keys:
/// `<dialogKey>.<id>` (the field), `.preview`, `.upload`, `.remove`.
class ImageFieldSpec extends DialogFieldSpec {
  const ImageFieldSpec({
    required super.id,
    required super.label,
    required this.pick,
    required this.uploadLabel,
    required this.replaceLabel,
    required this.removeLabel,
    required this.emptyLabel,
    required this.uploadingLabel,
    required this.errorLabel,
    this.initial = '',
    this.preview,
    this.description,
  });

  final String initial;
  final Future<ImageFieldPick?> Function() pick;
  final FutureOr<ImageProvider?> Function(String value)? preview;
  final String uploadLabel;
  final String replaceLabel;
  final String removeLabel;

  /// Shown in the thumbnail box without an image.
  final String emptyLabel;
  final String uploadingLabel;
  final String errorLabel;
  final String? description;
}

/// A dialog button.
class DialogButtonSpec {
  const DialogButtonSpec({
    required this.id,
    required this.label,
    this.primary = false,
    this.destructive = false,
    this.validates = true,
  });

  final String id;
  final String label;
  final bool primary;
  final bool destructive;

  /// Run field validators first.
  final bool validates;
}

/// A declarative dialog (title, fields, buttons) rendered by
/// [WonkyFormDialog]; automatically MCP-operable.
class WonkyDialogSpec {
  const WonkyDialogSpec({
    required this.title,
    this.description,
    this.fields = const [],
    required this.buttons,
    this.cancelId = 'cancel',
    this.width = 420,
    this.dialogKey,
    this.alert = false,
  });

  final String title;
  final String? description;
  final List<DialogFieldSpec> fields;
  final List<DialogButtonSpec> buttons;

  /// The button id reported for Esc / close.
  final String cancelId;
  final double width;

  /// Stable key prefix for widgets (`dialog.rename`).
  final String? dialogKey;

  /// Rendered as a `ShadDialog.alert` (no close icon; a message the user
  /// acknowledges, e.g. the *Out of storage* dialog).
  final bool alert;
}

/// What the user chose.
class DialogResult {
  const DialogResult(this.buttonId, this.values);

  final String buttonId;
  final Map<String, Object?> values;

  String text(String id) => '${values[id] ?? ''}';
  bool flag(String id) => values[id] == true;

  /// The checked values of a [ChecklistFieldSpec].
  List<String> checked(String id) => [
    for (final v in values[id] as List? ?? const []) '$v',
  ];
}

/// Shows [spec]; resolves with the pressed button and field values (null
/// when dismissed).
Future<DialogResult?> showWonkyFormDialog(
  BuildContext context,
  WonkyDialogSpec spec,
) => showShadDialog<DialogResult>(
  context: context,
  builder: (_) => WonkyFormDialog(spec: spec),
);

/// Renders a [WonkyDialogSpec] with shad widgets.
class WonkyFormDialog extends StatefulWidget {
  const WonkyFormDialog({super.key, required this.spec});

  final WonkyDialogSpec spec;

  @override
  State<WonkyFormDialog> createState() => _WonkyFormDialogState();
}

class _WonkyFormDialogState extends State<WonkyFormDialog>
    implements McpDescribableDialog {
  ShellServices? _registeredIn;
  final Map<String, TextEditingController> _text = {};
  final Map<String, Object?> _values = {};
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    for (final f in widget.spec.fields) {
      switch (f) {
        case TextFieldSpec():
          final c = TextEditingController(text: f.initial);
          if (f.selectAll) {
            c.selection = TextSelection(
              baseOffset: 0,
              extentOffset: f.initial.length,
            );
          }
          _text[f.id] = c;
        case CheckboxFieldSpec():
          _values[f.id] = f.initial;
        case ChecklistFieldSpec():
          _values[f.id] = <String>{
            for (final i in f.items)
              if (f.initial?.contains(i.value) ?? true) i.value,
          };
        case SelectFieldSpec():
          _values[f.id] = f.initial;
        case ImageFieldSpec():
          _values[f.id] = f.initial;
          _resolvePreview(f, f.initial);
      }
    }
  }

  /// Thumbnails of [ImageFieldSpec]s; ids of those uploading.
  final Map<String, ImageProvider?> _previews = {};
  final Set<String> _uploading = {};

  void _resolvePreview(ImageFieldSpec f, String value) {
    _previews[f.id] = null;
    if (value.isEmpty || f.preview == null) return;
    final p = f.preview!(value);
    if (p is Future<ImageProvider?>) {
      unawaited(
        p.then((provider) {
          if (mounted && _values[f.id] == value) {
            setState(() => _previews[f.id] = provider);
          }
        }, onError: (Object _) {}),
      );
    } else {
      _previews[f.id] = p;
    }
  }

  Future<void> _pickImage(ImageFieldSpec f) async {
    setState(() {
      _uploading.add(f.id);
      _errors[f.id] = null;
    });
    try {
      final picked = await f.pick();
      if (!mounted || picked == null) return;
      setState(() {
        _values[f.id] = picked.value;
        _previews[f.id] = picked.preview;
      });
      if (picked.preview == null) _resolvePreview(f, picked.value);
    } catch (e) {
      if (mounted) setState(() => _errors[f.id] = f.errorLabel);
    } finally {
      if (mounted) setState(() => _uploading.remove(f.id));
    }
  }

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
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, Object?> get _all => {
    for (final e in _values.entries)
      // Checklists: the checked values in the items' order.
      e.key: e.value is Set<String> ? _checkedOf(e.key) : e.value,
    for (final e in _text.entries) e.key: e.value.text,
  };

  List<String> _checkedOf(String id) {
    final f = widget.spec.fields.firstWhere((f) => f.id == id);
    final set = _values[id]! as Set<String>;
    return [
      if (f is ChecklistFieldSpec)
        for (final i in f.items)
          if (set.contains(i.value)) i.value,
    ];
  }

  bool _validate() {
    var ok = true;
    for (final f in widget.spec.fields) {
      if (f is TextFieldSpec && f.validator != null) {
        final e = f.validator!(_text[f.id]!.text);
        _errors[f.id] = e;
        if (e != null) ok = false;
      }
    }
    setState(() {});
    return ok;
  }

  void _press(DialogButtonSpec b) {
    // Not before an image field's upload has finished.
    if (b.id != widget.spec.cancelId && _uploading.isNotEmpty) return;
    if (b.id != widget.spec.cancelId && b.validates && !_validate()) return;
    Navigator.of(context).pop(DialogResult(b.id, _all));
  }

  DialogButtonSpec? get _primary {
    for (final b in widget.spec.buttons) {
      if (b.primary) return b;
    }
    return null;
  }

  @override
  Map<String, Object?> describe() => {
    'title': widget.spec.title,
    if (widget.spec.description != null) 'description': widget.spec.description,
    'fields': [
      for (final f in widget.spec.fields)
        {
          'id': f.id,
          'label': f.label,
          'type': switch (f) {
            TextFieldSpec() => 'text',
            CheckboxFieldSpec() => 'checkbox',
            ChecklistFieldSpec() => 'checklist',
            SelectFieldSpec() => 'select',
            ImageFieldSpec() => 'image',
          },
          if (f is ImageFieldSpec && _uploading.contains(f.id))
            'uploading': true,
          'value': _all[f.id],
          if (f is ChecklistFieldSpec) ...{
            'options': [for (final i in f.items) i.value],
            'optionLabels': {
              for (final i in f.items)
                i.value: i.group == null ? i.label : '${i.group}: ${i.label}',
            },
          },
          if (f is SelectFieldSpec) 'options': f.options.keys.toList(),
          // (v2) What each option says (Slides' Go to slide lists slides
          // by id; agents need the labels).
          if (f is SelectFieldSpec) 'optionLabels': f.options,
          if (_errors[f.id] != null) 'error': _errors[f.id],
        },
    ],
    'buttons': [
      for (final b in widget.spec.buttons) {'id': b.id, 'label': b.label},
    ],
  };

  @override
  bool setField(String id, Object? value) {
    final f = widget.spec.fields.where((f) => f.id == id).firstOrNull;
    switch (f) {
      case TextFieldSpec():
        _text[id]!.text = '${value ?? ''}';
      case CheckboxFieldSpec():
        if (value is! bool) return false;
        setState(() => _values[id] = value);
      case ChecklistFieldSpec():
        final known = {for (final i in f.items) i.value};
        if (value is! List || value.any((v) => !known.contains('$v'))) {
          return false;
        }
        setState(() => _values[id] = <String>{for (final v in value) '$v'});
      case SelectFieldSpec():
        if (!f.options.containsKey(value)) return false;
        setState(() => _values[id] = value);
      case ImageFieldSpec():
        // An id of an image that is already uploaded, or '' for none.
        if (value is! String) return false;
        setState(() {
          _values[id] = value;
          _resolvePreview(f, value);
        });
      case null:
        return false;
    }
    return true;
  }

  @override
  bool press(String buttonId) {
    final b = widget.spec.buttons.where((b) => b.id == buttonId).firstOrNull;
    if (b == null) return false;
    _press(b);
    return true;
  }

  Widget _checklist(ChecklistFieldSpec f, ShadThemeData theme, String? key) {
    final cs = theme.colorScheme;
    final checked = _values[f.id]! as Set<String>;
    final rows = <Widget>[];
    String? group;
    for (final i in f.items) {
      if (i.group != null && i.group != group) {
        group = i.group;
        rows.add(
          Padding(
            padding: EdgeInsets.only(top: rows.isEmpty ? 0 : 8, bottom: 2),
            child: Text(
              group!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.small.copyWith(color: cs.mutedForeground),
            ),
          ),
        );
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: ShadCheckbox(
            key: key == null
                ? null
                : ValueKey<String>('$key.${f.id}.${i.value}'),
            value: checked.contains(i.value),
            onChanged: (v) => setState(() {
              v ? checked.add(i.value) : checked.remove(i.value);
            }),
            label: Text(i.label, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(f.label, style: theme.textTheme.small),
        if (f.description != null) ...[
          const SizedBox(height: 2),
          Text(f.description!, style: theme.textTheme.muted),
        ],
        const SizedBox(height: 6),
        DecoratedBox(
          key: key == null ? null : ValueKey<String>('$key.${f.id}'),
          decoration: BoxDecoration(
            border: Border.all(color: cs.border),
            borderRadius: theme.radius,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: f.maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: rows,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _image(ImageFieldSpec f, ShadThemeData theme, String? key) {
    final cs = theme.colorScheme;
    final value = _values[f.id]! as String;
    final preview = _previews[f.id];
    final uploading = _uploading.contains(f.id);
    ValueKey<String>? k(String part) =>
        key == null ? null : ValueKey<String>('$key.${f.id}$part');
    final Widget thumbnail;
    if (uploading) {
      thumbnail = Text(f.uploadingLabel, style: theme.textTheme.muted);
    } else if (value.isEmpty) {
      thumbnail = Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(LucideIcons.image, size: 20, color: cs.mutedForeground),
          Text(
            f.emptyLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.muted,
          ),
        ],
      );
    } else if (preview == null) {
      thumbnail = Icon(LucideIcons.image, size: 20, color: cs.mutedForeground);
    } else {
      thumbnail = Image(
        key: k('.preview'),
        image: preview,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) =>
            Icon(LucideIcons.imageOff, size: 20, color: cs.mutedForeground),
      );
    }
    return Column(
      key: k(''),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(f.label, style: theme.textTheme.small),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 12,
          children: [
            // 16:9, the usual shape of a blog's cover.
            Container(
              width: 128,
              height: 72,
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: cs.muted,
                border: Border.all(color: cs.border),
                borderRadius: theme.radius,
              ),
              child: thumbnail,
            ),
            Flexible(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ShadButton.outline(
                    key: k('.upload'),
                    size: ShadButtonSize.sm,
                    enabled: !uploading,
                    leading: const Icon(LucideIcons.upload, size: 16),
                    onPressed: () => unawaited(_pickImage(f)),
                    child: Text(value.isEmpty ? f.uploadLabel : f.replaceLabel),
                  ),
                  if (value.isNotEmpty && !uploading)
                    ShadButton.ghost(
                      key: k('.remove'),
                      size: ShadButtonSize.sm,
                      leading: const Icon(LucideIcons.x, size: 16),
                      onPressed: () => setState(() {
                        _values[f.id] = '';
                        _previews[f.id] = null;
                      }),
                      child: Text(f.removeLabel),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (f.description != null) ...[
          const SizedBox(height: 6),
          Text(f.description!, style: theme.textTheme.muted),
        ],
        if (_errors[f.id] != null) ...[
          const SizedBox(height: 4),
          Text(
            _errors[f.id]!,
            style: theme.textTheme.small.copyWith(color: cs.destructive),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final theme = ShadTheme.of(context);
    final key = spec.dialogKey;
    var first = true;
    final fields = <Widget>[];
    for (final f in spec.fields) {
      final autofocus = first;
      first = false;
      switch (f) {
        case TextFieldSpec():
          fields.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (f.label.isNotEmpty) ...[
                  Text(f.label, style: theme.textTheme.small),
                  const SizedBox(height: 6),
                ],
                ShadInput(
                  key: key == null ? null : ValueKey<String>('$key.${f.id}'),
                  controller: _text[f.id],
                  autofocus: autofocus,
                  placeholder: f.placeholder == null
                      ? null
                      : Text(f.placeholder!),
                  maxLength: f.maxLength,
                  obscureText: f.obscure,
                  maxLines: f.multiline ? 5 : 1,
                  minLines: f.multiline ? 3 : 1,
                  onSubmitted: f.multiline
                      ? null
                      : (_) {
                          final p = _primary;
                          if (p != null) _press(p);
                        },
                  onChanged: (_) {
                    if (_errors[f.id] != null) {
                      setState(() => _errors[f.id] = null);
                    }
                  },
                ),
                if (_errors[f.id] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _errors[f.id]!,
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.destructive,
                    ),
                  ),
                ],
              ],
            ),
          );
        case CheckboxFieldSpec():
          fields.add(
            ShadCheckbox(
              key: key == null ? null : ValueKey<String>('$key.${f.id}'),
              value: _values[f.id] == true,
              onChanged: (v) => setState(() => _values[f.id] = v),
              label: Text(f.label),
            ),
          );
        case ChecklistFieldSpec():
          fields.add(_checklist(f, theme, key));
        case SelectFieldSpec():
          fields.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(f.label, style: theme.textTheme.small),
                const SizedBox(height: 6),
                ShadSelect<String>(
                  key: key == null ? null : ValueKey<String>('$key.${f.id}'),
                  initialValue: _values[f.id] as String?,
                  options: [
                    for (final o in f.options.entries)
                      ShadOption(value: o.key, child: Text(o.value)),
                  ],
                  selectedOptionBuilder: (context, v) =>
                      Text(f.options[v] ?? v),
                  onChanged: (v) => setState(() => _values[f.id] = v),
                ),
              ],
            ),
          );
        case ImageFieldSpec():
          fields.add(_image(f, theme, key));
      }
    }
    // Below shad's `sm` breakpoint the actions stack vertically and each
    // button is as wide as the dialog: long labels ellipsize instead of
    // overflowing (360 px windows, long translations).
    final narrow = MediaQuery.sizeOf(context).width < 640;
    Widget label(DialogButtonSpec b) => narrow
        ? Flexible(
            child: Text(b.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          )
        : Text(b.label);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: (spec.alert ? ShadDialog.alert : ShadDialog.new)(
        key: key == null ? null : ValueKey<String>(key),
        title: Text(spec.title),
        description: spec.description == null ? null : Text(spec.description!),
        actions: [
          for (final b in spec.buttons)
            b.primary
                ? (b.destructive
                      ? ShadButton.destructive(
                          key: key == null
                              ? null
                              : ValueKey<String>('$key.${b.id}'),
                          onPressed: () => _press(b),
                          child: label(b),
                        )
                      : ShadButton(
                          key: key == null
                              ? null
                              : ValueKey<String>('$key.${b.id}'),
                          onPressed: () => _press(b),
                          child: label(b),
                        ))
                : ShadButton.outline(
                    key: key == null ? null : ValueKey<String>('$key.${b.id}'),
                    onPressed: () => _press(b),
                    child: label(b),
                  ),
        ],
        child: SizedBox(
          width: spec.width,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: fields,
            ),
          ),
        ),
      ),
    );
  }
}
