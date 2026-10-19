import 'package:serverpod/serverpod.dart';
import 'package:wonky_slides_core/templates.dart';
import 'package:wonky_slides_core/themes.dart' show BuiltInThemes;
import 'package:wonky_write_core/wonky_write_core.dart' as core;

import '../../../slides/templates/slides_template_decks.dart';
import '../../common/models.dart';

/// A sheet of a built-in spreadsheet template. [rows] hold user input as
/// typed in a cell (numbers, text, `=` formulas in A1 notation, en_US).
class TemplateSheet {
  const TemplateSheet({
    required this.name,
    required this.rows,
    this.columnWidths = const {},
    this.boldRows = const {0},
    this.frozenRows = 1,
    this.numberFormats = const {},
  });

  final String name;
  final List<List<String?>> rows;

  /// Column index → width in px.
  final Map<int, double> columnWidths;

  /// Rows rendered bold (headers).
  final Set<int> boldRows;
  final int frozenRows;

  /// Column index → number format applied to the data rows.
  final Map<int, String> numberFormats;
}

/// A built-in template (specs/05 §3.1). Document templates carry Markdown,
/// spreadsheet templates carry [sheets].
class BuiltinTemplate {
  const BuiltinTemplate({
    required this.key,
    required this.kind,
    required this.name,
    required this.description,
    required this.category,
    this.markdown,
    this.sheets = const [],
    this.inGallery = true,
    this.themeKey,
    this.accent,
    this.banner = false,
    this.centeredHeadings = false,
    this.uppercaseHeadings = false,
    this.accentHeadings = false,
  }) : slides = null;

  /// (SL-22) A built-in presentation template: the core's [SlidesTemplate]
  /// (Slides 04 §15) with its key, name, category and Slides theme.
  BuiltinTemplate.presentation(SlidesTemplate this.slides)
    : key = slides.key,
      kind = DriveItemKind.presentation,
      name = slides.name,
      description = slides.description,
      category = TemplateCategory.values.byName(slides.category),
      markdown = null,
      sheets = const [],
      inGallery = true,
      themeKey = slides.themeKey,
      accent = null,
      banner = false,
      centeredHeadings = false,
      uppercaseHeadings = false,
      accentHeadings = false;

  final String key;
  final DriveItemKind kind;
  final String name;
  final String description;
  final TemplateCategory category;
  final String? markdown;
  final List<TemplateSheet> sheets;

  /// The deck of a presentation template (null for documents and
  /// spreadsheets).
  final SlidesTemplate? slides;

  /// Welcome content is created at sign-up but not listed in the gallery.
  final bool inGallery;

  /// The built-in Write theme documents from this template get (and the
  /// colors of its card), e.g. `classic-serif`; for presentations the
  /// built-in Slides theme (`aurora`).
  final String? themeKey;

  /// Card accent of templates without a theme (spreadsheets), `#rrggbb`.
  final String? accent;

  /// Card traits (see [TemplatePreviewStyle]); [accentHeadings] draws the
  /// headings in the accent color.
  final bool banner;
  final bool centeredHeadings;
  final bool uppercaseHeadings;
  final bool accentHeadings;

  /// The card's miniature page style (specs/05 §3.1).
  TemplatePreviewStyle? get previewStyle {
    final deck = slides;
    if (deck != null) return _slidesPreviewStyle(deck.themeKey);
    final key = themeKey;
    if (key != null) {
      final theme = core.BuiltinThemes.byKey(key);
      if (theme == null) return null;
      final json = theme.json;
      final light = (json['palette'] as Map).cast<String, Object?>();
      final darkJson = (json['dark'] as Map?)?['palette'] as Map?;
      final dark = darkJson?.cast<String, Object?>() ?? light;
      String color(Map<String, Object?> palette, String name) {
        var v = palette[name];
        // Palette references ("@accent") resolve within the palette.
        for (var i = 0; i < 4 && v is String && v.startsWith('@'); i++) {
          v = palette[v.substring(1)];
        }
        return v is String && v.startsWith('#') ? v : '#000000';
      }

      final fonts = (json['fonts'] as Map?)?.cast<String, Object?>() ?? {};
      final category = core.FontRegistry.lookup(
        '${fonts['heading'] ?? fonts['body'] ?? ''}',
      )?.category;
      return TemplatePreviewStyle(
        paper: color(light, 'page'),
        text: color(light, 'text'),
        heading: color(light, accentHeadings ? 'accent' : 'heading'),
        accent: color(light, 'accent'),
        darkPaper: color(dark, 'page'),
        darkText: color(dark, 'text'),
        darkHeading: color(dark, accentHeadings ? 'accent' : 'heading'),
        darkAccent: color(dark, 'accent'),
        banner: banner,
        centeredHeadings: centeredHeadings,
        uppercaseHeadings: uppercaseHeadings,
        fontCategory: switch (category) {
          core.FontCategory.serif => 'serif',
          core.FontCategory.mono => 'mono',
          _ => 'sans',
        },
      );
    }
    final a = accent;
    if (a == null) return null;
    return TemplatePreviewStyle(
      paper: '#ffffff',
      text: '#3f3f46',
      heading: '#18181b',
      accent: a,
      darkPaper: '#1c1c1f',
      darkText: '#d4d4d8',
      darkHeading: '#fafafa',
      darkAccent: a,
      banner: banner,
      centeredHeadings: false,
      uppercaseHeadings: false,
      fontCategory: 'sans',
    );
  }

  /// The card colors of a presentation template: the Slides theme's
  /// background, text and accent colors in both schemes; headings in the
  /// accent color on dark decks' cards look like the decks' titles.
  static TemplatePreviewStyle? _slidesPreviewStyle(String themeKey) {
    final def = BuiltInThemes.byKey(themeKey);
    if (def == null) return null;
    // Scheme order: bg1, text1, bg2, text2, accent1…6, link (opaque).
    String c(List<String> scheme, int i) =>
        scheme[i].substring(0, 7).toLowerCase();
    final category = core.FontRegistry.lookup(
      def.fonts.heading.family,
    )?.category;
    return TemplatePreviewStyle(
      paper: c(def.light, 0),
      text: c(def.light, 3),
      heading: c(def.light, 1),
      accent: c(def.light, 4),
      darkPaper: c(def.dark, 0),
      darkText: c(def.dark, 3),
      darkHeading: c(def.dark, 1),
      darkAccent: c(def.dark, 4),
      banner: false,
      centeredHeadings: false,
      uppercaseHeadings: false,
      fontCategory: switch (category) {
        core.FontCategory.serif => 'serif',
        core.FontCategory.mono => 'mono',
        _ => 'sans',
      },
    );
  }

  UuidValue get uuid =>
      const Uuid().v5obj(Namespace.url.value, 'wonky-template:$key');

  String get previewText {
    final deck = slides;
    if (deck != null) return SlidesTemplateDecks.previewText(deck);
    if (markdown != null) {
      // One line per block (for the thumbnail): headings keep a leading
      // "#", list markers become "•", tables become spaced cells.
      final lines = <String>[];
      for (var line in markdown!.split('\n')) {
        line = line.trim();
        if (line.isEmpty || RegExp(r'^\|?[\s:|-]+\|?$').hasMatch(line)) {
          continue;
        }
        final heading = line.startsWith('#');
        line = line
            .replaceFirst(RegExp(r'^#+\s*'), '')
            .replaceFirst(RegExp(r'^[-*+]\s+\[[ xX]\]\s*'), '☐ ')
            .replaceFirst(RegExp(r'^[-*+]\s+'), '• ')
            .replaceFirst(RegExp(r'^>\s*'), '')
            .replaceAll(RegExp(r'[*_`]'), '')
            .replaceAll(RegExp(r'\s*\|\s*'), '   ')
            .trim();
        // Placeholder items without text ("1.", "☐") add nothing.
        if (line.isEmpty || RegExp(r'^(\d+[.)]|[☐•—-])$').hasMatch(line)) {
          continue;
        }
        lines.add(heading ? '# $line' : line);
        if (lines.length >= 14) break;
      }
      final text = lines.join('\n');
      return text.length > 600 ? '${text.substring(0, 600)}…' : text;
    }
    final first = sheets.isEmpty ? const <List<String?>>[] : sheets.first.rows;
    final text = first
        .take(3)
        .map((r) => r.whereType<String>().join(' · '))
        .join(' — ');
    return text.length > 140 ? '${text.substring(0, 140)}…' : text;
  }
}

/// The built-in template gallery. Lines ending in two spaces are Markdown
/// hard line breaks (one block, several lines); keep the trailing spaces.
abstract final class BuiltinTemplates {
  static const welcomeDocumentKey = 'write.welcome';
  static const welcomeSpreadsheetKey = 'sheets.welcome';

  static BuiltinTemplate? byUuid(UuidValue uuid) {
    for (final t in all) {
      if (t.uuid == uuid) return t;
    }
    return null;
  }

  static BuiltinTemplate byKey(String key) =>
      all.firstWhere((t) => t.key == key);

  static final List<BuiltinTemplate> all = List.unmodifiable([
    ..._documentsAndSpreadsheets,
    // (SL-22) Presentations: the core's built-in Slides templates.
    for (final t in SlidesTemplates.all) BuiltinTemplate.presentation(t),
  ]);

  static const List<BuiltinTemplate> _documentsAndSpreadsheets = [
    BuiltinTemplate(
      key: welcomeDocumentKey,
      kind: DriveItemKind.document,
      name: 'New here? Read me first',
      description: 'An introduction to Wonky Work.',
      category: TemplateCategory.personal,
      inGallery: false,
      markdown: '''
# Welcome to Wonky Work

Welcome to Wonky Work, the free, open-source office suite that's a little different. It's built with Flutter and Serverpod, collectively vibe-coded with AI, and made for people who love to build things.

Markdown documents, spreadsheets, and slides, but with a twist. Everything works offline first, syncs in real time, and is built with AI in mind. There's even a built-in AI agent and an MCP server, so your favorite coding agent can work with your documents.

We're still in beta, so expect a few wonky bits. The good news? You can help us fix them.

## Meet the apps

Currently our apps run on the web only, as we make frequent updates. When things get a bit more stable, we’re bringing them to your desktop computer and your phone, too!

### Write

You're using it right now! Write lets you edit and publish Markdown documents, with more features on the way. It's currently the most polished app in the suite.

### Sheets

Create spreadsheets, crunch numbers, and make graphs. You can even import Excel files. There's already plenty of functionality, but also plenty of room to improve.

### Slides

Make beautiful presentations, including slides with syntax-highlighted code. Perfect for developers who have something to show off.

## Let’s build Wonky together

Here's where things get interesting. Wonky Work isn't just open source. **Anyone can help decide what we build next, and anyone can help build it.**

We've created a process that makes contributing easier than ever:

1. **Found a bug?** Click *Report a bug* and tell us what went wrong.
2. **Have a great idea?** Click *Suggest an improvement*.
3. **Vote for what matters.** Visit [Contribute & build](https://wonky.work/drive/improvements) to upvote bugs and feature requests.
4. **Pick something to build.** Our moderators select tasks and prepare detailed prompts that are ready for AI coding agents.
5. **Put your unused AI credits to work.** If you have some credits left on your AI plan, grab a task, let your favorite frontier model work on it, and submit a pull request.
6. **Make Wonky better for everyone.** Our GitHub bot reviews contributions and checks that they work as intended. Once merged, your changes become part of Wonky Work.

The more we build together, the less wonky Wonky gets.

## Now, make something!

This welcome document is just the beginning. Create a new document, spreadsheet, or presentation and give Wonky Work a spin.

And if you like what we're building, help us spread the word!

**Happy wonking!**
''',
    ),
    BuiltinTemplate(
      key: 'write.meeting-notes',
      kind: DriveItemKind.document,
      name: 'Meeting notes',
      description: 'Agenda, notes, decisions and action items.',
      category: TemplateCategory.work,
      themeKey: 'modern-sans',
      banner: true,
      markdown: '''
# Meeting notes

**Date:** Thursday, 10:00–10:45  
**Attendees:** Ada, Grace, Linus  
**Goal:** Agree on the launch plan

## Agenda

1. Status since last week (5 min)
2. Launch checklist (20 min)
3. Open questions (15 min)

## Notes

- The beta has 120 active users; feedback is mostly positive.
- Onboarding needs one more pass before launch.

## Decisions

- Launch moves to the first Monday of next month.

## Action items

- [ ] Ada — polish the onboarding flow — Friday
- [ ] Grace — draft the announcement — Tuesday
- [ ] Linus — book the retro — next week
''',
    ),
    BuiltinTemplate(
      key: 'write.project-brief',
      kind: DriveItemKind.document,
      name: 'Project brief',
      description: 'Goals, scope, milestones and risks of a project.',
      category: TemplateCategory.projectManagement,
      themeKey: 'technical',
      markdown: '''
# Project brief

## Summary

One paragraph describing the project, who it is for and why it matters now.

## Goals

- Ship a first version to ten pilot customers.
- Cut the time to first value from a day to an hour.

## Non-goals

- A mobile app (planned for later).

## Scope

| Area | In scope | Notes |
| --- | --- | --- |
| Onboarding | Yes | New guided setup |
| Billing | No | Unchanged |

## Milestones

1. **Kick-off** — week 1
2. **First release** — week 6
3. **Launch** — week 10

## Risks

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| Scope creep | Medium | Weekly scope review |

## Team

- **Lead:** Your name
- **Contributors:** Design, engineering, support
''',
    ),
    BuiltinTemplate(
      key: 'write.letter',
      kind: DriveItemKind.document,
      name: 'Letter',
      description: 'A formal letter with a classic letterhead.',
      category: TemplateCategory.personal,
      themeKey: 'classic-serif',
      centeredHeadings: true,
      markdown: '''
# Your Name

Street address · City, postal code · you@example.com

---

12 March

Recipient name  
Street address  
City, postal code

Dear recipient,

Start your letter here. Keep the first paragraph short and state why you are
writing.

Use the following paragraphs for the details: what happened, what you would
like to happen next, and by when.

Thank you for your time and consideration.

Kind regards,

Your Name
''',
    ),
    BuiltinTemplate(
      key: 'write.weekly-report',
      kind: DriveItemKind.document,
      name: 'Weekly report',
      description: 'A newsletter-style update on the week.',
      category: TemplateCategory.work,
      themeKey: 'newsletter',
      accentHeadings: true,
      markdown: '''
# This week at the studio

*Week 12 · Highlights, progress and what is next*

## Highlights

- The new dashboard is live for every team.
- Support response time dropped to under two hours.

> "The fastest week we have had this quarter." — the support team

## Progress

| Workstream | Status | Notes |
| --- | --- | --- |
| Dashboard | Shipped | Rolled out on Tuesday |
| Mobile | On track | Beta next week |
| Billing | At risk | Waiting on legal review |

## Next week

- [ ] Start the mobile beta
- [ ] Close the billing review

## Blockers

- Legal review of the new terms.
''',
    ),
    BuiltinTemplate(
      key: 'write.lecture-notes',
      kind: DriveItemKind.document,
      name: 'Lecture notes',
      description: 'Structured notes with key terms and questions.',
      category: TemplateCategory.education,
      themeKey: 'academic-apa',
      centeredHeadings: true,
      markdown: '''
# Lecture notes

**Course:** Introduction to Psychology  
**Lecture:** 4 — Memory  
**Date:** 3 October

## Key ideas

- Memory is reconstructive, not a recording.
- Sleep helps consolidate what we learn during the day.

## Key terms

- **Encoding** — turning experience into a memory trace.
- **Retrieval** — bringing a stored memory back to mind.

## Questions

- How does spaced repetition change long-term retention?

## Summary

Write a short summary of the lecture in your own words.
''',
    ),
    BuiltinTemplate(
      key: 'write.todo',
      kind: DriveItemKind.document,
      name: 'To-do list',
      description: 'A plain, focused checklist for the day or the week.',
      category: TemplateCategory.personal,
      themeKey: 'minimal-mono',
      markdown: '''
# To-do list

## Today

- [ ] Reply to the important emails
- [ ] 30 minutes of deep work on the big task
- [ ] Walk

## This week

- [ ] Plan the weekend
- [ ] Call the bank

## Someday

- [ ] Learn to bake bread
''',
    ),
    BuiltinTemplate(
      key: 'write.recipe',
      kind: DriveItemKind.document,
      name: 'Recipe',
      description: 'Ingredients, steps and notes for a favorite dish.',
      category: TemplateCategory.personal,
      themeKey: 'wonky-default',
      banner: true,
      markdown: '''
# Lemon pasta 🍋

*Serves 2 · 20 minutes*

## Ingredients

- 200 g spaghetti
- 1 lemon (zest and juice)
- 40 g butter
- 50 g grated parmesan
- Black pepper

## Steps

1. Cook the pasta in salted water; keep a cup of the water.
2. Melt the butter with the lemon zest.
3. Toss the pasta with the butter, juice, cheese and a splash of water.
4. Season with plenty of pepper and serve right away.

## Notes

> Add a handful of spinach at the end for something green.
''',
    ),
    BuiltinTemplate(
      key: 'write.story',
      kind: DriveItemKind.document,
      name: 'Story draft',
      description: 'A manuscript page for fiction and creative writing.',
      category: TemplateCategory.personal,
      themeKey: 'manuscript',
      centeredHeadings: true,
      uppercaseHeadings: true,
      markdown: '''
# The lighthouse

*A short story*

## Chapter one

The lamp had not been lit for eleven years when Mara climbed the stairs
with a box of matches and a borrowed key.

Outside, the sea kept its own time. Inside, the dust settled where it had
always settled, waiting for someone to disturb it.

---

She counted the steps on the way up. One hundred and twelve. On the way down
there would be one hundred and thirteen, and she would never find out why.
''',
    ),
    BuiltinTemplate(
      key: welcomeSpreadsheetKey,
      kind: DriveItemKind.spreadsheet,
      name: 'Welcome to Wonky Sheets',
      description: 'A short tour of Wonky Sheets.',
      category: TemplateCategory.personal,
      inGallery: false,
      sheets: [
        TemplateSheet(
          name: 'Welcome',
          columnWidths: {0: 220, 1: 120, 2: 360},
          rows: [
            ['Welcome to Wonky Sheets', null, null],
            ['Item', 'Amount', 'Try this'],
            ['Coffee', '3.5', 'Change a number and watch the total update'],
            ['Lunch', '12', 'Type =SUM( and select a range'],
            ['Books', '24.9', 'Select cells and press Mod+B'],
            ['Total', '=SUM(B3:B5)', 'Works offline — changes sync later'],
          ],
          boldRows: {0, 1, 5},
          frozenRows: 2,
        ),
      ],
    ),
    BuiltinTemplate(
      key: 'sheets.monthly-budget',
      kind: DriveItemKind.spreadsheet,
      name: 'Monthly budget',
      description: 'Planned and actual income and expenses.',
      category: TemplateCategory.finance,
      accent: '#16a34a',
      banner: true,
      sheets: [
        TemplateSheet(
          name: 'Budget',
          columnWidths: {0: 200, 1: 120, 2: 120, 3: 120},
          numberFormats: {1: '#,##0.00', 2: '#,##0.00', 3: '#,##0.00'},
          rows: [
            ['Category', 'Planned', 'Actual', 'Difference'],
            ['Salary', '3000', '3000', '=C2-B2'],
            ['Rent', '-1100', '-1100', '=C3-B3'],
            ['Groceries', '-400', '-436.2', '=C4-B4'],
            ['Transport', '-120', '-95', '=C5-B5'],
            ['Utilities', '-150', '-162.4', '=C6-B6'],
            ['Entertainment', '-100', '-80', '=C7-B7'],
            ['Savings', '-500', '-500', '=C8-B8'],
            ['Total', '=SUM(B2:B8)', '=SUM(C2:C8)', '=C9-B9'],
          ],
          boldRows: {0, 8},
        ),
      ],
    ),
    BuiltinTemplate(
      key: 'sheets.todo',
      kind: DriveItemKind.spreadsheet,
      name: 'To-do list',
      description: 'Tasks with due dates and status.',
      category: TemplateCategory.personal,
      accent: '#2563eb',
      banner: true,
      sheets: [
        TemplateSheet(
          name: 'Tasks',
          columnWidths: {0: 280, 1: 120, 2: 120},
          rows: [
            ['Task', 'Due', 'Status'],
            ['Plan the week', null, 'Not started'],
            ['Reply to emails', null, 'In progress'],
            ['Book appointments', null, 'Done'],
          ],
        ),
      ],
    ),
    BuiltinTemplate(
      key: 'sheets.project-tracker',
      kind: DriveItemKind.spreadsheet,
      name: 'Project tracker',
      description: 'Tasks, owners, dates and progress.',
      category: TemplateCategory.projectManagement,
      accent: '#7c3aed',
      banner: true,
      sheets: [
        TemplateSheet(
          name: 'Tracker',
          columnWidths: {0: 240, 1: 140, 2: 110, 3: 110, 4: 110, 5: 100},
          numberFormats: {5: '0%'},
          rows: [
            ['Task', 'Owner', 'Start', 'End', 'Status', 'Progress'],
            ['Kick-off', null, null, null, 'Done', '1'],
            ['Design', null, null, null, 'In progress', '0.5'],
            ['Build', null, null, null, 'Not started', '0'],
            ['Launch', null, null, null, 'Not started', '0'],
            ['Overall', null, null, null, null, '=AVERAGE(F2:F5)'],
          ],
          boldRows: {0, 5},
        ),
      ],
    ),
    BuiltinTemplate(
      key: 'sheets.invoice',
      kind: DriveItemKind.spreadsheet,
      name: 'Invoice',
      description: 'Line items with quantities, prices and totals.',
      category: TemplateCategory.finance,
      accent: '#0f766e',
      banner: true,
      sheets: [
        TemplateSheet(
          name: 'Invoice',
          columnWidths: {0: 280, 1: 90, 2: 110, 3: 120},
          numberFormats: {2: '#,##0.00', 3: '#,##0.00'},
          rows: [
            ['Description', 'Quantity', 'Unit price', 'Amount'],
            ['Consulting (hours)', '10', '95', '=B2*C2'],
            ['Design work (hours)', '6', '80', '=B3*C3'],
            ['Materials', '1', '120', '=B4*C4'],
            ['Subtotal', null, null, '=SUM(D2:D4)'],
            ['Tax (20%)', null, null, '=D5*0.2'],
            ['Total', null, null, '=D5+D6'],
          ],
          boldRows: {0, 6},
        ),
      ],
    ),
    BuiltinTemplate(
      key: 'sheets.gradebook',
      kind: DriveItemKind.spreadsheet,
      name: 'Gradebook',
      description: 'Scores per assignment with averages.',
      category: TemplateCategory.education,
      accent: '#ea580c',
      banner: true,
      sheets: [
        TemplateSheet(
          name: 'Grades',
          columnWidths: {0: 200},
          numberFormats: {4: '0.0'},
          rows: [
            ['Student', 'Assignment 1', 'Assignment 2', 'Exam', 'Average'],
            ['Student A', '85', '92', '78', '=AVERAGE(B2:D2)'],
            ['Student B', '72', '80', '88', '=AVERAGE(B3:D3)'],
            ['Student C', '95', '90', '93', '=AVERAGE(B4:D4)'],
            [
              'Class average',
              '=AVERAGE(B2:B4)',
              '=AVERAGE(C2:C4)',
              '=AVERAGE(D2:D4)',
              '=AVERAGE(E2:E4)',
            ],
          ],
          boldRows: {0, 4},
        ),
      ],
    ),
    BuiltinTemplate(
      key: 'sheets.weekly-schedule',
      kind: DriveItemKind.spreadsheet,
      name: 'Weekly schedule',
      description: 'Time slots for each day of the week.',
      category: TemplateCategory.personal,
      accent: '#db2777',
      banner: true,
      sheets: [
        TemplateSheet(
          name: 'Schedule',
          columnWidths: {0: 90},
          rows: [
            ['Time', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            ['08:00'],
            ['09:00'],
            ['10:00'],
            ['11:00'],
            ['12:00'],
            ['13:00'],
            ['14:00'],
            ['15:00'],
            ['16:00'],
            ['17:00'],
          ],
        ),
      ],
    ),
  ];
}
