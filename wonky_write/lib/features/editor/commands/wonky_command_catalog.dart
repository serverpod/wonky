part of 'editor_command_catalog.dart';

const _variants = ['info', 'tip', 'note', 'warning', 'caution', 'danger'];
const _boxTypes = ['callout', 'details', 'card'];
const _bullets = ['check', 'circle', 'none'];
const _linkStyles = ['plain', 'arrow', 'button', 'buttonSecondary'];

const _containerArgs = <String, JsonSchema>{
  'nodeId': JsonSchema.string(),
  'depth': JsonSchema.integer(minimum: 0, maximum: 2),
};

/// The Wonky Markdown commands (Write 11 §7.5); all only in Wonky documents.
List<EditorCommandSpec> wonkyEditorCommandCatalog() => [
  EditorCommandSpec(
    id: 'write.insert.callout',
    title: 'Callout',
    category: 'Insert',
    wonkyOnly: true,
    requiredRole: Role.commenter,
    argsSchema: JsonSchema.object(
      properties: {'variant': JsonSchema.string(enumValues: _variants)},
    ),
    enabled: (t, _) => t.commands.canInsertContainer(),
    run: (t, a) => _result(
      t.commands.insertContainer(
        BoxType.callout,
        variant:
            CalloutVariant.tryParse(a.string('variant')) ?? CalloutVariant.info,
      ),
    ),
  ),
  EditorCommandSpec(
    id: 'write.insert.details',
    title: 'Details',
    category: 'Insert',
    wonkyOnly: true,
    requiredRole: Role.commenter,
    enabled: (t, _) => t.commands.canInsertContainer(),
    run: (t, _) => _result(t.commands.insertContainer(BoxType.details)),
  ),
  EditorCommandSpec(
    id: 'write.insert.card',
    title: 'Card',
    category: 'Insert',
    wonkyOnly: true,
    requiredRole: Role.commenter,
    enabled: (t, _) => t.commands.canInsertContainer(),
    run: (t, _) => _result(t.commands.insertContainer(BoxType.card)),
  ),
  EditorCommandSpec(
    id: 'write.insert.youtube',
    title: 'YouTube video',
    category: 'Insert',
    wonkyOnly: true,
    suggestable: false,
    argsSchema: JsonSchema.object(
      properties: {
        'url': JsonSchema.string(
          description:
              'A YouTube link (watch, youtu.be, embed, shorts) or '
              'video id; a t= or start= time is kept',
        ),
        'title': JsonSchema.string(),
      },
    ),
    enabled: (t, _) => t.commands.canInsertBlock() && !t.commands.isSuggesting,
    run: (t, a) {
      // Without `url` the screen asks for it (Write 11 §7.5).
      final id = t.commands.insertYouTube(
        a.string('url') ?? '',
        title: a.string('title'),
      );
      return id == null
          ? const CommandResult.failed('Not a YouTube video link')
          : CommandResult.ok({'id': id});
    },
  ),
  EditorCommandSpec(
    id: 'write.youtube.edit',
    title: 'Edit video',
    category: 'Format',
    wonkyOnly: true,
    suggestable: false,
    argsSchema: JsonSchema.object(
      properties: {
        'nodeId': JsonSchema.string(),
        'url': JsonSchema.string(),
        'title': JsonSchema.string(description: 'Empty removes the title'),
      },
    ),
    enabled: (t, a) =>
        t.commands.canEdit &&
        !t.commands.isSuggesting &&
        t.commands.youtubeOf(nodeId: a.string('nodeId')) != null,
    run: (t, a) => _result(
      t.commands.setYouTube(
        nodeId: a.string('nodeId'),
        url: a.string('url'),
        title: a.string('title'),
      ),
    ),
  ),
  EditorCommandSpec(
    id: 'write.youtube.delete',
    title: 'Delete video',
    category: 'Format',
    wonkyOnly: true,
    suggestable: false,
    argsSchema: const JsonSchema.object(
      properties: {'nodeId': JsonSchema.string()},
    ),
    enabled: (t, a) =>
        t.commands.canEdit &&
        !t.commands.isSuggesting &&
        t.commands.youtubeOf(nodeId: a.string('nodeId')) != null,
    run: (t, a) {
      final video = t.commands.youtubeOf(nodeId: a.string('nodeId'));
      return _result(video != null && t.commands.deleteBlock(nodeId: video.id));
    },
  ),
  EditorCommandSpec(
    id: 'write.insert.grid',
    title: 'Grid',
    category: 'Insert',
    wonkyOnly: true,
    suggestable: false,
    argsSchema: JsonSchema.object(
      properties: {
        'columns': JsonSchema.integer(minimum: 1, maximum: 4),
        'bullets': JsonSchema.string(enumValues: _bullets),
      },
    ),
    enabled: (t, _) => t.commands.canInsertBlock() && !t.commands.isSuggesting,
    run: (t, a) {
      final id = t.commands.insertGrid(
        columns: a.integer('columns') ?? 3,
        bullets: a.string('bullets') == null
            ? GridBullets.check
            : GridBullets.parse(a.string('bullets')),
      );
      return id == null
          ? const CommandResult.failed('Not available here')
          : CommandResult.ok({'id': id});
    },
  ),
  EditorCommandSpec(
    id: 'write.box.setVariant',
    title: 'Callout type',
    category: 'Format',
    wonkyOnly: true,
    radio: true,
    requiredRole: Role.commenter,
    argsSchema: JsonSchema.object(
      properties: {
        'variant': JsonSchema.string(enumValues: _variants),
        ..._containerArgs,
      },
      required: const ['variant'],
    ),
    enabled: (t, a) =>
        t.commands.canEdit &&
        t.commands
                .containerAt(
                  nodeId: a.string('nodeId'),
                  depth: a.integer('depth'),
                )
                ?.frame
                .type ==
            BoxType.callout,
    checked: (t, a) {
      final c = t.commands.containerAt(
        nodeId: a.string('nodeId'),
        depth: a.integer('depth'),
      );
      if (c == null || c.frame.type != BoxType.callout) return null;
      return c.frame.variant?.value == a.string('variant');
    },
    run: (t, a) => _result(
      t.commands.setBoxVariant(
        CalloutVariant.tryParse(a.requireString('variant')) ??
            CalloutVariant.info,
        nodeId: a.string('nodeId'),
        depth: a.integer('depth'),
      ),
    ),
  ),
  EditorCommandSpec(
    id: 'write.box.editTitle',
    title: 'Callout title',
    category: 'Format',
    wonkyOnly: true,
    requiredRole: Role.commenter,
    argsSchema: JsonSchema.object(
      properties: {'title': JsonSchema.string(), ..._containerArgs},
    ),
    enabled: (t, a) =>
        t.commands.canEdit &&
        t.commands
                .containerAt(
                  nodeId: a.string('nodeId'),
                  depth: a.integer('depth'),
                )
                ?.frame
                .type ==
            BoxType.callout,
    run: (t, a) => _result(
      t.commands.setBoxTitle(
        a.string('title'),
        nodeId: a.string('nodeId'),
        depth: a.integer('depth'),
      ),
    ),
  ),
  EditorCommandSpec(
    id: 'write.box.convert',
    title: 'Change container type',
    category: 'Format',
    wonkyOnly: true,
    radio: true,
    requiredRole: Role.commenter,
    argsSchema: JsonSchema.object(
      properties: {
        'type': JsonSchema.string(enumValues: _boxTypes),
        ..._containerArgs,
      },
      required: const ['type'],
    ),
    enabled: (t, a) =>
        t.commands.canEdit &&
        t.commands.containerAt(
              nodeId: a.string('nodeId'),
              depth: a.integer('depth'),
            ) !=
            null,
    checked: (t, a) => t.commands
        .containerAt(nodeId: a.string('nodeId'), depth: a.integer('depth'))
        ?.frame
        .type
        .value
        .let((type) => type == a.string('type')),
    run: (t, a) => _result(
      t.commands.convertBox(
        BoxType.tryParse(a.requireString('type')) ?? BoxType.card,
        nodeId: a.string('nodeId'),
        depth: a.integer('depth'),
      ),
    ),
  ),
  EditorCommandSpec(
    id: 'write.box.unwrap',
    title: 'Remove container',
    category: 'Format',
    wonkyOnly: true,
    requiredRole: Role.commenter,
    argsSchema: JsonSchema.object(properties: _containerArgs),
    enabled: (t, a) =>
        t.commands.canEdit &&
        t.commands.containerAt(
              nodeId: a.string('nodeId'),
              depth: a.integer('depth'),
            ) !=
            null,
    run: (t, a) => _result(
      t.commands.unwrapBox(
        nodeId: a.string('nodeId'),
        depth: a.integer('depth'),
      ),
    ),
  ),
  EditorCommandSpec(
    id: 'write.details.toggleCollapsed',
    title: 'Collapse or expand details',
    category: 'View',
    wonkyOnly: true,
    requiredRole: Role.viewer,
    isUndoable: false,
    suggestable: false,
    argsSchema: JsonSchema.object(properties: {'nodeId': JsonSchema.string()}),
    enabled: (t, a) => t.commands.detailsAt(nodeId: a.string('nodeId')) != null,
    run: (t, a) =>
        _result(t.commands.toggleDetailsCollapsed(nodeId: a.string('nodeId'))),
  ),
  EditorCommandSpec(
    id: 'write.box.delete',
    title: 'Delete container',
    category: 'Format',
    wonkyOnly: true,
    requiredRole: Role.commenter,
    argsSchema: JsonSchema.object(properties: _containerArgs),
    enabled: (t, a) =>
        t.commands.canEdit &&
        t.commands.containerAt(
              nodeId: a.string('nodeId'),
              depth: a.integer('depth'),
            ) !=
            null,
    run: (t, a) => _result(
      t.commands.deleteBox(
        nodeId: a.string('nodeId'),
        depth: a.integer('depth'),
      ),
    ),
  ),
  EditorCommandSpec(
    id: 'write.grid.setColumns',
    title: 'Grid columns',
    category: 'Format',
    wonkyOnly: true,
    radio: true,
    suggestable: false,
    argsSchema: JsonSchema.object(
      properties: {
        'columns': JsonSchema.integer(minimum: 1, maximum: 4),
        'nodeId': JsonSchema.string(),
      },
      required: const ['columns'],
    ),
    enabled: (t, a) =>
        t.commands.canEdit &&
        !t.commands.isSuggesting &&
        t.commands.gridOf(nodeId: a.string('nodeId')) != null,
    checked: (t, a) {
      final grid = t.commands.gridOf(nodeId: a.string('nodeId'));
      return grid == null ? null : grid.columns == a.integer('columns');
    },
    run: (t, a) => _result(
      t.commands.setGridColumns(
        a.integer('columns') ?? 3,
        nodeId: a.string('nodeId'),
      ),
    ),
  ),
  EditorCommandSpec(
    id: 'write.grid.setBullets',
    title: 'Grid bullets',
    category: 'Format',
    wonkyOnly: true,
    radio: true,
    suggestable: false,
    argsSchema: JsonSchema.object(
      properties: {
        'bullets': JsonSchema.string(enumValues: _bullets),
        'nodeId': JsonSchema.string(),
      },
      required: const ['bullets'],
    ),
    enabled: (t, a) =>
        t.commands.canEdit &&
        !t.commands.isSuggesting &&
        t.commands.gridOf(nodeId: a.string('nodeId')) != null,
    checked: (t, a) {
      final grid = t.commands.gridOf(nodeId: a.string('nodeId'));
      return grid == null ? null : grid.bullets.value == a.string('bullets');
    },
    run: (t, a) => _result(
      t.commands.setGridBullets(
        GridBullets.parse(a.requireString('bullets')),
        nodeId: a.string('nodeId'),
      ),
    ),
  ),
  EditorCommandSpec(
    id: 'write.grid.addItem',
    title: 'Add grid item',
    category: 'Format',
    wonkyOnly: true,
    suggestable: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'nodeId': JsonSchema.string(),
        'index': JsonSchema.integer(minimum: 0),
      },
    ),
    enabled: (t, a) =>
        t.commands.canEdit &&
        !t.commands.isSuggesting &&
        t.commands.gridOf(nodeId: a.string('nodeId')) != null,
    run: (t, a) => _result(
      t.commands.addGridItem(
        nodeId: a.string('nodeId'),
        index: a.integer('index'),
      ),
    ),
  ),
  EditorCommandSpec(
    id: 'write.grid.removeItem',
    title: 'Remove grid item',
    category: 'Format',
    wonkyOnly: true,
    suggestable: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'nodeId': JsonSchema.string(),
        'index': JsonSchema.integer(minimum: 0),
      },
      required: ['index'],
    ),
    enabled: (t, a) =>
        t.commands.canEdit &&
        !t.commands.isSuggesting &&
        t.commands.gridOf(nodeId: a.string('nodeId')) != null,
    run: (t, a) => _result(
      t.commands.removeGridItem(
        a.integer('index') ?? 0,
        nodeId: a.string('nodeId'),
      ),
    ),
  ),
  EditorCommandSpec(
    id: 'write.grid.delete',
    title: 'Delete grid',
    category: 'Format',
    wonkyOnly: true,
    suggestable: false,
    argsSchema: const JsonSchema.object(
      properties: {'nodeId': JsonSchema.string()},
    ),
    enabled: (t, a) =>
        t.commands.canEdit &&
        !t.commands.isSuggesting &&
        t.commands.gridOf(nodeId: a.string('nodeId')) != null,
    run: (t, a) {
      final grid = t.commands.gridOf(nodeId: a.string('nodeId'));
      return _result(grid != null && t.commands.deleteBlock(nodeId: grid.id));
    },
  ),
  EditorCommandSpec(
    id: 'write.link.setStyle',
    title: 'Link style',
    category: 'Format',
    wonkyOnly: true,
    radio: true,
    requiredRole: Role.commenter,
    argsSchema: JsonSchema.object(
      properties: {'style': JsonSchema.string(enumValues: _linkStyles)},
      required: const ['style'],
    ),
    enabled: (t, _) => t.commands.canEdit && t.commands.linkStyleAt() != null,
    checked: (t, a) {
      final style = t.commands.linkStyleAt();
      return style == null ? null : style == a.string('style');
    },
    run: (t, a) => _result(t.commands.setLinkStyle(a.requireString('style'))),
  ),
  EditorCommandSpec(
    id: 'write.format.chip',
    title: 'Chip',
    category: 'Format',
    wonkyOnly: true,
    requiredRole: Role.commenter,
    enabled: (t, _) => t.commands.canInsertLink(),
    checked: (t, _) => t.commands.isChipActive(),
    run: (t, _) => _result(t.commands.toggleChip()),
  ),
  EditorCommandSpec(
    id: 'write.heading.toggleStep',
    title: 'Numbered heading',
    category: 'Format',
    wonkyOnly: true,
    requiredRole: Role.commenter,
    enabled: (t, _) => t.commands.canChangeBlockType(),
    checked: (t, _) => t.commands.isStepActive(),
    run: (t, _) => _result(t.commands.toggleStep()),
  ),
  EditorCommandSpec(
    id: 'write.heading.setStepNumber',
    title: 'Step number',
    category: 'Format',
    wonkyOnly: true,
    requiredRole: Role.commenter,
    argsSchema: const JsonSchema.object(
      properties: {
        'n': JsonSchema.integer(minimum: 0, maximum: 9999),
        'nodeId': JsonSchema.string(),
      },
      required: ['n'],
    ),
    enabled: (t, _) => t.commands.canEdit,
    run: (t, a) => _result(
      t.commands.setStepNumber(a.integer('n') ?? 1, nodeId: a.string('nodeId')),
    ),
  ),
  EditorCommandSpec(
    id: 'write.heading.renumberSteps',
    title: 'Renumber steps',
    category: 'Format',
    wonkyOnly: true,
    requiredRole: Role.commenter,
    enabled: (t, _) => t.commands.canEdit,
    run: (t, _) => _result(t.commands.renumberSteps()),
  ),
];

extension<T> on T {
  R let<R>(R Function(T value) f) => f(this);
}
