import '../src/commands/json_schema.dart';
import 'mcp_tool.dart';

/// Shared argument types of the `write.*` tools (Write 09 §1.2).
abstract final class WriteSchemas {
  static const documentUuid = JsonSchema.string(
    format: 'uuid',
    description:
        'The document: the drive item uuid (as in /d/<uuid>) or the '
        'document uuid.',
  );

  static const _quote = JsonSchema.string(
    minLength: 1,
    maxLength: 2000,
    description:
        'Exact, case-sensitive text of the document (plain text: embeds are '
        'U+FFFC). Prefer short unique quotes of 10–80 characters.',
  );
  static const _occurrence = JsonSchema.integer(
    minimum: 1,
    description:
        '1-based occurrence when the quote/heading appears more than once.',
  );
  static const _heading = JsonSchema.string(
    minLength: 1,
    description: 'Heading text (case-insensitive, without numbering).',
  );
  static const _level = JsonSchema.integer(minimum: 1, maximum: 6);

  static ObjectSchema _typed(
    String type, [
    Map<String, JsonSchema> props = const {},
    List<String> required = const [],
  ]) => ObjectSchema(
    properties: {
      'type': JsonSchema.string(enumValues: [type]),
      ...props,
    },
    required: ['type', ...required],
  );

  static final Map<String, JsonSchema> _headingProps = {
    'heading': _heading,
    'heading_index': const JsonSchema.integer(
      minimum: 0,
      description: '0-based index in the outline (instead of heading).',
    ),
    'level': _level,
    'occurrence': _occurrence,
  };

  /// Where to insert (`Position`).
  static final position = JsonSchema.anyOf(
    [
      _typed('start'),
      _typed('end'),
      _typed(
        'offset',
        {'offset': const JsonSchema.integer(minimum: 0)},
        ['offset'],
      ),
      _typed(
        'before_quote',
        {'quote': _quote, 'occurrence': _occurrence},
        ['quote'],
      ),
      _typed(
        'after_quote',
        {'quote': _quote, 'occurrence': _occurrence},
        ['quote'],
      ),
      _typed('before_heading', _headingProps),
      _typed('after_heading', _headingProps),
      _typed('end_of_section', _headingProps),
      _typed('replace_heading_section', {
        ..._headingProps,
        'include_heading': const JsonSchema.boolean(defaultValue: false),
      }),
    ],
    description:
        'Where to insert. {"type":"start"|"end"}, {"type":"offset",'
        '"offset":120} (0-based Delta offset), {"type":"after_quote",'
        '"quote":"Next steps"}, {"type":"before_quote",…}, '
        '{"type":"after_heading","heading":"Budget"} (right after the '
        'heading line), {"type":"before_heading",…}, {"type":'
        '"end_of_section","heading":"Budget"}, {"type":'
        '"replace_heading_section","heading":"Budget"} (replaces the '
        'section body).',
  );

  /// What to read or change (`Range`).
  static final range = JsonSchema.anyOf(
    [
      _typed(
        'offsets',
        {
          'start': const JsonSchema.integer(minimum: 0),
          'length': const JsonSchema.integer(minimum: 0),
        },
        ['start', 'length'],
      ),
      _typed('quote', {'quote': _quote, 'occurrence': _occurrence}, ['quote']),
      _typed('heading_section', {
        ..._headingProps,
        'include_heading': const JsonSchema.boolean(defaultValue: true),
      }),
      _typed(
        'block',
        {
          'block_index': const JsonSchema.integer(minimum: 0),
          'count': const JsonSchema.integer(minimum: 1, defaultValue: 1),
        },
        ['block_index'],
      ),
      _typed('all'),
    ],
    description:
        'A range. {"type":"quote","quote":"the old plan","occurrence":2} '
        '(preferred), {"type":"offsets","start":120,"length":40} (0-based '
        'Delta offsets, UTF-16, embeds count 1), {"type":"heading_section",'
        '"heading":"Budget","include_heading":true}, {"type":"block",'
        '"block_index":12,"count":1} (blocks map of write.get_document) or '
        '{"type":"all"}.',
  );

  /// Mutation options (all mutating tools).
  static const Map<String, JsonSchema> mutation = {
    'expected_revision': JsonSchema.integer(
      minimum: 0,
      description:
          'Optional optimistic check: fails with revision_mismatch when the '
          'document head is at another revision. Pass it when using offsets '
          'from an earlier read.',
    ),
    'mode': JsonSchema.string(
      enumValues: ['edit', 'suggest'],
      description:
          '"edit" (default for editors) or "suggest" (tracked change; '
          'forced for commenters).',
    ),
    'label': JsonSchema.string(
      maxLength: 200,
      description: 'Short label shown in history and as the undo label.',
    ),
  };

  static ObjectSchema doc(
    Map<String, JsonSchema> props, {
    List<String> required = const [],
    bool mutating = false,
  }) => ObjectSchema(
    properties: {
      'document_uuid': documentUuid,
      ...props,
      if (mutating) ...mutation,
    },
    required: ['document_uuid', ...required],
  );

  static const findOptions = <String, JsonSchema>{
    'regex': JsonSchema.boolean(
      defaultValue: false,
      description: 'Interpret the query as a Dart RegExp (unicode).',
    ),
    'match_case': JsonSchema.boolean(defaultValue: false),
    'whole_word': JsonSchema.boolean(defaultValue: false),
  };

  static const mutationResult = JsonSchema.object(
    additionalProperties: true,
    properties: {
      'change_id': JsonSchema.string(),
      'revision': JsonSchema.integer(),
      'applied_range': JsonSchema.object(
        additionalProperties: true,
        properties: {
          'start': JsonSchema.integer(),
          'length': JsonSchema.integer(),
        },
      ),
      'suggestion_id': JsonSchema.string(),
      'summary': JsonSchema.string(),
      'warnings': JsonSchema.array(JsonSchema.any()),
    },
  );
}

const _addressing =
    ' Addressing: prefer quote ranges ({"type":"quote","quote":"…"}); '
    'offsets are 0-based Delta offsets (UTF-16 code units, embeds count 1, '
    'each line ends with one "\\n") valid for the returned revision only. '
    'Content is Markdown-only (no colors/fonts: themes control appearance). '
    'Every call is one undoable change with a change_id for changes.revert.';

/// Headless `write.*` tools (Write 09 §2).
abstract final class WriteTools {
  static const _read = {McpScope.writeRead};
  static const _edit = {McpScope.writeEdit};

  static final getDocument = McpToolDefinition(
    name: 'write.get_document',
    title: 'Read a document',
    description:
        'Reads a Wonky Write document as Markdown (default), plain text, '
        'Quill Delta JSON or outline. Use range to read one section. '
        'include_blocks adds a blocks map with Delta offsets per block. '
        'Long content is paged: when truncated is true, call again with '
        'next_cursor. suggestions: "accepted" (default; pending suggestions '
        'shown as if accepted), "original", or "raw" (CriticMarkup '
        '{++ins++}/{--del--}).',
    inputSchema: WriteSchemas.doc({
      'format': const JsonSchema.string(
        enumValues: ['markdown', 'delta', 'text', 'outline'],
        defaultValue: 'markdown',
      ),
      'range': WriteSchemas.range,
      'suggestions': const JsonSchema.string(
        enumValues: ['accepted', 'original', 'raw'],
      ),
      'include_blocks': const JsonSchema.boolean(defaultValue: false),
      'revision': const JsonSchema.integer(
        minimum: 0,
        description: 'Read an older revision (Editor+).',
      ),
      'max_chars': const JsonSchema.integer(
        minimum: 100,
        maximum: 200000,
        defaultValue: 50000,
      ),
      'cursor': McpSchemas.cursor,
    }),
    annotations: McpToolAnnotations.read,
    scopes: _read,
  );

  static final getOutline = McpToolDefinition(
    name: 'write.get_outline',
    title: 'Get the outline',
    description:
        'Returns the headings of a document with level, text, numbering and '
        'the Delta range of each section. Use it to navigate long documents '
        'and to address sections ({"type":"heading_section",…}).',
    inputSchema: WriteSchemas.doc({}),
    annotations: McpToolAnnotations.read,
    scopes: _read,
  );

  static final getStats = McpToolDefinition(
    name: 'write.get_stats',
    title: 'Document statistics',
    description:
        'Word, character, paragraph, heading, list, image, table and code '
        'block counts, reading time, open comments and pending suggestions. '
        'Optional range restricts the text counts.',
    inputSchema: WriteSchemas.doc({'range': WriteSchemas.range}),
    annotations: McpToolAnnotations.read,
    scopes: _read,
  );

  static final search = McpToolDefinition(
    name: 'write.search',
    title: 'Search in a document',
    description:
        'Finds text in a document (plain text; matches never span a line '
        'end). Each match has offsets, context, the enclosing heading path '
        'and its occurrence number, usable directly for quote addressing '
        '({"type":"quote","quote":<text>,"occurrence":<occurrence>}).',
    inputSchema: WriteSchemas.doc(
      {
        'query': const JsonSchema.string(minLength: 1, maxLength: 500),
        ...WriteSchemas.findOptions,
        'scope': WriteSchemas.range,
        'limit': const JsonSchema.integer(
          minimum: 1,
          maximum: 500,
          defaultValue: 100,
        ),
        'context_chars': const JsonSchema.integer(
          minimum: 0,
          maximum: 200,
          defaultValue: 40,
        ),
      },
      required: ['query'],
    ),
    annotations: McpToolAnnotations.read,
    scopes: _read,
  );

  static final getPageSetup = McpToolDefinition(
    name: 'write.get_page_setup',
    title: 'Get the page setup',
    description:
        'Returns the document\'s page setup (paper size, orientation, '
        'margins, layout pages/pageless, header/footer) with the resolved '
        'paper size in points.',
    inputSchema: WriteSchemas.doc({}),
    annotations: McpToolAnnotations.read,
    scopes: _read,
  );

  static final insertMarkdown = McpToolDefinition(
    name: 'write.insert_markdown',
    title: 'Insert Markdown',
    description:
        'Inserts GitHub-flavored Markdown at a position (headings, lists, '
        'quotes, code, tables, links, images by URL). as: "auto" (default; a '
        'single paragraph inserted mid-line is merged inline, otherwise '
        'blocks), "inline" or "blocks". Use it to add new content; use '
        'write.replace_range to rewrite existing text.$_addressing',
    inputSchema: WriteSchemas.doc(
      {
        'markdown': const JsonSchema.string(maxLength: 1000000),
        'at': WriteSchemas.position,
        'as': const JsonSchema.string(
          enumValues: ['auto', 'inline', 'blocks'],
          defaultValue: 'auto',
        ),
      },
      required: ['markdown', 'at'],
      mutating: true,
    ),
    outputSchema: WriteSchemas.mutationResult,
    scopes: _edit,
  );

  static final replaceText = McpToolDefinition(
    name: 'write.replace_text',
    title: 'Find and replace',
    description:
        'Replaces occurrences of text (Find & Replace). occurrence is '
        'required: a 1-based number or "all". The replacement keeps the '
        'formatting of the first replaced character (replace_format: "text"), '
        'or is parsed as inline Markdown ("markdown_inline"). Use it for '
        'small wording changes.$_addressing',
    inputSchema: WriteSchemas.doc(
      {
        'find': const JsonSchema.string(minLength: 1, maxLength: 2000),
        'replace': const JsonSchema.string(maxLength: 100000),
        'occurrence': const JsonSchema.anyOf([
          JsonSchema.integer(minimum: 1),
          JsonSchema.string(enumValues: ['all']),
        ]),
        ...WriteSchemas.findOptions,
        'replace_format': const JsonSchema.string(
          enumValues: ['text', 'markdown_inline'],
          defaultValue: 'text',
        ),
        'scope': WriteSchemas.range,
      },
      required: ['find', 'replace', 'occurrence'],
      mutating: true,
    ),
    outputSchema: WriteSchemas.mutationResult,
    scopes: _edit,
  );

  static final replaceRange = McpToolDefinition(
    name: 'write.replace_range',
    title: 'Replace a range',
    description:
        'Replaces a range (quote, section, blocks, offsets) with Markdown. '
        'With preserve_overlays (default) only the changed words are '
        'rewritten, so comments on unchanged text survive. Use the smallest '
        'range that covers the change.$_addressing',
    inputSchema: WriteSchemas.doc(
      {
        'range': WriteSchemas.range,
        'markdown': const JsonSchema.string(maxLength: 1000000),
        'preserve_overlays': const JsonSchema.boolean(defaultValue: true),
      },
      required: ['range', 'markdown'],
      mutating: true,
    ),
    outputSchema: WriteSchemas.mutationResult,
    scopes: _edit,
  );

  static final deleteRange = McpToolDefinition(
    name: 'write.delete_range',
    title: 'Delete a range',
    description:
        'Deletes a range. Whole blocks are removed with their line ends; '
        'deleting "all" leaves one empty paragraph.$_addressing',
    inputSchema: WriteSchemas.doc(
      {'range': WriteSchemas.range},
      required: ['range'],
      mutating: true,
    ),
    outputSchema: WriteSchemas.mutationResult,
    annotations: const McpToolAnnotations(destructive: true),
    scopes: _edit,
  );

  static final applyFormat = McpToolDefinition(
    name: 'write.apply_format',
    title: 'Format text',
    description:
        'Sets or removes inline formatting on a range: bold, italic, strike, '
        'code (true sets, false removes) and link (URL sets, null removes; '
        'http(s), mailto or wonky:// only). code: true removes bold/italic/'
        'strike. Line ends and embeds are skipped.$_addressing',
    inputSchema: WriteSchemas.doc(
      {
        'range': WriteSchemas.range,
        'set': const JsonSchema.object(
          properties: {
            'bold': JsonSchema.boolean(),
            'italic': JsonSchema.boolean(),
            'strike': JsonSchema.boolean(),
            'code': JsonSchema.boolean(),
            'link': JsonSchema.nullable(JsonSchema.string()),
          },
        ),
      },
      required: ['range', 'set'],
      mutating: true,
    ),
    outputSchema: WriteSchemas.mutationResult,
    scopes: _edit,
  );

  static final setBlockType = McpToolDefinition(
    name: 'write.set_block_type',
    title: 'Set the block type',
    description:
        'Changes every line touched by the range to a paragraph, heading '
        '(level 1–6), bullet/ordered/task list item (indent 0–8, checked; '
        'a list item in a quote keeps the quote unless quoted is false), '
        'quote or code block (language). Converting lines to code merges '
        'them into one code block.$_addressing',
    inputSchema: WriteSchemas.doc(
      {
        'range': WriteSchemas.range,
        'type': const JsonSchema.string(
          enumValues: [
            'paragraph',
            'heading',
            'bullet',
            'ordered',
            'task',
            'quote',
            'code',
          ],
        ),
        'level': const JsonSchema.integer(minimum: 1, maximum: 6),
        'indent': const JsonSchema.integer(minimum: 0, maximum: 8),
        'checked': const JsonSchema.boolean(),
        'quoted': const JsonSchema.boolean(),
        'language': const JsonSchema.string(maxLength: 40),
      },
      required: ['range', 'type'],
      mutating: true,
    ),
    outputSchema: WriteSchemas.mutationResult,
    scopes: _edit,
  );

  static final setMarkdown = McpToolDefinition(
    name: 'write.set_markdown',
    title: 'Replace the whole document',
    description:
        'Replaces the whole document with Markdown using a minimal diff '
        '(comments and suggestions on unchanged text survive). Avoid it '
        'unless you really rewrite the whole document; prefer targeted '
        'tools. front_matter: YAML string, null to remove, omit to keep.'
        '$_addressing',
    inputSchema: WriteSchemas.doc(
      {
        'markdown': const JsonSchema.string(maxLength: 1000000),
        'front_matter': const JsonSchema.nullable(JsonSchema.string()),
      },
      required: ['markdown'],
      mutating: true,
    ),
    outputSchema: WriteSchemas.mutationResult,
    annotations: const McpToolAnnotations(destructive: true),
    scopes: _edit,
  );

  static final applyDelta = McpToolDefinition(
    name: 'write.apply_delta',
    title: 'Apply a Delta (expert)',
    description:
        'Applies a raw Quill Delta change ([{"retain":n},{"insert":"…",'
        '"attributes":{…}},{"delete":n}]) based on base_revision; it is '
        'transformed to the head like a client op and validated. Prefer the '
        'other tools.$_addressing',
    inputSchema: WriteSchemas.doc(
      {
        'delta': const JsonSchema.array(
          JsonSchema.object(additionalProperties: true),
          minItems: 1,
        ),
        'base_revision': const JsonSchema.integer(minimum: 0),
      },
      required: ['delta', 'base_revision'],
      mutating: true,
    ),
    outputSchema: WriteSchemas.mutationResult,
    scopes: _edit,
  );

  static final insertImage = McpToolDefinition(
    name: 'write.insert_image',
    title: 'Insert an image',
    description:
        'Inserts an image block at a position from an https URL or base64 '
        'data (png, jpeg, gif, webp, svg; max 20 MB). With store (default) '
        'the image is copied into Wonky storage.$_addressing',
    inputSchema: WriteSchemas.doc(
      {
        'at': WriteSchemas.position,
        'source': const JsonSchema.object(
          properties: {
            'url': JsonSchema.string(),
            'base64': JsonSchema.string(),
            'mime': JsonSchema.string(
              enumValues: [
                'image/png',
                'image/jpeg',
                'image/gif',
                'image/webp',
                'image/svg+xml',
              ],
            ),
          },
        ),
        'alt': const JsonSchema.string(maxLength: 1000),
        'title': const JsonSchema.string(maxLength: 1000),
        'store': const JsonSchema.boolean(defaultValue: true),
      },
      required: ['at', 'source', 'alt'],
      mutating: true,
    ),
    outputSchema: WriteSchemas.mutationResult,
    annotations: const McpToolAnnotations(openWorld: true),
    scopes: _edit,
  );

  static final insertTable = McpToolDefinition(
    name: 'write.insert_table',
    title: 'Insert a table',
    description:
        'Inserts a table: rows of cells (row 0 is the header; cells are '
        'inline Markdown; rows are padded to the widest). align per column: '
        '"left", "center", "right" or null.$_addressing',
    inputSchema: WriteSchemas.doc(
      {
        'at': WriteSchemas.position,
        'rows': const JsonSchema.array(
          JsonSchema.array(JsonSchema.string()),
          minItems: 1,
        ),
        'align': const JsonSchema.array(
          JsonSchema.nullable(
            JsonSchema.string(enumValues: ['left', 'center', 'right']),
          ),
        ),
      },
      required: ['at', 'rows'],
      mutating: true,
    ),
    outputSchema: WriteSchemas.mutationResult,
    scopes: _edit,
  );

  static final updateTable = McpToolDefinition(
    name: 'write.update_table',
    title: 'Update a table',
    description:
        'Updates a table found by table_id or table_index (0-based among the '
        'tables in document order): either replace all rows, or apply '
        'operations in order: {"op":"set_cell","row","col","markdown"}, '
        '{"op":"insert_row","at","cells"?}, {"op":"delete_row","row"}, '
        '{"op":"insert_column","at","header"?,"cells"?}, '
        '{"op":"delete_column","col"}, {"op":"set_align","col","align"}.'
        '$_addressing',
    inputSchema: WriteSchemas.doc(
      {
        'table': const JsonSchema.object(
          properties: {
            'table_id': JsonSchema.string(),
            'table_index': JsonSchema.integer(minimum: 0),
          },
        ),
        'rows': const JsonSchema.array(JsonSchema.array(JsonSchema.string())),
        'operations': const JsonSchema.array(
          JsonSchema.object(additionalProperties: true),
        ),
      },
      required: ['table'],
      mutating: true,
    ),
    outputSchema: WriteSchemas.mutationResult,
    scopes: _edit,
  );

  static final updatePageSetup = McpToolDefinition(
    name: 'write.update_page_setup',
    title: 'Update the page setup',
    description:
        'Merges a partial page setup into the document\'s page setup (e.g. '
        '{"layout":"pageless"}, {"paper":"a4","orientation":"landscape"}, '
        '{"margins":{"top":72}}). Validated; revert with changes.revert.',
    inputSchema: WriteSchemas.doc(
      {'patch': const JsonSchema.object(additionalProperties: true)},
      required: ['patch'],
    ),
    scopes: _edit,
  );

  static final listSuggestions = McpToolDefinition(
    name: 'write.list_suggestions',
    title: 'List suggestions',
    description:
        'Lists pending suggestions (tracked changes) with author, summary, '
        'parts (insert/delete/format with offsets and text) and the '
        'discussion thread.',
    inputSchema: WriteSchemas.doc({
      'author_uuid': McpSchemas.uuid,
      'limit': McpSchemas.limit,
      'cursor': McpSchemas.cursor,
    }),
    annotations: McpToolAnnotations.read,
    scopes: _read,
  );

  static final acceptSuggestion = McpToolDefinition(
    name: 'write.accept_suggestion',
    title: 'Accept suggestions',
    description:
        'Accepts suggestions by id, or "all" (optionally only those of '
        'author_uuid). One change for all ids. Editors only.',
    inputSchema: WriteSchemas.doc(
      {
        'suggestion_ids': const JsonSchema.anyOf([
          JsonSchema.array(JsonSchema.string(), minItems: 1),
          JsonSchema.string(enumValues: ['all']),
        ]),
        'author_uuid': McpSchemas.uuid,
      },
      required: ['suggestion_ids'],
      mutating: true,
    ),
    outputSchema: WriteSchemas.mutationResult,
    scopes: _edit,
  );

  static final rejectSuggestion = McpToolDefinition(
    name: 'write.reject_suggestion',
    title: 'Reject suggestions',
    description:
        'Rejects suggestions by id, or "all" (optionally only those of '
        'author_uuid). Editors reject any; authors may withdraw their own.',
    inputSchema: WriteSchemas.doc(
      {
        'suggestion_ids': const JsonSchema.anyOf([
          JsonSchema.array(JsonSchema.string(), minItems: 1),
          JsonSchema.string(enumValues: ['all']),
        ]),
        'author_uuid': McpSchemas.uuid,
      },
      required: ['suggestion_ids'],
      mutating: true,
    ),
    outputSchema: WriteSchemas.mutationResult,
    scopes: _edit,
  );

  static final suggestEdit = McpToolDefinition(
    name: 'write.suggest_edit',
    title: 'Suggest an edit',
    description:
        'Creates a replacement suggestion (tracked change) for a range: the '
        'range is marked as deleted and the Markdown inserted as a '
        'suggestion. markdown "" suggests a deletion. comment is posted to '
        'the suggestion\'s discussion thread.$_addressing',
    inputSchema: WriteSchemas.doc(
      {
        'range': WriteSchemas.range,
        'markdown': const JsonSchema.string(maxLength: 1000000),
        'comment': const JsonSchema.string(maxLength: 10000),
      },
      required: ['range', 'markdown'],
      mutating: true,
    ),
    outputSchema: WriteSchemas.mutationResult,
    scopes: _edit,
  );

  static final listThemes = McpToolDefinition(
    name: 'write.list_themes',
    title: 'List themes',
    description:
        'Lists document themes: built-in ones and the user\'s own. With '
        'document_uuid also marks (and includes) the theme that document '
        'uses.',
    inputSchema: ObjectSchema(
      properties: {
        'scope': const JsonSchema.string(
          enumValues: ['all', 'builtin', 'mine'],
          defaultValue: 'all',
        ),
        'document_uuid': WriteSchemas.documentUuid,
      },
    ),
    annotations: McpToolAnnotations.read,
    scopes: _read,
  );

  static final applyTheme = McpToolDefinition(
    name: 'write.apply_theme',
    title: 'Apply a theme',
    description:
        'Assigns a theme to a document (theme_uuid from write.list_themes; '
        'null = the viewer\'s default theme). Themes control all appearance '
        '(fonts, colors, spacing). Revert with changes.revert.',
    inputSchema: WriteSchemas.doc(
      {'theme_uuid': const JsonSchema.nullable(McpSchemas.uuid)},
      required: ['theme_uuid'],
    ),
    scopes: _edit,
  );

  static final all = [
    getDocument,
    getOutline,
    getStats,
    search,
    getPageSetup,
    insertMarkdown,
    replaceText,
    replaceRange,
    deleteRange,
    applyFormat,
    setBlockType,
    setMarkdown,
    applyDelta,
    insertImage,
    insertTable,
    updateTable,
    updatePageSetup,
    listSuggestions,
    acceptSuggestion,
    rejectSuggestion,
    suggestEdit,
    listThemes,
    applyTheme,
  ];
}

/// Write-specific UI-bridge tools (`ui.write.*`, Write 09 §3), executed in
/// the live Wonky Write window.
abstract final class UiWriteTools {
  static const _scopes = {McpScope.uiControl};
  static const _session = JsonSchema.string(
    description:
        'Target window from ui.list_sessions; defaults to the most recently '
        'focused Wonky Write window.',
  );

  static ObjectSchema _schema([
    Map<String, JsonSchema> props = const {},
    List<String> required = const [],
  ]) => ObjectSchema(
    properties: {'session_id': _session, ...props},
    required: required,
  );

  static final getSelection = McpToolDefinition(
    name: 'ui.write.get_selection',
    title: 'Get the selection',
    description:
        'Returns the selection in the open document: offsets, selected text '
        'and Markdown, block types, active formats and the editing mode.',
    inputSchema: _schema(),
    annotations: McpToolAnnotations.read,
    scopes: _scopes,
  );

  static final selectRange = McpToolDefinition(
    name: 'ui.write.select_range',
    title: 'Select a range',
    description:
        'Selects Delta offsets {start, length} in the open document and '
        'scrolls them into view; returns the new selection.',
    inputSchema: _schema(
      {
        'start': const JsonSchema.integer(minimum: 0),
        'length': const JsonSchema.integer(minimum: 0),
      },
      ['start', 'length'],
    ),
    scopes: _scopes,
  );

  static final selectText = McpToolDefinition(
    name: 'ui.write.select_text',
    title: 'Select text',
    description:
        'Selects a quote ({quote, occurrence?}) in the open document and '
        'scrolls it into view; returns the new selection.',
    inputSchema: _schema(
      {
        'quote': const JsonSchema.string(minLength: 1, maxLength: 2000),
        'occurrence': const JsonSchema.integer(minimum: 1),
      },
      ['quote'],
    ),
    scopes: _scopes,
  );

  static final scrollTo = McpToolDefinition(
    name: 'ui.write.scroll_to',
    title: 'Scroll to',
    description:
        'Scrolls the open document to a target: {"heading":"Budget"}, '
        '{"heading_index":2}, {"offset":120}, {"comment_thread_uuid":…} or '
        '{"suggestion_id":…} (activates the card).',
    inputSchema: _schema(
      {
        'target': const JsonSchema.object(
          properties: {
            'heading': JsonSchema.string(),
            'heading_index': JsonSchema.integer(minimum: 0),
            'offset': JsonSchema.integer(minimum: 0),
            'comment_thread_uuid': JsonSchema.string(),
            'suggestion_id': JsonSchema.string(),
          },
        ),
        'align': const JsonSchema.string(enumValues: ['top', 'center']),
      },
      ['target'],
    ),
    scopes: _scopes,
  );

  static final getLayoutInfo = McpToolDefinition(
    name: 'ui.write.get_layout_info',
    title: 'Get layout information',
    description:
        'Returns layout information of the open document: zoom, layout mode '
        '(pages/pageless), document length, the visible Delta range and the '
        'first visible heading.',
    inputSchema: _schema(),
    annotations: McpToolAnnotations.read,
    scopes: _scopes,
  );

  static final setViewMode = McpToolDefinition(
    name: 'ui.write.set_view_mode',
    title: 'Set the editing mode',
    description: 'Switches the editing mode: editing, suggesting or viewing.',
    inputSchema: _schema(
      {
        'mode': const JsonSchema.string(
          enumValues: ['editing', 'suggesting', 'viewing'],
        ),
      },
      ['mode'],
    ),
    scopes: _scopes,
  );

  static final setLayoutMode = McpToolDefinition(
    name: 'ui.write.set_layout_mode',
    title: 'Set the layout',
    description:
        'Switches the document layout between pages and pageless (an '
        'undoable document setting).',
    inputSchema: _schema(
      {
        'layout': const JsonSchema.string(enumValues: ['pages', 'pageless']),
      },
      ['layout'],
    ),
    scopes: _scopes,
  );

  static final toggleOutline = McpToolDefinition(
    name: 'ui.write.toggle_outline',
    title: 'Show or hide the outline',
    description: 'Opens (open: true), closes or toggles the outline panel.',
    inputSchema: _schema({'open': const JsonSchema.boolean()}),
    scopes: _scopes,
  );

  static final insertMarkdownAtSelection = McpToolDefinition(
    name: 'ui.write.insert_markdown_at_selection',
    title: 'Insert Markdown at the selection',
    description:
        'Inserts Markdown at the caret of the open document (or replaces the '
        'selection with replace_selection). Lands on the user\'s undo stack '
        'as one step.',
    inputSchema: _schema(
      {
        'markdown': const JsonSchema.string(maxLength: 1000000),
        'replace_selection': const JsonSchema.boolean(defaultValue: false),
      },
      ['markdown'],
    ),
    scopes: _scopes,
  );

  static final all = [
    getSelection,
    selectRange,
    selectText,
    scrollTo,
    getLayoutInfo,
    setViewMode,
    setLayoutMode,
    toggleOutline,
    insertMarkdownAtSelection,
  ];
}
