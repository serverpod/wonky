# Slides 04 · Screens, Menus, Toolbar, Navigator, Panels and Dialogs

This spec defines every screen of Wonky Slides, the editor layout, the **slide navigator with
slide groups** (decision D11), the inspector, the speaker-notes pane, the grid and outline views,
the **complete menubar**, the toolbar, context menus, side panels, dialogs, the status bar, the
home screen, light/dark and narrow-width behavior. It is the **canonical registry of menu-bound
command ids**: behavior specs (03, 05–11) use the ids listed here, or update this file when they
need a different one.

Behavior of canvas interactions is [03](03-editor-canvas-and-objects.md); storage is
[02](02-data-model.md). Shared shell pieces (header structure, menu framework, palette, overlays,
settings split, Bugs & improvements (was Report a bug)) come from suite [03](../03-app-shell-and-navigation.md),
[02](../02-design-system.md), [04](../04-auth-and-accounts.md) and `specs/wonky_drive/`.

Owned folders: `wonky_slides/lib/config/**` (routes, `MenuSpec`, toolbar spec, panel registry,
context-menu specs), `wonky_slides/lib/features/{editor_screen,navigator,groups,inspector,notes,
grid_view,outline_view,menus,toolbar,dialogs,home}/`.

## 0. Conventions

- Shortcut columns: **macOS** with ⌘ ⌥ ⇧ ⌃ glyphs; **Win/Linux** with `Ctrl`, `Alt`, `Shift`.
  Browser-reserved chords are never bound (suite 08 §1.2): ⌘W ⌘T ⌘N ⌘L ⇧⌘R ⌥⌘I ⌘M (mac minimize)
  are avoided. "—" = no default shortcut.
- **Enabled** predicates: `view` = always; `edit` = role ≥ Editor and the deck is loaded;
  `comment` = role ≥ Commenter; `canDownload` = role ≥ Editor or the owner allows download/copy
  (suite 06 §1); `sel` = ≥ 1 element selected; `sel2`/`sel3` = ≥ 2/3 elements; `text` = text
  editing or a text-capable element selected; `slides` = ≥ 1 slide selected in the navigator;
  `group` = ≥ 1 group header selected; `img`, `table`, `line`, `code`, `chart` = selection of
  that kind; `masters` = master editing mode. Disabled items show the reason as a tooltip
  ("You have view access", "Select two or more objects").
- Every menu is generated from a declarative `MenuSpec` (suite 02 §4.3): the same tree feeds
  `WonkyMenubar`, the macOS `PlatformMenuBar`, command-palette menu paths and MCP
  `ui.get_menu_tree`.
- Dynamic labels: `{n}` = count from the selection ("Delete 3 slides"), `{group}` = group title.
- Ids of areas specified by other Slides specs (`slides.animate.*`, `slides.transition.*` — 06;
  `slides.code.*` — 07; `slides.chart.*` — 08; `slides.present.*`, `slides.print.*`,
  `slides.file.download` — 10; `slides.ai.*` — 11) are listed here as menu bindings; their
  arguments and behavior are defined there.

---

## 1. Screen inventory

| Route (D1, relative to `/slides/`) | Screen | Class | Notes |
|------------------------------------|--------|-------|-------|
| `/` and drive routes (`/recent`, `/f/:folder`, `/shared`, `/starred`, `/trash`, `/search`) | **Home** (Drive filtered to presentations, D2) | shell `DriveHomeScreen` with `SlidesAppConfig.homeScope` = `HomeScope.kind(presentation)` | §15 |
| `/templates` | Template gallery (presentation categories) | shell | §15 |
| `/p/:uuid` (`?slide=<slideId>&comment=<threadUuid>`) | **Deck editor** | `DeckEditorScreen` | §2 |
| `/p/:uuid` while downloading | "Downloading presentation…" (skeleton navigator + slide) until the deck's structure page arrived; a deck in the device cache opens at once | `DeckLoadingView` | 02 §9.1 |
| `/p/:uuid/present` (`?slide=&from=start`) | Presenting in this window (full screen, or presenter view; audience on other devices/browsers via the presentation session, 10 §5.2) | `PresentScreen` | [10](10-presenting-and-pdf.md) |
| `/p/:uuid/print` | Print / PDF preview with options | `SlidesPrintPreviewScreen` | [10](10-presenting-and-pdf.md) |
| `/p/:uuid/history` (`?version=`) | Version history (full-screen) | `SlidesVersionHistoryScreen` | [09 §4](09-collaboration-history.md) |
| `/settings` | **Wonky Work settings** (suite-level, D4) | shell | suite 04 |
| `/settings/app` | **Slides settings** (D4) | shell page + Slides sections | §13.16 |
| No access / not found / unavailable offline | Empty state in the editor route: "This presentation isn't available offline." with "It opens by itself when you're back online.", or the session's reason ("You don't have access to this presentation.", "You no longer have access to this presentation.") and *Back to Slides* | `DeckEditorScreen` (`slides.unavailable`) | suite 03 §4, 02 §9.1 |

`/p/:uuid/present` and `/p/:uuid/print` are editor child routes (the deck session stays mounted,
`WonkyAppConfig.editorRoutes`). Dev web port **8104** (`serverpod: flutter_apps: slides`, D1).

---

## 2. Editor layout

```
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│ [▶] Q3 Review ☆ 📁 ☁ Saved              (A)(B)(+2)  💬3  🐞  [▶ Present ▾]  [🔒 Share]  (me)  │ title row (48)
│ File Edit View Insert Format Slide Arrange Tools Extensions Help                             │ menubar (32)
│ ↶ ↷ 🖌 Fit▾ │ ＋Slide▾ │ ⬚ T ▢▾ ╱▾ 🖼▾ ⊞▾ </> 📊▾ ☆ │ ‹contextual: Inter▾ −40+ B I U A▾ ≡▾ …› │ 💬 ✨Animate │ toolbar (40)
├──────────────┬────────────────────────────────────────────────────────────┬────────────┬──┤
│ ▾ ● Intro (3)│                                                            │ Format     │  │
│  1 [thumb]   │                                                            │ Animate    │ r│
│  2 [thumb]   │                 CANVAS (03)                                │ Slide      │ a│
│  3 [thumb]   │          ┌───────────────────────────┐                     │ ────────── │ i│
│ ▸ ● Demo (6) │          │          slide            │                     │ Inspector  │ l│
│  10 [thumb]  │          └───────────────────────────┘                     │ (§7)       │  │
│  11 [thumb]  │                                                            │            │  │
│  + New slide │────────────────────────────────────────────────────────────│            │  │
│              │ Speaker notes (§8)                                          │            │  │
├──────────────┴────────────────────────────────────────────────────────────┴────────────┴──┤
│ Slide 2 of 24 · Intro · 1 skipped                              ▤ ▦ ≡    − Fit +            │ status bar (24)
└──────────────────────────────────────────────────────────────────────────────────────────────┘
   navigator (220)                                                 inspector (300)  side panel
                                                                                    host + rail
```

Regions (left → right): **navigator** (§5), **canvas** with the **notes pane** below it (§8),
**inspector** (§7), the shell **side panel host** with its icon rail (suite 02 §4.5: Comments,
Assistant, Layers, Themes, Accessibility, History). Region focus cycles with F6
(`shell.focus.nextRegion`).

View modes replace the navigator + canvas + notes area: **Normal**, **Grid** (§9), **Outline**
(§10), **Masters** (master/layout editing, [05 §8](05-themes-layouts-masters.md)) —
`slides.view.setMode {mode}`; the status bar has the three view buttons.

Viewer/commenter mode: toolbar reduced to Zoom, Comment (commenters) and the **Present** button;
a `ShadBadge` "View only" / "Comment only" with *Request edit access*; inspector hidden (toggle
still available, read-only); navigator drag disabled (collapse allowed).

Folder layout:

```
lib/
  config/
    routes.dart                         # /p/:uuid, present, print, history
    menus/slides_menu_spec.dart         # MenuSpec tree (§4)
    menus/context_menu_specs.dart       # canvas/element/text/navigator/group/table menus (§11)
    toolbar/slides_toolbar_spec.dart    # ToolbarSpec (§6)
    panels/slides_panels.dart           # SidePanelSpec registry (§12)
  features/
    editor_screen/                      # DeckEditorScreen, header composition, view modes
    navigator/  groups/                 # §5
    inspector/                          # §7 (section bodies live in their feature folders)
    notes/  grid_view/  outline_view/   # §8–10
    menus/  toolbar/  dialogs/  home/   # §4, §6, §13, §15
```

---

## 3. Header (title row)

Follows suite 03 §3.1 with Slides additions:

| Item | Behavior |
|------|----------|
| App icon | Slides product icon (`WonkyProduct.slides`) → Home |
| `DocumentTitleField` | Rename = `shell.drive.rename` (shell stack step) |
| Star, Move, `SyncStatusIndicator` | Shell. *Saved* means every change is acknowledged by the server; *Saving* while this tab's outbox holds changes; *Offline — changes saved on this device* without a connection ([17](../17-revlog-sync.md) part 6 §9) |
| `PresenceAvatarStack` | Avatars show "Editing slide 4" / "Presenting" / "Viewing"; ⋮ › *Follow* (09 §1.5) |
| Comments button | `shell.comments.togglePanel` (badge = open threads) |
| **Bugs & improvements** (M12) | Icon button (Lucide `messageSquarePlus`, tooltip "Bugs & improvements") → `shell.board.report` (replaced *Report a bug*, D5) |
| **Present** split button (primary, before Share) | Main: `slides.present.fromCurrent` (⌘Enter / Ctrl+Enter). Chevron menu: *Present from beginning* (`slides.present.fromStart`, ⇧⌘Enter), *Presenter view* (`slides.present.presenterView`, ⌥⌘Enter / Ctrl+Alt+Enter; in this window, 10 §5.2), *Open on another device…* (`slides.present.openOnAnotherDevice`), *Rehearse* (`slides.present.rehearse`, P1), *Use phone as remote* (`slides.present.remote`, P1), separator, *Presenting settings…* (`shell.settings.openApp {section: presenting}`). While someone presents, the button shows a live dot and *Follow Anna's presentation* (09 §1.6). |
| **Share** | Shell |
| Account avatar | Shell (incl. *Slides settings*, *Wonky Work settings*, D4) |

The Present button needs an app slot in the shell title row
(`EditorScaffold.titleActions`, suite addition §17).

---

## 4. Menubar

### 4.1 File

| Item | Command id | macOS | Win/Linux | Enabled | Spec |
|------|-----------|-------|-----------|---------|------|
| New ▸ Presentation | `shell.file.new {kind: presentation}` | — | — | view | 02 §9.3 |
| New ▸ Document / Spreadsheet | `shell.file.new {kind: document\|spreadsheet}` | — | — | view | shell |
| New ▸ From template… | `shell.file.newFromTemplate` | — | — | view | §15 |
| Open… | `shell.nav.quickSwitcher` | ⌘O | Ctrl+O | view | shell |
| Import slides… | `slides.file.importSlides` | — | — | edit | §13.9 (P1) |
| Make a copy… | `shell.drive.copy` | — | — | canDownload | 02 §9.3 |
| — | | | | | |
| Share ▸ Share with others / Copy link | `shell.sharing.open` / `shell.sharing.copyLink` | — | — | view | shell |
| Download ▸ PDF document (.pdf) | `slides.file.download {format: pdf}` → print/PDF preview | — | — | canDownload | 10 |
| Download ▸ PNG image (current slide)… | `slides.file.download {format: png}` | — | — | canDownload | 10 §13 (P1; built, SL-33: opens the PNG dialog) |
| Download ▸ PNG images (all slides, .zip)… | `slides.file.download {format: pngZip}` | — | — | canDownload | 10 §13 (P2; built, SL-33: the PNG dialog with all slides) |
| Download ▸ Outline as Markdown (.md) | `slides.file.download {format: markdown}` | — | — | canDownload | §10 (P2) |
| — | | | | | |
| Rename | `shell.drive.rename` | — | — | edit | shell |
| Move… | `shell.drive.move` | — | — | edit | shell |
| Add shortcut to Drive | `shell.drive.addShortcut` | — | — | view | shell |
| Move to trash | `shell.drive.trash` | — | — | owner/editor | shell |
| — | | | | | |
| Version history ▸ Name current version | `slides.history.nameCurrentVersion` | — | — | edit | 09 §4 |
| Version history ▸ See version history | `slides.history.open` | ⌥⇧⌘H | Ctrl+Alt+Shift+H | edit | 09 §4 |
| Make available offline ✓ | `shell.drive.togglePinnedOffline` | — | — | view | suite 12 |
| Details | `shell.file.details` | — | — | view | shell |
| Language ▸ *languages* | `slides.file.setLanguage {language}` | — | — | edit | 03 §14 |
| Page setup… (slide size) | `slides.file.pageSetup` | — | — | edit | §13.1, 05 §7 |
| — | | | | | |
| Print | `slides.print.open` | ⌘P | Ctrl+P | canDownload | 10 |

No PPTX/Keynote items (non-goal).

### 4.2 Edit

| Item | Command id | macOS | Win/Linux | Enabled | Spec |
|------|-----------|-------|-----------|---------|------|
| Undo *label* / Redo *label* | `shell.edit.undo` / `shell.edit.redo` | ⌘Z / ⇧⌘Z | Ctrl+Z / Ctrl+Y | stack | suite 08 |
| Undo history… | `shell.edit.undoHistory` | — | — | stack | suite 08 §3.5 |
| — | | | | | |
| Cut / Copy / Paste | `shell.edit.cut` / `copy` / `paste` | ⌘X / ⌘C / ⌘V | Ctrl+X / C / V | edit (copy: canDownload) | 03 §12 |
| Paste without formatting | `shell.edit.pasteWithoutFormatting` | ⇧⌘V | Ctrl+Shift+V | edit | 03 §12.5 |
| Paste special ▸ Keep source formatting / Use destination theme / Paste chart unlinked | `slides.edit.pasteSpecial {mode: keepSource\|useDestination\|unlinked}` | — | — | edit | 03 §12.3 |
| Duplicate | `slides.edit.duplicate` | ⌘D | Ctrl+D | edit, sel or slides | 03 §11, §5.7 |
| Delete | `slides.edit.delete` | ⌫ | Delete | edit | 03 §11 |
| Select all | `shell.edit.selectAll` | ⌘A | Ctrl+A | view | 03 §3.3 |
| Select none | `slides.select.escape` | Esc | Esc | view | 03 |
| — | | | | | |
| Find and replace | `slides.find.openReplace` | ⇧⌘H | Ctrl+H | view (replace: edit) | 03 §13 |
| Copy style / Paste style | `slides.format.copyStyle` / `pasteStyle` | ⌥⌘C / ⌥⌘V | Ctrl+Alt+C / V | sel | 03 §9 |

`⌘F` (`slides.find.open`) opens the find bar (shortcuts dialog only, as Sheets).

### 4.3 View

| Item | Command id | macOS | Win/Linux | Enabled | Spec |
|------|-----------|-------|-----------|---------|------|
| Present ▸ From current slide / From beginning / Presenter view / Rehearse | `slides.present.fromCurrent` / `fromStart` / `presenterView` / `rehearse` | ⌘Enter / ⇧⌘Enter / ⌥⌘Enter | Ctrl+Enter / Ctrl+Shift+Enter / Ctrl+Alt+Enter | view | 10 |
| — | | | | | |
| Normal / Grid / Outline (radio) | `slides.view.setMode {mode: normal\|grid\|outline}` | — | — | view | §9, §10 |
| Edit masters and layouts | `slides.view.setMode {mode: masters}` | — | — | edit | 05 §8 |
| — | | | | | |
| Show ▸ Navigator ✓ | `slides.view.toggleNavigator` | — | — | view | §5 |
| Show ▸ Inspector ✓ | `slides.view.toggleInspector` | ⌥⇧⌘I | Ctrl+Alt+Shift+I | view | §7 |
| Show ▸ Speaker notes ✓ | `slides.view.toggleNotes` | ⌥⇧⌘N | Ctrl+Alt+Shift+N | view | §8 |
| Show ▸ Rulers ✓ | `slides.view.toggleRulers` | ⌥⇧⌘R | Ctrl+Alt+Shift+R | view | 03 §5.6 (P1) |
| Show ▸ Guides ✓ | `slides.view.toggleGuides` | — | — | view | 03 §5.6 |
| Show ▸ Build order ✓ | `slides.animate.toggleOrderOverlay` | — | — | view | 06 §5.5 |
| Show ▸ Magic Move matches ✓ | `slides.magicMove.toggleMatches` | — | — | view | 06 §8 |
| Show ▸ Comments on canvas ✓ | `slides.view.toggleCommentPins` | — | — | view | 09 §3.3 |
| Show ▸ Collaborator cursors ✓ | `slides.view.toggleRemoteCursors` | — | — | view | 09 §2 |
| Snap ▸ Smart guides ✓ / Snap to objects ✓ / Snap to guides ✓ / Snap to grid ✓ (P2) | `slides.view.toggleSmartGuides` / `toggleSnapObjects` / `toggleSnapGuides` / `toggleSnapGrid` | — | — | view | 03 §5.3 |
| Guides ▸ Add vertical guide / Add horizontal guide / Clear guides | `slides.guides.add {axis}` / `slides.guides.clear` | — | — | edit | 03 §5.6 |
| — | | | | | |
| Zoom ▸ Fit / 50 % / 100 % / 150 % / 200 % / Zoom in / Zoom out / Zoom to selection | `slides.view.zoomFit` / `slides.view.zoom {percent}` / `zoomIn` / `zoomOut` / `zoomToSelection` | ⌥⌘0, ⌥⌘=, ⌥⌘− | Ctrl+Alt+0, =, − | view | 03 §2.2 |
| Panels ▸ Comments / Layers / Themes / Accessibility / Assistant / Animate | `shell.panels.open {panelId}` (Animate: `slides.panel.animate`) | — | — | view | §12 |
| App theme ▸ System / Light / Dark | `shell.appearance.setTheme {mode}` | — | — | view | suite 02 |
| Mode ▸ Editing / Viewing | `shell.view.setMode {mode}` | — | — | edit for Editing | shell |

### 4.4 Insert

| Item | Command id | macOS | Win/Linux | Enabled | Spec |
|------|-----------|-------|-----------|---------|------|
| New slide | `slides.slide.new` | ⌃M | Ctrl+M | edit | §5.7 |
| New slide with layout ▸ *layouts* | `slides.slide.new {layoutId}` | — | — | edit | 05 §4 |
| Magic Move slide | `slides.slide.duplicateForMagicMove` | ⌥⇧⌘D | Ctrl+Alt+Shift+D | edit | 06 §8 |
| — | | | | | |
| Text box | `slides.insert.textBox` | T (canvas) | T | edit | 03 §6.1 |
| Image ▸ Upload from computer / From Wonky Drive / By URL / From clipboard | `slides.insert.image {source: upload\|drive\|url\|clipboard}` | — | — | edit | 03 §6.5 |
| Shape ▸ *categories ▸ shapes* (grid menu with icons) | `slides.insert.shape {geometry}` | S (last shape) | S | edit | 03 §6.3 |
| Line ▸ Line / Arrow / Double arrow / Elbow connector / Curved connector | `slides.insert.line {routing, arrows}` | L | L | edit | 03 §6.4 |
| Table ▸ *size picker* | `slides.insert.table {rows, cols}` | — | — | edit | 03 §6.6 |
| Code block ▸ *recent languages*, Plain text, All languages… | `slides.insert.code {language?}` | — | — | edit | 07 |
| Chart ▸ From Wonky Sheets… | `slides.insert.chartFromSheets` | — | — | edit | 08 |
| Chart ▸ Column / Bar / Line / Pie / Area / Scatter (native, P1) | `slides.insert.chart {type}` | — | — | edit | 08 |
| Icon… | `slides.insert.icon` | — | — | edit | §13.6 |
| Emoji… (P1) | `slides.insert.emoji` | — | — | edit | 03 §6.7 |
| Special characters… (P1) | `slides.insert.specialCharacter` | — | — | edit (text) | 03 |
| — | | | | | |
| Link | `slides.insert.link` | ⌘K | Ctrl+K | edit, text or sel | 03 §6.1, §6.9 |
| Comment | `shell.comments.create` | ⌥⌘M | Ctrl+Alt+M | comment | 09 §3 |
| Animation… | `slides.panel.animate {tab: build}` | — | — | edit, sel | 06 §5 |
| — | | | | | |
| Slide numbers… | `slides.deck.openNumbering` | — | — | edit | §13.3 |
| Placeholder ▸ *types* (master mode) | `slides.layout.insertPlaceholder {type}` | — | — | edit, masters | 05 §8 |

### 4.5 Format

| Item | Command id | macOS | Win/Linux | Enabled | Spec |
|------|-----------|-------|-----------|---------|------|
| Text ▸ Bold / Italic / Underline / Strikethrough | `slides.format.bold` / `italic` / `underline` / `strikethrough` | ⌘B / ⌘I / ⌘U / ⇧⌘X | Ctrl+B / I / U / Alt+Shift+5 | edit, text | 03 §6.1 |
| Text ▸ Superscript / Subscript | `slides.format.script {value}` | ⌘. / ⌘, | Ctrl+. / Ctrl+, | edit, text | |
| Text ▸ Size ▸ Increase / Decrease | `slides.format.increaseFontSize` / `decreaseFontSize` | ⇧⌘. / ⇧⌘, | Ctrl+Shift+. / , | edit, text | |
| Text ▸ Capitalization ▸ UPPERCASE / Small caps / Title Case / None | `slides.format.caps {value}` | — | — | edit, text | |
| Text style ▸ Title / Subtitle / Heading / Body / Body 2 / Caption / Quote / Attribution / Big number / Label | `slides.format.textStyle {key}` | ⌥⌘1…9 | Ctrl+Alt+1…9 | edit, text | 05 §2.5 |
| Align & indent ▸ Left / Center / Right / Justify | `slides.format.align {value}` | ⇧⌘L / E / R / J | Ctrl+Shift+L / E / R / J | edit, text | |
| Align & indent ▸ Top / Middle / Bottom | `slides.format.anchor {value}` | — | — | edit, text | |
| Align & indent ▸ Increase indent / Decrease indent | `slides.format.indent` / `outdent` | ⌘] / ⌘[ | Ctrl+] / Ctrl+[ | edit, text | |
| Line & paragraph spacing ▸ Single / 1.15 / 1.5 / Double / Custom… / Add space before / after | `slides.format.lineHeight {value}` / `slides.format.paragraphSpacing` | — | — | edit, text | |
| Bullets & numbering ▸ Bulleted / Numbered / Checklist / *list styles* / Restart numbering | `slides.format.list {type}` / `listStyle` / `listStart` | ⇧⌘8 / ⇧⌘7 / ⇧⌘9 | Ctrl+Shift+8 / 7 / 9 | edit, text | |
| Text fitting ▸ Do not autofit / Shrink text on overflow / Resize shape to fit text | `slides.format.autofit {mode}` | — | — | edit, text | 02 §5.1 |
| — | | | | | |
| Fill ▸ *color picker* / Gradient… / Image… / None | `slides.format.fill {fill}` | — | — | edit, sel | 02 §5.2 |
| Border ▸ Color / Weight / Dash / None | `slides.format.stroke {…}` | — | — | edit, sel | 02 §5.3 |
| Effects ▸ Shadow / Glow (P1) / Blur (P1) / None | `slides.format.effects {…}` | — | — | edit, sel | 02 §5.4 |
| Opacity… | `slides.format.opacity {value}` | — | — | edit, sel | |
| Image ▸ Crop / Mask with shape ▸ / Replace image ▸ / Adjustments… / Reset image / Download original | `slides.image.crop` / `mask` / `replace` / `adjust` / `reset` / `downloadOriginal` | — | — | edit, img | 03 §6.5 |
| Table ▸ Insert row above / below, column left / right, Delete row / column, Merge / Unmerge cells, Distribute rows / columns, Table options… | `slides.table.*` (03 §19) | — | — | edit, table | 03 §6.6 |
| Shape ▸ Change shape ▸ / Quick styles ▸ | `slides.shape.change` / `applyQuickStyle` | — | — | edit, shape | 03 §6.3 |
| Line ▸ Start arrow ▸ / End arrow ▸ / Routing ▸ | `slides.line.setArrow` / `setRouting` | — | — | edit, line | 03 §6.4 |
| Code ▸ Language ▸ / Line numbers ✓ / Highlight steps… / States… | `slides.code.*` | — | — | edit, code | 07 |
| Chart ▸ Update / Update automatically ✓ / Open source spreadsheet / Unlink | `slides.chart.update` / `setAutoUpdate` / `openSource` / `unlink` | — | — | edit, chart | 08 |
| — | | | | | |
| Alt text… | `slides.element.editAltText` | ⌥⌘Y | Ctrl+Alt+Y | edit, sel | 03 §17.1 |
| Paint format | `slides.format.paintFormat` | — | — | edit | 03 §9 |
| Clear formatting | `slides.format.clear` | ⌘\ | Ctrl+\ | edit, text | 03 §6.1 |
| Format options… (opens Inspector › Format) | `slides.inspector.open {tab: format}` | — | — | view | §7 |

### 4.6 Slide

| Item | Command id | macOS | Win/Linux | Enabled | Spec |
|------|-----------|-------|-----------|---------|------|
| New slide | `slides.slide.new` | ⌃M | Ctrl+M | edit | §5.7 |
| Duplicate slide | `slides.slide.duplicate` | ⌘D (navigator) | Ctrl+D | edit, slides | §5.7 |
| Delete slide | `slides.slide.delete` | ⌫ (navigator) | Delete | edit, slides | §5.7 |
| Skip slide / Unskip slide | `slides.slide.toggleSkip` | — | — | edit, slides | §5.7 |
| Move slide ▸ To beginning / Up / Down / To end | `slides.slide.move {to: start\|up\|down\|end}` | ⇧⌘↑ / ⌘↑ / ⌘↓ / ⇧⌘↓ (navigator) | Ctrl+Shift+↑ / Ctrl+↑ / Ctrl+↓ / Ctrl+Shift+↓ | edit, slides | §5.9 |
| — | | | | | |
| Group ▸ Group slides | `slides.group.create` | ⌘G (navigator) | Ctrl+G | edit, slides | §5.6 |
| Group ▸ Ungroup | `slides.group.ungroup` | ⇧⌘G (navigator) | Ctrl+Shift+G | edit, group | §5.7 |
| Group ▸ Add to group ▸ *groups* | `slides.group.addSlides {groupId}` | — | — | edit, slides | §5.6 (P1) |
| Group ▸ Remove from group | `slides.group.removeSlides` | — | — | edit, slides in a group | §5.6 |
| Group ▸ Rename group | `slides.group.startRename` | F2 (header) | F2 | edit, group | §5.4 |
| Group ▸ Color ▸ *palette* | `slides.group.setColor {color}` | — | — | edit, group | §5.4 |
| Group ▸ Skip group ✓ | `slides.group.toggleSkip` | — | — | edit, group | §5.7 |
| Group ▸ Collapse / Expand / Collapse all / Expand all | `slides.group.collapse` / `expand` / `collapseAll` / `expandAll` | ← / → (header), ⌥⌘[ / ⌥⌘] | same, Ctrl+Alt+[ / ] | view | §5.4 |
| — | | | | | |
| Apply layout ▸ *layout thumbnails* | `slides.slide.applyLayout {layoutId}` | — | — | edit, slides | 05 §4 |
| Reset slide to layout | `slides.slide.resetToLayout` | — | — | edit, slides | 05 §5.4 |
| Change background… | `slides.inspector.open {tab: slide}` | — | — | edit | §7.4 |
| Transition… | `slides.panel.animate {tab: transition}` | — | — | edit | 06 §5.1 |
| Preview animations | `slides.animate.preview` | ⌥⇧⌘P | Ctrl+Alt+Shift+P | view | 06 §6 |
| Remove all animations | `slides.animate.removeAll` | — | — | edit | 06 |
| — | | | | | |
| Change theme… | `shell.panels.open {panelId: slides.panel.themes}` | — | — | edit | 05 §9 |
| Edit theme… | `slides.theme.edit` | — | — | edit | 05 §8.4 |
| Edit masters and layouts | `slides.view.setMode {mode: masters}` | — | — | edit | 05 §8 |
| — | | | | | |
| Go to slide… | `slides.nav.goToSlide` | — (palette: "Go to slide…") | — | view | §13.10 |
| Previous slide / Next slide | `slides.nav.previousSlide` / `nextSlide` | PgUp / PgDn | PgUp / PgDn | view | §5.9 |

### 4.7 Arrange

| Item | Command id | macOS | Win/Linux | Enabled | Spec |
|------|-----------|-------|-----------|---------|------|
| Order ▸ Bring to front / Bring forward / Send backward / Send to back | `slides.arrange.order {op}` | ⌥⇧⌘↑ / ⇧⌘↑ / ⇧⌘↓ / ⌥⇧⌘↓ | Ctrl+Alt+Shift+↑ / Ctrl+Shift+↑ / Ctrl+Shift+↓ / Ctrl+Alt+Shift+↓ | edit, sel | 03 §8.3 |
| Align ▸ Left / Center / Right / Top / Middle / Bottom | `slides.arrange.align {edge}` | ⌥⌘← / — / ⌥⌘→ / ⌥⌘↑ / — / ⌥⌘↓ | Ctrl+Alt+arrows | edit, sel | 03 §5.5 |
| Distribute ▸ Horizontally / Vertically | `slides.arrange.distribute {axis}` | — | — | edit, sel3 | 03 §5.5 |
| Center on slide ▸ Horizontally / Vertically / Both | `slides.arrange.centerOnSlide {axis}` | — | — | edit, sel | |
| Match size ▸ Width / Height / Both (P1) | `slides.arrange.matchSize {dimension}` | — | — | edit, sel2 | |
| Rotate ▸ Rotate 90° clockwise / counter-clockwise / Flip horizontally / Flip vertically | `slides.arrange.rotate {degrees}` / `slides.arrange.flip {axis}` | — | — | edit, sel | 03 §4.3 |
| — | | | | | |
| Group | `slides.arrange.group` | ⌥⌘G (and ⌘G on canvas) | Ctrl+Alt+G (and Ctrl+G) | edit, sel2 | 03 §7 |
| Ungroup | `slides.arrange.ungroup` | ⌥⇧⌘G (and ⇧⌘G on canvas) | Ctrl+Alt+Shift+G | edit, element group | 03 §7 |
| — | | | | | |
| Lock / Unlock | `slides.element.toggleLock` | ⌥⇧⌘L | Ctrl+Alt+Shift+L | edit, sel | 03 §8.2 |
| Unlock all on slide | `slides.element.unlockAll` | — | — | edit | |
| Hide / Show | `slides.element.hide` / `show` | — | — | edit, sel | |
| — | | | | | |
| Animate… | `slides.panel.animate {tab: build}` | — | — | edit | 06 §5 |
| Size and position… | `slides.inspector.open {tab: format, section: arrange}` | — | — | sel | §7.2 |
| Layers | `shell.panels.open {panelId: slides.panel.layers}` | — | — | view | 03 §8.1 (P1) |

### 4.8 Tools

| Item | Command id | macOS | Win/Linux | Enabled | Spec |
|------|-----------|-------|-----------|---------|------|
| Assistant | `shell.ai.togglePanel` | ⌘J | Ctrl+J | AI enabled | suite 10, 11 |
| Spelling ▸ Check spelling / Underline errors ✓ / Personal dictionary | `slides.spelling.check` / `toggleUnderline` / `shell.settings.open {section: dictionary}` | — | — | edit / view | 03 §14 (P1) |
| Accessibility check | `slides.tools.accessibilityCheck` | — | — | view | 03 §17.4 (P1) |
| Rehearse presentation | `slides.present.rehearse` | — | — | view | 10 (P1) |
| Notification settings | `slides.notifications.openSettings` | — | — | view | suite 07 |
| Accessibility settings | `shell.settings.accessibility` | — | — | view | suite |
| Keyboard shortcuts | `shell.help.shortcuts` | ⌘/ | Ctrl+/ | view | §13.15 |
| Slides settings… | `shell.settings.openApp` | ⌘, (desktop) | — | view | §13.16 |

### 4.9 Extensions

| Item | Command id | Enabled | Spec |
|------|-----------|---------|------|
| AI ▸ Generate presentation… | `slides.ai.generateDeck` | edit, AI | 11 |
| AI ▸ Rewrite text ▸ Shorter / Longer / Clearer / More formal / Fix grammar / Custom… | `slides.ai.rewrite {mode}` | edit, text, AI | 11 |
| AI ▸ Suggest layouts for this slide | `slides.ai.suggestLayouts` | edit, AI | 11 |
| AI ▸ Write speaker notes | `slides.ai.speakerNotes` | edit, AI | 11 |
| AI ▸ Generate alt text | `slides.ai.altText` | edit, sel, AI | 11 |
| AI ▸ Make a code walkthrough… | `slides.ai.codeWalkthrough` | edit, code, AI | 11 |
| MCP ▸ Copy MCP connection info | `shell.mcp.copyConnectionInfo` | view | suite 09 |

### 4.10 Help

| Item | Command id | macOS | Win/Linux |
|------|-----------|-------|-----------|
| Keyboard shortcuts | `shell.help.shortcuts` | ⌘/ | Ctrl+/ |
| — | | | |
| Bugs & improvements… (M12) | `shell.board.report` (replaces *Report a bug*; `shell.help.reportBug` and `shell.help.feedback` stay as hidden aliases, suite 03 §3.2) | — | — |
| Browse Bugs & improvements (M12) | `shell.board.open` | — | — |
| What's new | `shell.help.whatsNew` | — | — |
| About | `shell.help.about` | — | — |

### 4.11 Menu behavior

As Sheets 04 §3.10: Alt+letter (Win/Linux) / ⌃⌥letter (macOS) opens a menu — File F, Edit E,
View V, Insert I, Format O, Slide S, Arrange A, Tools T, Extensions N, Help H; one menu open at a
time; reasons on disabled items; ✓ and ● for checked/radio; macOS native menus from the same
spec.


---

## 5. Slide navigator and slide groups (D11)

`SlideNavigator` (`features/navigator/`) and group behavior (`features/groups/`). The navigator is
a virtualized vertical list (built on `WonkyTreeView` primitives, suite 02 §4.6: lazy, keyboard,
drag-and-drop with indicators) of **rows**: group headers and slide rows in presentation order
(02 §3.4).

### 5.1 Layout

- Width 220 px default, resizable 160–400 px by dragging its right edge (device pref
  `slides.navigator.width`); collapsible (`slides.view.toggleNavigator`; below 768 px it becomes
  a drawer, §16). Header: none (the list starts at the top); footer: **+ New slide** button
  (`slides.slide.new`) with a layout chevron.
- Thumbnail width = navigator width − 56 px; aspect = deck aspect; rendered by the shared
  `SlideStage` thumbnail mode (03 §2.4) and cached by slide revision.

### 5.2 Slide rows

```
  ▌ 12 ┌──────────────┐ 💬2
  ▌    │  thumbnail   │ ⚡      ← builds indicator (P1), transition glyph (P1)
  ▌ ⊘  └──────────────┘ (A)(B) ← presence dots (09)
```

| Element | Behavior |
|---------|----------|
| Group color bar | 4 px bar at the left edge in the group's color for every slide of a group (none for top-level slides) |
| Indent | Slides inside a group are indented 12 px |
| Number | Slide number in presentation order (skipped slides show the number struck through and dimmed) |
| Thumbnail | Rounded 4 px, 1 px `border`; **current** slide: 2 px `primary` ring; **selected** (not current): `selection` tint ring |
| Skipped | Thumbnail at 40 % opacity + `eye-off` badge (also when skipped through its group) |
| Badges (right column) | Open comment count (click → comments filtered to the slide), presence dots (max 3 + "+N"), builds ⚡ (P1, click → Animate panel), transition glyph (P1) |
| Hover | `⋮` button (slide context menu §11.5) |

### 5.3 Group header rows

```
 ▾ ● Intro                       3   ⋮
 ▸ ● Demo  (collapsed)  ⊘        6   ⋮   ← skipped group shows eye-off; collapsed shows stack preview
     ┌────┐┐┐
     └────┘┘┘
```

| Element | Behavior |
|---------|----------|
| Chevron | Click toggles collapse (`slides.group.toggleCollapsed {groupId}`); Alt+click collapses/expands **all** groups |
| Color dot | Group color (§5.4); click opens the color menu |
| Title | Group title (ellipsized); double-click or F2 → inline rename field (§5.4) |
| Count | Number of slides in the group (skipped included) |
| Skip badge | `eye-off` when the group is skipped |
| Collapsed preview | When collapsed: a small stacked preview of the group's first slide (64 px wide, 2 offset shadows) under the title, so the group stays recognizable |
| Presence | Dots for collaborators on any slide of the group (collapsed only) |
| `⋮` | Group context menu (§11.6) |
| Selected | Header row `selection` background; its slides (visible or collapsed) count as selected |

Collapsed/expanded state is **per user and device** (`LocalViewState.collapsedGroups`, 02 §7),
not synced, not undoable; new groups start expanded; a group containing the current slide
expands when the current slide is set from elsewhere (search, comments, presence jump,
`?slide=`).

### 5.4 Rename, color, collapse

- **Rename**: inline `ShadInput` replaces the title (select-all on focus); Enter/blur commits
  `slides.group.rename {groupId, title}` (1 step; 1–100 chars, empty → reverts with shake); Esc
  cancels.
- **Color**: palette of 9 named colors + *None* (rendered via tokens `groupColor.<name>`, light
  and dark variants): gray `#71717A/#A1A1AA`, red `#DC2626/#F87171`, orange `#EA580C/#FB923C`,
  amber `#D97706/#FBBF24`, green `#16A34A/#4ADE80`, teal `#0D9488/#2DD4BF`, blue
  `#2563EB/#60A5FA`, violet `#7C3AED/#A78BFA`, pink `#DB2777/#F472B6`. New groups take the next
  color in this cycle not used by the previous group. `slides.group.setColor {groupId, color?}`
  (1 step). Group colors appear in the navigator, grid view, outline view, presenter slide picker
  (10) and as PDF bookmark labels (no color).
- **Collapse/expand**: chevron, ← / → on a focused header, `slides.group.collapse/expand
  {groupIds?}` (default: selected or the current slide's group), `collapseAll`/`expandAll`
  (⌥⌘[ / ⌥⌘]). Collapsing the group containing the current slide keeps the current slide
  (shown highlighted header instead).

### 5.5 Selection semantics

| Gesture | Result |
|---------|--------|
| Click slide | Select it alone; it becomes the **current slide** (canvas shows it) |
| Shift+click slide | Range from the anchor to it **in visible order**; a collapsed group inside the range is included **as a whole group** |
| Mod+click slide | Toggle it (current slide unchanged unless it was deselected → the last selected) |
| Click group header | Select the **group** (header highlighted); all its slides count as selected; current slide → the group's first slide (if the current slide is not already in the group) |
| Shift+click header | Range including the group |
| Mod+click header | Toggle the group |
| Click empty area below rows | Clears to the current slide only |
| Arrow keys | Move the current slide/header focus (§5.9) |

The **navigator selection** has two parts: selected group ids and selected slide ids (slides of
selected groups implied). Commands interpret it:

| Command | Acts on |
|---------|---------|
| Delete | Selected groups → *Delete group* dialog (§5.7); selected slides → delete |
| Duplicate, Copy, Cut | Groups as groups (with their slides) + loose slides |
| Move (drag, ⌘↑/↓) | Groups and slides as units in visible order |
| Skip | Groups → group skip; slides → slide skip |
| Group slides (⌘G) | Selected slides (and slides of selected groups) |

Selection is view state (not undoable; restored by undo/redo).

### 5.6 Creating groups and changing membership

- **Group slides** (`slides.group.create {slideIds?, title?, color?}`, ⌘G / Ctrl+G in the
  navigator scope; also Slide › Group ▸ Group slides and the slide context menu): requires ≥ 1
  selected slide. The new group is created at the **top-level position of the first selected
  slide's item**: if that slide is top-level, the group takes its place; if it is inside group G,
  the new group is placed **directly after G**. All selected slides move into the new group in
  their current presentation order (non-contiguous slides are gathered). Title: "Group {n}"
  (lowest free number); the inline rename field opens immediately (typing renames; Esc keeps the
  default). One undo step "Group slides".
- Disabled when the selection is exactly all slides of one existing group (reason "These slides
  are already a group").
- v1 has no nesting: grouping slides that are inside other groups moves them out of those groups
  (empty groups remain, §5.11).
- **Add to group ▸** (P1, `slides.group.addSlides {groupId, slideIds?}`): appends the selected
  slides at the end of the target group.
- **Remove from group** (`slides.group.removeSlides {slideIds?}`): moves the selected slides out
  to the top level **right after their group** (keeping order).
- Drag & drop also changes membership (§5.10).

### 5.7 Slide and group operations

| Operation | Command | Behavior | Undo |
|-----------|---------|----------|------|
| New slide | `slides.slide.new {layoutId?, after?}` | Inserted after the current slide **in the same group** (or at the insertion point, §5.8); layout = the current slide's layout if it is `titleBody`-like, else `titleBody` (Google behavior: "same as current" for content layouts; title layouts → `titleBody`); new slide becomes current with the title placeholder selected | 1 |
| Duplicate slides | `slides.slide.duplicate {slideIds?}` | Copies right after the last selected slide, in the same group; elements keep `matchKey` (Magic Move ready) | 1 |
| Duplicate group | `slides.group.duplicate {groupIds?}` | Copy placed right after the group: title "{title} (copy)", same color/skip, slides duplicated | 1 |
| Delete slides | `slides.slide.delete {slideIds?}` | Deletes; current slide → next (or previous); no confirm (undoable); deleting the last slide leaves an empty deck (§5.11) | 1 |
| Delete group | `slides.group.delete {groupIds?, withSlides}` | Dialog (§13.4): **Delete group and {n} slides** (destructive) / **Ungroup only** / Cancel; empty groups delete without a dialog | 1 |
| Ungroup | `slides.group.ungroup {groupIds?}` | Slides become top-level at the group's position (top-level keys `nBetween` the group's neighbors), group row deleted | 1 |
| Skip / unskip | `slides.slide.toggleSkip {slideIds?}`, `slides.group.toggleSkip {groupIds?}` | Slide `skipped` / group `skipped` (effective skip = either, 02 §3.4); a slide inside a skipped group shows "Skipped with group" and its own toggle is disabled with that reason | 1 |
| Move | `slides.slide.move {slideIds?, to}`, `slides.group.move {groupIds?, to}`, drag (§5.10) | `to: start\|up\|down\|end\|{beforeId}\|{afterId}\|{groupId, index}`; ⌘↑/⌘↓ move one visible position (moving a slide past a group boundary **enters/leaves** the group: ⌘↓ on the last slide of a group moves it out to directly after the group; ⌘↓ on a top-level slide directly above an expanded group moves it to the group's first position; a collapsed group is jumped over as one item) | 1 |
| Rename group | `slides.group.rename {groupId, title}` | §5.4 | 1 |
| Apply layout | `slides.slide.applyLayout {slideIds?, layoutId}` | 05 §5.4 | 1 |

### 5.8 Clipboard and the insertion point

- Copy/cut/paste in the navigator use the `application/x-wonky-slides` payload with `kind: slides`
  or `groups` (03 §12.2). Copying a group header copies the group (title, color, skip) and its
  slides; mixed selections copy groups and loose slides in order.
- **Insertion point**: clicking the gap between two rows shows a horizontal insertion caret
  (2 px `primary`, indented inside a group when the gap is inside an expanded group); paste and
  *New slide* insert there.
- **Paste position** without an insertion point: after the last selected row. Pasting **groups**
  while the anchor is inside a group places them **after that group** (v1 has no nesting).
  Pasted groups arrive **expanded**, keep title/color/skip, and keep their slides' builds, code
  states, linked charts and images (re-homed across decks, 03 §12.3). Paste options chip:
  *Keep source formatting* / *Use destination theme* (03 §12.3).
- Cross-deck paste works between any two decks the user can read (source) and edit (target),
  including offline when both decks are on the device (file copies queued).
- Dropping slides from another deck's grid view (P2: two decks side by side) is not supported in
  v1 (single window).

### 5.9 Keyboard (navigator scope `slidesNavigator`)

| Key | Action | Command |
|-----|--------|---------|
| ↑ / ↓ | Previous / next row (focus + current slide; headers get focus without changing the slide) | `slides.nav.previousSlide` / `nextSlide` |
| Shift+↑ / ↓ | Extend selection | — |
| Home / End | First / last row | — |
| ← / → on a header | Collapse / expand; on a slide inside a group, ← moves focus to its header | `slides.group.collapse` / `expand` |
| Enter | On a slide: focus the canvas; on a header: toggle collapse | — |
| F2 | Rename group (header) | `slides.group.startRename` |
| ⌘↑ / ⌘↓ (Ctrl) | Move selection up / down one position | `slides.slide.move` / `slides.group.move` |
| ⇧⌘↑ / ⇧⌘↓ | Move to start / end | same |
| ⌘G / ⇧⌘G (Ctrl) | Group slides / ungroup | `slides.group.create` / `ungroup` |
| ⌃M / Ctrl+M | New slide | `slides.slide.new` |
| ⌘D | Duplicate slides/groups | `slides.edit.duplicate` |
| ⌫ / Delete | Delete (groups: dialog) | `slides.edit.delete` |
| ⌘C / ⌘X / ⌘V | Copy / cut / paste slides and groups | `shell.edit.*` |
| ⌘A | Select all slides | `shell.edit.selectAll` |
| ⌘Enter / ⇧⌘Enter | Present from selected / from start | `slides.present.*` |
| ⌥⌘[ / ⌥⌘] | Collapse all / expand all | `slides.group.collapseAll` / `expandAll` |
| Type-ahead | Letters jump to the next group whose title starts with them | — |

Screen readers: rows are a tree (`Semantics(treeItem)`): "Group Intro, 3 slides, expanded,
skipped"; "Slide 4 of 24, in group Intro: Our mission, 2 comments, skipped".

### 5.10 Drag and drop

- Drag starts after 4 px. Dragging any selected row drags the **whole navigator selection**; the
  ghost shows the first thumbnail stacked with a count badge ("3 slides" / "Intro · 5 slides").
  Dragging a group header collapses it visually during the drag.
- **Drop indicator**: a 2 px `primary` line between rows with a 6 px circle at its start; its
  **indentation** shows the target level:
  - Between slides of an expanded group → inside the group (indented, in the group color).
  - Below the last slide of an expanded group → the pointer's x decides: x ≥ 24 px from the
    navigator's left → inside the group (end); otherwise → top level after the group. The
    indicator re-indents live as the pointer moves.
  - On a **group header** (middle 50 % of its height) → highlights the header: drop appends to
    that group (collapsed or expanded); upper/lower quarter → top-level before/after the group.
  - On a collapsed group's preview area → append to the group.
- **Groups** can only drop at top-level positions; while dragging a selection containing groups,
  inside-group positions show a red indicator with the tooltip "Groups can't be nested" and drop
  is refused.
- **Alt (Option)** while dropping copies (duplicates) instead of moving (cursor `+`).
- Auto-scroll within 32 px of the list edges (speed ∝ distance). Esc cancels.
- One drop = one undo step ("Move slides" / "Move group"), writing `groupId`+`sortKey` pairs
  (02 P4) and/or group `sortKey`s; keys are `nBetween` the drop neighbors in the target key space.
- Dropping **elements** dragged from the canvas onto a slide row moves (Alt: copies) them to
  that slide (03 §4.1, P1).
- Dropping **image files** from the OS on a slide row inserts them on that slide; between rows
  creates one new slide per image (layout `imageFull`) (P1).

### 5.11 Empty states and view mode

- **Empty deck** (zero slides): navigator shows "No slides" with **New slide**; the canvas shows
  an empty-state illustration with *New slide* and *Choose a layout* (layout gallery).
- **Empty group**: header + an indented dashed drop zone "Drop slides here" (also a *New slide in
  group* link).
- Viewers/commenters: selection, collapse/expand, copy (if allowed) and present work; drag,
  rename, color, skip, delete and grouping are disabled (reason tooltip).

### 5.12 Decided (v2 review, Q22): nested groups

**One level in v1** (option A). D11 lists nesting as P2; the model reserves
`SlideGroup.parentId` (02 §3.4, always null in v1), so nesting needs no schema change later.

| Option | Pros | Cons |
|--------|------|------|
| **A. One level only (v1)** *(chosen)* | Simple mental model (PowerPoint sections, Keynote collapsible groups are one level in practice); clear drop targets; groups map 1:1 to PDF bookmarks and presenter picker sections | Large decks can't express chapters ▸ sections |
| B. Nesting up to 2 levels (P2) | Chapters with sub-sections (talks with many parts) | More complex drag targets (indent levels), group ops must recurse (skip, duplicate, delete), outline/grid view headers nest |
| C. Arbitrary depth | Maximum flexibility | Hard to use in a 220 px navigator; deep trees rarely help presentations |

If B is chosen later: `parentId` is set only to a top-level group; drop indicators get a second
indent level (x ≥ 36 px); *Group slides* inside a group creates a subgroup; `slides.group.create`
gains `parentGroupId`.

### 5.13 Group commands summary

| Command id | Args | Undoable | Role |
|------------|------|----------|------|
| `slides.group.create` | `{slideIds?, title?, color?}` → `{groupId}` | ✓ | Editor |
| `slides.group.rename` / `startRename` | `{groupId, title}` / `{groupId?}` | ✓ / — | Editor |
| `slides.group.setColor` | `{groupIds?, color?}` | ✓ | Editor |
| `slides.group.toggleSkip` | `{groupIds?, skipped?}` | ✓ | Editor |
| `slides.group.move` | `{groupIds?, to}` | ✓ | Editor |
| `slides.group.duplicate` | `{groupIds?}` | ✓ | Editor |
| `slides.group.delete` | `{groupIds?, withSlides: bool}` | ✓ | Editor |
| `slides.group.ungroup` | `{groupIds?}` | ✓ | Editor |
| `slides.group.addSlides` / `removeSlides` | `{groupId, slideIds?}` / `{slideIds?}` | ✓ | Editor |
| `slides.group.collapse` / `expand` / `toggleCollapsed` / `collapseAll` / `expandAll` | `{groupIds?}` | — (view state) | Viewer+ |
| `slides.nav.goToGroup` | `{groupId}` | — | Viewer+ (palette provider "Go to group…") |

---

## 6. Toolbar

`SlidesToolbar` is a `WonkyToolbar` (suite 02 §4.1); priority 1 = never overflows. Items are
**contextual**: the middle section changes with the selection (Google Slides pattern).

### 6.1 Fixed items

| # | Control | Widget | Command(s) | Tooltip | Prio |
|---|---------|--------|-----------|---------|------|
| 1 | Undo / Redo | `ToolbarButton` (long-press undo → history) | `shell.edit.undo` / `redo` | Undo (⌘Z) / Redo (⇧⌘Z) | 1 |
| 2 | Paint format | `ToolbarToggleButton` (double-click sticky) | `slides.format.paintFormat` | Paint format | 3 |
| 3 | Zoom | `ToolbarSelect` (Fit, 50, 75, 100, 150, 200 %) | `slides.view.zoom*` | Zoom | 5 |
| — | separator | | | | |
| 4 | New slide | `ToolbarSplitButton` (+; chevron → layout gallery menu with thumbnails) | `slides.slide.new {layoutId?}` | New slide (⌃M) | 1 |
| — | separator | | | | |
| 5 | Select | `ToolbarToggleButton` (arrow; active when no insert tool armed) | `slides.tool.select` | Select (Esc) | 2 |
| 6 | Text box | `ToolbarToggleButton` | `slides.insert.textBox` | Text box (T) | 1 |
| 7 | Shape | `ToolbarDropdownButton` → shape grid by category | `slides.insert.shape` | Shape (S) | 2 |
| 8 | Line | `ToolbarDropdownButton` → line/arrow/connectors | `slides.insert.line` | Line (L) | 3 |
| 9 | Image | `ToolbarDropdownButton` → Upload / Drive / URL / Clipboard | `slides.insert.image` | Insert image | 2 |
| 10 | Table | `ToolbarDropdownButton` → `WonkyTableSizePicker` | `slides.insert.table` | Insert table | 4 |
| 11 | Code | `ToolbarButton` (`code-xml`) | `slides.insert.code` | Insert code block | 3 |
| 12 | Chart | `ToolbarDropdownButton` → From Sheets… / native types | `slides.insert.chartFromSheets` / `chart` | Insert chart | 4 |
| 13 | Icon | `ToolbarButton` (`shapes`) | `slides.insert.icon` | Insert icon | 5 |
| — | separator | | | | |
| 14–n | **Contextual section** (§6.2) | | | | |
| — | separator (right-aligned group) | | | | |
| r1 | Comment | `ToolbarButton` | `shell.comments.create` | Add comment (⌥⌘M) | 4 |
| r2 | Animate | `ToolbarButton` (`sparkles`, label "Animate") | `slides.panel.animate {tab: build}` | Animate | 2 |

### 6.2 Contextual section

| Selection | Controls (left → right) |
|-----------|-------------------------|
| **Nothing** (slide) | *Background* (`slides.inspector.open {tab: slide}`), *Layout ▾* (layout gallery → `slides.slide.applyLayout`), *Theme* (`slides.panel.themes`), *Transition* (`slides.panel.animate {tab: transition}`) — Google Slides' slide toolbar |
| **Text** (editing or text-capable element) | Text style ▾ (`FontPicker`-like style list with previews), Font ▾ (`FontPicker`, sections Theme fonts / Recent / All bundled), Size (`ToolbarNumberField` − 40 +), **B** **I** **U**, Text color (`ToolbarSplitButton` → `WonkyColorPicker` with Theme colors row), Highlight, Link, Align ▾ (left/center/right/justify + top/middle/bottom), Lists ▾ (bulleted/numbered/checklist + styles), Line spacing ▾, Indent − / +, Clear formatting; for shapes also Fill, Border |
| **Shape** | Fill (split; color/gradient/image/none), Border color, Border weight ▾, Border dash ▾, Quick styles ▾, Change shape ▾, + text controls when it has text |
| **Line** | Line color, Weight ▾, Dash ▾, Start arrow ▾, End arrow ▾, Routing ▾ |
| **Image** | Crop, Mask ▾, Replace ▾, Adjustments (opens Inspector › Format › Image), Border, Reset |
| **Table** | Fill, Border picker (`TableBorderPicker`), Border color/weight, cell vertical align ▾, + text controls |
| **Code** | Language ▾, Line numbers toggle, Highlight steps (opens Inspector › Format › Code, 07), States ▾ (07) |
| **Chart** | Update (when linked & stale, with dot), Edit in Sheets (`slides.chart.openSource`), 3D view ▾ (08), Style ▾ |
| **Icon** | Color, Stroke width ▾, Replace icon |
| **Multiple** | Fill, Border, Align ▾ (align/distribute menu), Group / Ungroup, Order ▾ |

Toolbar state mirrors the selection (toggles checked when **all** selected text/elements share
the value; mixed shows the first element's value like Sheets 04 §4). Overflow: at 1,280 px the
contextual section's lowest-priority controls move to "⋯"; at 1,024 px items with prio ≥ 4 too.

---

## 7. Inspector

### 7.1 Layout

A docked, resizable right column (default 300 px, 260–420 px, device pref
`slides.inspector.width`), between the canvas and the shell side panel host, toggled with
`slides.view.toggleInspector` (⌥⇧⌘I). Tabs (`ShadTabs`): **Format** · **Animate** · **Slide**
(`slides.inspector.open {tab, section?}`). Body in `WonkyScrollArea`, sections as `ShadAccordion`
items (multiple open, open state per user). Every control commits through a command (one undo
step per committed change; slider drags coalesce into one step on release).

**Decided (v2 review, Q21): docked inspector, not a side panel.** D-brief asks for an inspector
with Format / Animate / Slide tabs; 06 specifies the Animate UI as the panel
`slides.panel.animate`. The **docked inspector** (Keynote/Pitch/Figma: always
visible while designing) hosts the Animate UI of 06 §5 as its **Animate tab**, and
`slides.panel.animate {tab}` is an alias that opens the inspector on that tab (sub-tab
Transition/Build/Order). The shell side panel host stays free for Comments, Assistant, Layers,
Themes, Accessibility at the same time. Alternative: inspector as one more `SidePanelSpec` —
simpler shell integration, but opening Comments or the Assistant hides the inspector, which
breaks the design flow (rejected). Below 1,200 px the docked inspector overlays the canvas (§16).

### 7.2 Format tab (by selection)

| Selection | Sections (in order) |
|-----------|---------------------|
| None | Empty state "Select an object to format it" + quick buttons: *Text box*, *Shape*, *Image*; the slide's background is on the Slide tab |
| Text / shape / placeholder | **Text** (style, font, size, weight, color, highlight, B/I/U/S, caps, letter spacing, alignment, anchor, line height, space before/after, lists & bullets, autofit, insets, columns (P2)), **Fill**, **Border**, **Effects**, **Arrange**, **Link**, **Accessibility** |
| Line | **Line** (color, weight, dash, cap, arrows start/end + size, routing), **Effects**, **Arrange** |
| Image | **Image** (replace, crop, mask, adjustments sliders, reset, opacity), **Border**, **Effects**, **Arrange**, **Link**, **Accessibility** |
| Table | **Table** (style, header row, first column, banded rows/columns, total row, distribute, cell padding), **Cell** (fill, borders, vertical align), **Text**, **Arrange** |
| Icon | **Icon** (replace, color, stroke width), **Arrange**, **Link**, **Accessibility** |
| Code | **Code** (07: language, theme appearance, line numbers, wrap, font size/auto-fit, title, chrome, highlight steps, states), **Effects**, **Arrange** |
| Chart | **Chart** (08: link status, update, auto-update, style overrides, 3D camera, data table for native), **Arrange**, **Accessibility** |
| Group | **Arrange**, **Effects**, **Accessibility** (+ "Edit inside group") |
| Multiple | Common sections (Fill, Border, Effects, Arrange incl. align/distribute buttons); values "Mixed" when different |

**Arrange** section: X, Y, W, H (su), lock aspect, rotation (`WonkyNumberStepper` + dial), flip
H/V, align/distribute icon rows, order buttons, lock toggle, name field, **Magic Move ID**
(text field, 06 §8.2), *Reset to layout* (placeholders), *Scale text when resizing* (multi).

**Accessibility** section: alt text field (+ *Generate with AI*), *Decorative* toggle, reading
order position ("3 of 7", *Edit order…* → Layers › Reading order).

### 7.3 Animate tab

Hosts the Animate UI of [06 §5](06-animations-and-transitions.md) (Transition / Build / Order
sub-tabs, effect grid, timing, Order list, Preview). Viewers see it read-only.

**As built (SL-30).** `features/inspector/animate/` (06 §5.7): the sub-tabs are ghost buttons under
the inspector tabs (`slides.panel.animate {tab}`), with the *Reduce motion* banner above the body;
every control runs a command. Inspector › Arrange gains the *Magic Move ID* field
(`slides.element.setMatchKey`). Settings › *Animations & code* › *Animations* lists every
transition but Magic Move and the build-in effects for any object; the default transition applies
to blank presentations. Shown only while `SlidesFeature.animations` is on.

### 7.4 Slide tab

| Section | Controls | Commands |
|---------|----------|----------|
| Layout | Layout gallery (thumbnails of the theme's layouts), *Reset slide to layout*, *Edit layout* (master mode at this layout) | `slides.slide.applyLayout`, `resetToLayout`, `slides.view.setMode {masters, layoutId}` |
| Background | Fill editor (solid/gradient/image, theme colors), *Reset to layout background*, *Apply to all slides* (P1) | `slides.slide.setBackground {fill?}`, `slides.slide.applyBackgroundToAll` |
| Theme & appearance | Current theme name (→ Themes panel), deck appearance Light/Dark segmented (05 §2.4) | `slides.deck.setAppearance {appearance}` |
| Visibility | *Skip slide* switch (disabled with reason if skipped via group), *Hide master objects* switch | `slides.slide.toggleSkip`, `slides.slide.setHideMasterElements` |
| Group | Group name + color (or "Not in a group") with *Remove from group* | `slides.group.*` |
| Info | Slide number, layout name, created/modified (read-only), comment count | — |

Multi-selected slides in the navigator: Slide tab edits apply to all (one step).

---

## 8. Speaker notes pane

- Below the canvas, default 120 px, resizable 48 px – 50 % of the editor height (device pref);
  toggled by `slides.view.toggleNotes` (⌥⇧⌘N) and a handle bar ("Speaker notes ⌃").
- Editor: the notes subset of the text schema (02 §4.3) in the app UI font, 14 px, with a mini
  toolbar on focus (B, I, U, list, link); placeholder "Click to add speaker notes". Font zoom
  (P1) `slides.notes.zoom {percent}` 75–200 %.
- Writes `Slide.notes` with the same persistence, typing coalescing and **soft lock** as text
  bodies (02 §4.4): "Anna is editing these notes".
- Scope `slidesNotes`; Esc returns focus to the canvas. Find & replace includes notes.
- Viewers see notes read-only (commenters too).

---

## 9. Grid view (light table, P1)

- `slides.view.setMode {mode: grid}`: a responsive grid of thumbnails (size slider 120–480 px,
  device pref), **groups as section headers** spanning the row (chevron, color, title, count,
  ⋮) — same collapse state as the navigator, same selection model (§5.5), same keyboard (arrows
  move in 2D; ⌘ arrows move slides), same drag & drop (indicator: vertical bar between
  thumbnails; dropping on a section header appends to the group; groups drag as sections), same
  context menus and commands.
- Double-click / Enter opens the slide in Normal view.
- Skipped slides dimmed; slide numbers under thumbnails; comment/presence badges as in §5.2.

## 10. Outline view (P1)

- `slides.view.setMode {mode: outline}`: a single text-like document of the deck:

```
 ● INTRO (group header, color dot, editable title)
 1  Our mission                                  ← title placeholder text
       • Make collaboration feel effortless      ← body placeholder paragraphs
       • Offline is normal
 2  The problem
 ● DEMO
 3  …                                (+ 2 images, chart)   ← other elements summarized
```

- Editable: slide titles (the `title` placeholder's text) and the **first body placeholder**'s
  paragraphs (plain lines with list indentation; inline bold/italic preserved, other formatting
  kept on untouched runs); group titles. Other elements are listed read-only as a muted summary.
- Keys: Enter at the end of a title → new slide (`titleBody`) after it, caret in its title;
  ⌘Enter in a title → first bullet of its body; Enter in a bullet → new bullet; Tab / Shift+Tab →
  indent/outdent bullet; Shift+Tab on a level-0 bullet → **promote to a new slide** (P2); ⌘G on
  selected slide lines → group. Each edit writes the corresponding element text (one undo step per
  typing burst) via `slides.outline.setTitle {slideId, text}`, `slides.outline.setBody {slideId,
  delta}`, `slides.outline.newSlideAfter {slideId, title}`.
- Slides without a title placeholder show "(no title)" (click → adds a title placeholder instance
  if the layout has one).
- Copy from the outline gives Markdown (`#` titles, bullets); *Download ▸ Outline as Markdown*
  (P2) exports the same.

**As built (SL-34).** `features/outline_view/` (`OutlineView`), feature `outlineView`:
- Lines: one field per title and per body paragraph (`ShadInput`); the "first body placeholder"
  falls back to the **subtitle** on title slides. Inline bold/italic/underline/strike are drawn
  and kept: an edit diffs the line's text (common prefix/suffix), so untouched runs keep all their
  attributes and typed text takes the attributes before it. Typed line breaks become soft breaks.
- Writes: typing goes through `slides.outline.setTitle {slideId, text}` /
  `slides.outline.setBody {slideId, delta}` 500 ms after the last key with `typing: true`,
  coalesced per slide (one undo step per burst); pending typing is flushed into the next
  structural command's step and before undo/redo. A slide without a title instance gets one from
  its layout on the first edit (`InsertElements` + `ResetPlaceholders`, frame inherited).
- Keys (scope `slidesOutline`; each a command that also takes `slideId`/`index`/`offset`, index
  -1 = title): Enter `slides.outline.newSlideAfter` (title; the text after the caret moves to the
  new slide's title) / `slides.outline.newLine` (bullet split); ⌘Enter
  `slides.outline.focusBody`; Tab / Shift+Tab `slides.outline.indent` / `outdent` — Shift+Tab on
  a level-0 bullet **promotes** it (built, was P2: the bullets after it move along, its
  sub-bullets one level up), Tab on a title **demotes** the slide into the previous slide's
  bullets (only when it holds nothing but title and bullets and has no notes); Alt+Shift+↑/↓
  `slides.outline.moveUp`/`moveDown` (bullets in their body; slides via `slides.slide.move`);
  Backspace at a line start `slides.outline.joinLine` (joins a bullet onto the one above, deletes
  an empty slide); ⌘G `slides.outline.groupSlides` (`slides.group.create` on the selected slides);
  ↑/↓ cross lines at the first/last visual line; ⌘Z/⇧⌘Z run the deck's undo.
- Copy: `slides.outline.copyMarkdown` (top-bar button) copies the whole outline (`#` titles, `-`
  bullets indented two spaces per level, groups as `<!-- Group -->` comments) and returns it to
  MCP; a selection spanning several lines can't be copied as one (each line is a field).
  *Download ▸ Outline as Markdown* (P2) is not built.
- Groups: chevron = the navigator's collapse state (`slides.group.toggleCollapsed`), title renamed
  by double-click (`slides.group.rename`); empty groups are not listed. The focused slide is the
  current slide; slide numbers select (Shift/Mod extend the navigator selection). Collaborators
  editing a title or body (their soft-lock claim) show a 3 px caret bar in their color; outline
  typing itself doesn't claim a soft lock yet. Viewers see read-only lines.

---

## 11. Context menus

All built from `context_menu_specs.dart` (`ShadContextMenuRegion` + `WonkyDropdownMenu`), exposed
via MCP `ui.get_menu_tree {menu: 'context.<id>'}`.

### 11.1 Canvas, empty slide area (`context.slide`)

Paste · Paste without formatting · — · New slide · Duplicate slide · Skip slide ✓ · — · Apply
layout ▸ · Change background… · Transition… · — · Comment on slide (`shell.comments.create`
with slide anchor) · — · Edit layout · Edit masters and layouts · — · Guides ▸ (P1) · Select all.

### 11.2 Element (`context.element`)

| Item | Command |
|------|---------|
| Cut / Copy / Paste / Duplicate / Delete | `shell.edit.*`, `slides.edit.duplicate`, `slides.edit.delete` |
| Copy style / Paste style | `slides.format.copyStyle` / `pasteStyle` |
| — | |
| Order ▸ (4 items) | `slides.arrange.order` |
| Align ▸ / Distribute ▸ (multi) | `slides.arrange.align` / `distribute` |
| Group / Ungroup | `slides.arrange.group` / `ungroup` |
| Rotate ▸ | `slides.arrange.rotate` / `flip` |
| Lock / Unlock · Hide | `slides.element.toggleLock` · `slides.element.hide` |
| — | |
| Animate ▸ Add build in ▸ / Add action ▸ / Add build out ▸ / Copy animation / Paste animation / Remove animations | `slides.animate.*` (06 §15) |
| Magic Move ID… | `slides.inspector.open {tab: format, section: arrange}` |
| Link… / Remove link | `slides.element.setLink` / `removeLink` |
| Alt text… | `slides.element.editAltText` |
| Comment | `shell.comments.create` (element anchor) |
| Reset to layout (placeholders) | `slides.element.resetPlaceholder` |
| Format options… | `slides.inspector.open {tab: format}` |

Kind additions at the top: **image** → Crop, Mask ▸, Replace image ▸, Reset image, Download
original; **shape** → Edit text, Change shape ▸; **line** → Start/End arrow ▸, Routing ▸;
**table** → table items (§11.4); **code** → Edit code, Language ▸, States… (07); **chart** →
Update, Open source spreadsheet, Unlink, Copy chart as image (08); **group** → Enter group.

### 11.3 Text editing (`context.text`)

Spelling suggestions (top, when on a misspelled word) · Cut / Copy / Paste / Paste without
formatting · — · Link… · Comment · — · Text style ▸ · Bullets & numbering ▸ · Clear formatting ·
— · AI ▸ Rewrite ▸ (11).

### 11.4 Table cells (`context.table`)

Cut / Copy / Paste · — · Insert row above / below · Insert column left / right · Delete row /
column · Delete table · — · Merge cells / Unmerge · Distribute rows / columns · — · Cell fill ▸ ·
Borders ▸ · Vertical align ▸ · — · Table options….

### 11.5 Navigator slide (`context.navigatorSlide`)

New slide · Duplicate slide(s) · Delete slide(s) · Skip / Unskip slide · — · Cut / Copy / Paste ·
— · Group slides (⌘G) · Add to group ▸ (P1) · Remove from group · — · Move to beginning / Move to
end · — · Apply layout ▸ · Change background… · Transition… · — · Comment on slide · Present from
this slide.

### 11.6 Navigator group header (`context.navigatorGroup`)

| Item | Command |
|------|---------|
| Rename | `slides.group.startRename` |
| Color ▸ *palette* | `slides.group.setColor` |
| Collapse / Expand · Collapse all · Expand all | `slides.group.*` |
| — | |
| New slide in group | `slides.slide.new {inGroup}` |
| Select slides in group | `slides.group.selectSlides` |
| Duplicate group | `slides.group.duplicate` |
| Cut / Copy / Paste | `shell.edit.*` |
| Skip group ✓ | `slides.group.toggleSkip` |
| — | |
| Ungroup | `slides.group.ungroup` |
| Delete group… | `slides.group.delete` (dialog §13.4) |
| — | |
| Present from this group | `slides.present.fromSlide {slideId: first}` (10) |

### 11.7 Navigator empty area (`context.navigatorEmpty`)

New slide · Paste · New group (creates an empty group at the end, rename field open,
`slides.group.create {slideIds: []}`) · Collapse all · Expand all.

---

## 12. Side panels

Hosted by the shell `WonkySplitView` (one active, icon rail, shared width; suite 02 §4.5),
independent of the docked inspector.

| Panel id | Title | Opened by | Spec |
|----------|-------|-----------|------|
| `comments` (shell) | Comments | header button, `shell.comments.togglePanel` | [09 §3](09-collaboration-history.md) |
| `assistant` (shell) | Assistant | rail, ⌘J | 11 |
| `slides.panel.layers` | Layers | Arrange › Layers | 03 §8.1 (P1) |
| `slides.panel.themes` | Themes | Slide › Change theme, toolbar *Theme* | [05 §9](05-themes-layouts-masters.md) |
| `slides.panel.accessibility` | Accessibility | Tools › Accessibility check | 03 §17.4 (P1) |
| `slides.panel.linkedObjects` | Linked charts | chart badge, `slides.panel.linkedObjects` | [08 §14](08-charts-from-sheets.md) |
| `slides.panel.animate` | → alias of Inspector › Animate (§7.1) | `slides.panel.animate` | 06 §5 |
| — | Version history | full-screen route `/p/:uuid/history` | 09 §4 |

---

## 13. Dialogs

All dialogs are `WonkyFormDialog`s from a `WonkyDialogSpec` (MCP-operable, suite 09 §6.2) unless
marked *custom* (then `McpDescribableDialog`). Primary button right-most; Esc cancels; Enter =
primary when valid.

*As built (SL-42, AC-9 audit):* every Slides dialog is a `WonkyDialogSpec` or a custom
`McpDescribableDialog`; the soft-lock popover (13.11) is registered as one (`SoftLockDialog`),
*View data as table* is wrapped in an `McpDialogScope`, and the shell dialogs Slides opens —
keyboard shortcuts (13.15), Check spelling, Personal dictionary, Special characters, the emoji
picker — are describable. Commands open their dialogs for agents through
`ui.slides.open_dialog` (11 §5).

### 13.1 Page setup (`slides.file.pageSetup`)

Fields: `preset` (`ShadSelect`: Widescreen 16:9, Standard 4:3, Widescreen 16:10, Square 1:1,
Portrait 9:16 (P1), A4 landscape, Letter landscape, Custom), `width`/`height` (custom; units
selector su / px / in / cm), `scaleContent` (radio: *Scale content to fit* (default) / *Don't
scale*). Preview of the current slide in the new size. [Cancel] [Apply] →
`slides.deck.setSize {preset, width, height, scaleContent}` (one step; rewrites frames when
scaling, 05 §7).

### 13.2 Insert image by URL

`url` input with validation (http/https), preview once fetched (via the proxy), error text
"Couldn't load this image." [Cancel] [Insert].

### 13.3 Slide numbers and footer (`slides.deck.openNumbering`)

`showSlideNumbers` switch, `firstSlideNumber` stepper, `hideNumberOnTitle` checkbox,
`footerText` input (empty = hidden), preview. [Cancel] [Apply] → `slides.deck.setNumbering {…}`.

### 13.4 Delete group

`ShadDialog.alert`: "Delete group '{title}'?" body "The group contains {n} slides." Buttons:
[Cancel] [Ungroup only] [Delete group and {n} slides] (destructive). Undoable either way (toast
"Group deleted — Undo").

### 13.5 Link (popover, *custom*)

Anchored to the selection: tabs **URL** (input + *Apply*) and **Slide** (searchable list with
thumbnails and group headers); for elements also *Next slide / Previous slide / First / Last / End
show* actions; *Remove link*.

### 13.6 Icon picker (*custom*)

720 × 520: search field, category sidebar (Arrows, Business, Charts, Communication, Devices,
Files, Media, Nature, People, Shapes, Text, Travel, Weather…, from Lucide tags), virtualized grid
(48 px cells, name tooltip), *Recent* row, stroke width segmented (1/1.5/2/2.5/3), color swatch
(theme colors), [Cancel] [Insert] (double-click inserts). Keyboard: arrows over the grid, Enter
inserts.

*As built (SL-14):* `showIconPicker` (`features/elements/icon/icon_picker.dart`) — up to
720 × 520; categories *All*, *Recently used* (per user and device, newest 24) and 18 keyword
categories derived from the icon names (Lucide's tag data isn't shipped with the font; search
also matches aliases and common synonyms); color is a row of the theme colors plus *Theme
default* (no custom colors in the picker — the inspector's color button has the full picker);
below 560 px the sidebar becomes a category select. MCP-operable: fields `query`, `category`,
`icon` (the first 200 matches with labels), `strokeWidth`, `color`; buttons `cancel`, `insert`.
The *All shapes…* gallery dialog and the alt text dialog (13.7: a `WonkyDialogSpec` with the
description and *Decorative*) are MCP-operable too.

### 13.7 Alt text

`altText` (textarea, counter /1,000), `decorative` checkbox (disables the textarea), *Generate
with AI* (11), [Cancel] [Save].

### 13.8 Image adjustments

Inspector section (not a dialog) — listed for completeness (03 §6.5.5).

### 13.9 Import slides (`slides.file.importSlides`, P1, *custom*)

Step 1: Drive picker filtered to presentations. Step 2: the source deck's slides as a grid with
group sections and checkboxes (*Select all*, per-group checkboxes), option *Keep source
formatting* (default off = use this deck's theme). [Cancel] [Import {n} slides] → inserted after
the current slide (groups kept). Works offline when the source deck is on the device; otherwise
"Connect to the internet to import from a presentation that isn't on this device".

### 13.10 Go to slide (`slides.nav.goToSlide`)

Command-palette-like list of slides ("4 · Our mission — Intro") and groups with fuzzy search;
Enter goes. Also the palette provider "Go to slide…".

### 13.11 Soft-lock popover (*custom*, 02 §4.4)

"Anna is editing this text." [Cancel] [Edit anyway]. Shown on double-click/Enter/typing into a
claimed body.

### 13.12 Paste options chip

Floating chip after a cross-deck paste or a Sheets chart paste: *Use destination theme* ✓ / *Keep
source formatting* / (charts) *Paste unlinked*. Not modal; disappears after 10 s or on the next
edit (03 §12.3). *As built (SL-18):* a select in a small floating card (current mode ✓; charts:
*Linked to the spreadsheet* / *Paste chart unlinked*) with a close button; not shown for
cross-deck element pastes — 03 §12 "As built (SL-18)".

### 13.13 Quota exceeded

Suite dialog (D3): "You're out of storage — free up space in Wonky Drive" [Open Wonky Drive]
[OK].

### 13.14 Overwritten text review (09 §6.3)

### 13.15 Keyboard shortcuts (`shell.help.shortcuts`)

Shell dialog with Slides categories: Common, Slides & groups (navigator), Canvas & objects, Text,
Tables, Arrange, View, Present, Animations, Comments, Menus.

### 13.16 Slides settings (`/settings/app`, D4)

Built as the Slides app's settings sections (`WonkyAppConfig.settingsSections`), stored in
`UserPreferences.slidesDefaults` (§17):

| Section | Settings |
|---------|----------|
| New presentations | Default theme (gallery), default appearance (Light/Dark), default slide size, default language |
| Editing | Units (su / px / in / cm, P1), *Smart guides*, *Snap to objects*, *Snap to guides*, *Scroll to change slides* (P1), *Smart quotes*, *Autoformat lists*, *Show collaborator cursors* |
| Animations | Default transition (effect + duration), default build effect, *Preview animations on hover*, *Reduce motion in the editor* (06 §13) |
| Code | Default code font size, default code language, *Type-in click sound* (off), default typing speed (07) |
| Presenting | Presenter-view layout, timer mode (elapsed/countdown), laser pointer color, *Start presenting in full screen*, *Start with presenter view* — stored in `UserPreferences.slidesPresenter` (10 A-10-4); the *This presentation* section edits `Deck.presentJson` (10 §3) |
| Charts | *Update linked charts automatically by default* (08) |
| Spelling | Language default, *Underline spelling errors* |

---

## 14. Status bar

`EditorScaffold.showStatusBar = true`; items (suite 02 §4.13):

| Slot | Content |
|------|---------|
| Left | "Slide 4 of 24" (current position in presentation order; skipped slides counted) · group title of the current slide (color dot) · "{n} skipped" (when > 0, click → selects skipped slides) |
| Center | Offline storage warning (IndexedDB fallback); "Presenting: Anna" pill when someone presents (click → follow, 09) |
| Right | View mode buttons Normal / Grid / Outline (`slides.view.setMode`) · Zoom (− [Fit/100 %] + , click → zoom menu) |

---

## 15. Home screen and templates (Slides variant of the unified Drive, D2)

- `SlidesAppConfig.homeScope` = `HomeScope.kind(presentation)` (as built in SL-1): the app home shows **only presentations** (Recent, My files, Shared with
  me, Starred, Trash) with folders only as navigation (D2; only folders that contain a presentation,
  `kindMask` — decided in the v2 review, Q7, suite 03 §3.3). The left menu follows D2: apps section (Drive, Write, Sheets, **Slides**
  highlighted), the Slides navigation, then *Slides settings*, *Wonky Work settings*, *Bugs &
  Improvements* (M12; was *Report a bug*), storage meter ("12.3 MB of 50 MB"); *Open in Wonky Drive* link.
- **+ New** → *Presentation* (created on the device, works offline, 02 §9.3) and *From template…*.
- **Template strip**: Blank, Pitch deck, Project kickoff, Quarterly review (with linked-chart
  placeholders), Tech talk (code walkthrough with type-in), Lesson, Product launch, Weekly
  update, Portfolio, Workshop agenda — server-shipped presentations with `DriveItem.templateOf`
  (categories *Business*, *Education*, *Engineering*, *Personal*), each built on a built-in theme
  (05 §6).
  *As built (SL-22, 5 of 10):* Pitch deck (Aurora), Project kickoff (Swiss), Weekly update
  (Wonky), Lesson (Botanical) and Workshop agenda (Terminal) are core decks
  (`SlidesTemplates`, planner operations — 12 §4 SL-22) the app creates offline like a blank
  deck; the categories use the suite's `TemplateCategory` values (*Work*, *Project
  management*, *Education*). Template cards of presentations are slide-shaped (16:9); Slides
  renders the first slide of each built-in (`WonkyAppConfig.templatePreview`), other apps and
  published templates show a title-slide miniature in the theme's colors.
  *As built (SL-36, 9 of 9 + Blank = 10):* Quarterly review (Classic: key figures that build
  in, two chart-layout slides with **sample chart snapshots** in the chart placeholders — one
  growing by series, one 3D with a *Rotate to angle* camera build — KPI table, priorities that
  dim; *Relink…* turns a sample into a linked spreadsheet chart, which is how the template's
  "linked-chart placeholders" work: a template can't link to a spreadsheet the user doesn't
  have), Tech talk (Midnight: a callback pyramid **typed** into async/await with highlight steps
  and callouts, an error-handling walkthrough, a stream pipeline that **Magic Moves** (token
  morph) between two slides, cube transitions between parts), Product launch (Studio: title and
  statement that build in, a device that Magic Moves aside to reveal features, cards that pop
  in, a pricing table that wipes in, a launch timeline drawn on, flip and doorway transitions)
  and Portfolio (Paper: project covers — colored shapes standing in for screenshots — that
  Magic Move into project pages, revolve into the closing slide; no images, so no upload or
  quota on creation). Gallery order follows the strip above. Every template carries its own
  deck default transition (fade, push for Product launch), the user's *Default transition*
  setting applies to blank decks only (06 §5.7). Categories: Quarterly review and Product
  launch *Work*, Tech talk *Education* (Engineering, as SL-22), Portfolio *Personal*.
- **Thumbnails**: client-generated after an editing session (route exit or every 10 min of
  editing, editors only): the first non-skipped slide rendered by `SlideStage` at 320 × 180
  (aspect-fitted), light app theme irrelevant (deck appearance), uploaded via the files endpoint
  and `drive.setThumbnail(itemUuid, fileUuid)`; skipped when the slide's revision hash is
  unchanged. Thumbnails don't count toward quota (D3).
- Drag-and-drop of images onto the home creates nothing (no import of PPTX/Keynote); dropping a
  PDF shows "Wonky Slides can't import PDF or PowerPoint files" (non-goal).
- Offline: decks kept complete in the device cache (opened in the last 14 days, pinned, or with
  unsent changes; 02 §9.1) show as available offline; others dimmed.

---

## 16. Light/dark and narrow widths

- **App chrome** (header, navigator background, inspector, notes pane, canvas surround) follows
  the app theme via shad tokens and the Slides tokens (03 §20). **Slides** render in the deck's
  appearance (05 §2.4) regardless of the app theme — a dark deck stays dark in a light app. The
  thumbnail ring/selection colors meet ≥ 3:1 against both navigator backgrounds (token test).
- Print/PDF use the deck appearance (not the app theme); "Use dark theme" from Write/Sheets
  doesn't apply (10).
- **Widths**:

| Width | Behavior |
|-------|----------|
| ≥ 1,440 px | Everything docked: navigator, canvas, inspector, side panel |
| 1,200–1,440 | Opening a side panel collapses the inspector to a 44 px tab strip (click → overlay) |
| 1,024–1,200 | Inspector overlays the canvas from the right (scrim-less, pinned until closed); toolbar overflow |
| 768–1,024 | Navigator shrinks to 140 px (thumbnails only, numbers inside); notes pane collapsed by default |
| < 768 | Navigator becomes a drawer (hamburger in the title row), inspector and panels overlay over a scrim, toolbar shows only fixed items + overflow; editing remains possible |
| < 640 | The read-only mobile layout (§16.1); the editor's narrow layout is checked at 640 px |
| 360 | No overflow (mobile layout: Present stays visible; title truncates) |

### 16.1 Mobile layout (T-9)

Below 640 px (suite 02 §6.1) the deck opens **read-only** (`DeckEditorController.readOnlyView`,
folded into `roleCanEdit`: no edit command, Viewing, Masters left) in the shell's mobile title
row with a *Present* icon button (`slides.mobile.present`, `slides.present.fromSlide` at the
current slide — never the presenter view). The body (`DeckBody`) is the canvas region over the
**compact slide selector** (`MobileSlideStrip`): one row of 72 px thumbnails with their numbers
below them (current slide ringed, skipped slides faded), scrolled to keep the current slide in
the middle; a tap runs `slides.nav.goToSlide`. No navigator, notes pane, inspector or other view
mode; widening the window returns to the editor as it was.

---

## 17. Additions to 02-data-model and suite specs

| # | Addition |
|---|----------|
| A-04-1 | `LocalViewState` keys (02 §7): `collapsedGroups`, `navigatorWidth`, `notesHeight`, `notesVisible`, `inspectorVisible`, `inspectorTab`, `inspectorSections`, `viewMode`, `gridThumbSize`. |
| A-04-2 | `UserPreferences.slidesDefaults` (suite 04, D4): `{defaultThemeKey, defaultAppearance, defaultSize, defaultLanguage, units, smartGuides, snapObjects, snapGuides, scrollChangesSlides, smartQuotes, autoformatLists, showRemoteCursors, defaultTransition, defaultBuild, previewOnHover, reduceEditorMotion, codeFontSize, codeLanguage, typeInSound, typingSpeed, chartsAutoUpdate, underlineSpelling}`; presenter preferences live in `UserPreferences.slidesPresenter` (10 A-10-4). |
| A-04-3 | **Suite (drive)**: `DriveItemKind.presentation`, `drive.registerPresentation(spaceUuid, name, parentUuid?)` (= `createPresentation(fileUuid: spaceUuid, initialize: false)`; idempotent, queued offline as a `PendingDriveOp`), `drive.createPresentation` (server path; `fileUuid`/`initialize`, RevLog), template category values for presentations, `drive.setThumbnail` reused. |
| A-04-4 | **Suite (shell)**: `EditorScaffold.titleActions` slot for app buttons in the title row (Present split button); `shell.board.report` header icon (D5, formerly `shell.help.reportBug`) placement before Share. |
| A-04-5 | **Suite (comments)**: `CommentAnchorKind` values `slide` and `element` (09 §3.1). |
| A-04-6 | Tokens: `groupColor.{gray,red,orange,amber,green,teal,blue,violet,pink}` (light/dark), `navigatorBackground`, `thumbnailRing`. |

---

## 18. Acceptance criteria

- AC-1: Every menu item of §4 dispatches exactly the listed command id (test iterates the
  `MenuSpec` against a golden list); every id exists in the registry at startup.
- AC-2: `ui.get_menu_tree` returns the same tree with enabled/checked states and reasons.
- AC-3: Navigator: create a group from 3 non-contiguous slides with ⌘G (they gather at the first
  slide's position), rename inline, color it, collapse it (only for this user: a second client
  still sees it expanded), drag the collapsed group to another position (one undo step, one group
  row written), drag a slide into and out of the group using the indentation rule, Alt-drag
  copies, skip the group (slides dimmed, presenting skips them), ungroup and delete-with-slides
  — each one undo step, synced to a second client within 3 s.
- AC-4: Copy two groups from deck A and paste into deck B (online and offline): groups arrive
  expanded with titles, colors, skip flags, slides, builds, code states, linked charts and images.
- AC-5: Keyboard-only navigator operation per §5.9 including group collapse and moving slides
  across group boundaries per §5.7.
- AC-6: Toolbar contextual section switches with the selection within one frame; overflow at
  1,024 px moves prio ≥ 4 items into "⋯", which invokes the same commands.
- AC-7: Inspector: every Format section control commits one undo step (slider drags coalesce);
  multi-selection shows "Mixed"; Slide tab background/layout/skip apply to multi-selected slides.
- AC-8: Grid view and outline view reflect and edit the same deck (titles edited in outline
  appear on slides; groups shown as sections with shared collapse state).
- AC-9: Every dialog in §13 is describable and completable through `ui.get_dialog` /
  `ui.fill_dialog` / `ui.press_dialog_button`.
- AC-10: Viewer mode hides/disables every mutating control, keeps Present, collapse and copy (if
  allowed); "View only" badge shown.
- AC-11: Light/dark: chrome follows the app theme; slides keep the deck appearance (goldens).
- AC-12: At 360 px width nothing overflows (the mobile layout, §16.1); at 640–768 px the
  navigator is a drawer.

---

## 19. As built (SL-11)

The chrome of §2–§4, §6–§8, §11, §13.10, §13.16, §14 and §16 is built (Slides 12 SL-11);
features of later work packages are wired as **disabled placeholder commands** ("Not available
yet") so the menus, toolbar, context menus, palette and MCP show the complete product, and a
work package only registers the real command.

- **Folders.** `wonky_slides/lib/commands/` (`commands.dart` = the registration index:
  real commands first, then every placeholder whose id has no real registration;
  `slides_command.dart` = `SlidesCommand` (+ `.placeholder` with the owning WP),
  `SlidesKeyScopes` (03 §1.2), `SlidesCategory`; `chrome_commands.dart`;
  `placeholder_commands.dart`), `lib/config/menus/{slides_menu_spec,context_menu_specs}.dart`,
  `lib/config/toolbar/slides_toolbar_spec.dart` (contextual section per selection kind),
  `lib/config/panels/slides_panels.dart` (side panel registry, empty until SL-17/32/34),
  `lib/features/editor_screen/` (`DeckEditorScreen`, `DeckDocumentController`,
  `DeckEditorController`, body/regions, status bar, Present button, loading view, view-mode
  shells, route placeholders, chrome prefs), `lib/features/inspector/` (section registry +
  `DeckInspector`), `lib/features/toolbar/`, `lib/features/dialogs/` (Go to slide),
  `lib/features/settings/`, `lib/theme/slides_tokens.dart` (A-04-6). There is no
  `config/routes.dart`: the child routes are `SlidesAppConfig.editorRoutes`.
- **Editor state.** `DeckEditorController` holds the current slide and the navigator
  selection (slides + groups), a minimal element selection (ids + `selectionKind`, SL-12
  extends it), the armed tool, the view mode, the panes (device prefs `slides.chrome`:
  visibility, inspector tab, widths, notes height), zoom (*Fit* + fixed steps), the View ›
  Show toggles, the focus nodes of the canvas/navigator/notes key scopes and **`apply(ctx,
  op)`** — the write path of every Slides command (execute + one `slides.rows` undo entry).
  `DeckDocumentController` is the shell document (title, role, `SlidesRowsUndoHandler`,
  selection snapshots = current slide + elements, zoom, sync status, `describeState`).
  `DeckHarness` (tests) now runs on both.
- **Canvas and navigator are shells** until SL-10/SL-12/SL-16: a static `SlidePreview`
  (background, frames, plain text in the theme styles, placeholder prompts) on the canvas and
  as navigator thumbnails; the navigator lists group headers and slides (click =
  `slides.nav.goToSlide`, right-click menus, `+ New slide`), the notes pane shows the notes
  read-only, Grid and Outline views are read-only shells, Masters mode explains itself.
- **Deviations from the tables above.**
  - View › Mode uses `slides.mode.editing` / `slides.mode.viewing` (the shell has no
    `shell.view.setMode`; same as Sheets). File › Open… is the shell's `shell.file.open`;
    Tools › Accessibility settings is the shell's `shell.settings.open {section: appearance}`;
    the shell's Tools › Explore item is removed.
  - View › Panels: Layers, Themes, Accessibility (and *Linked charts*) are the commands
    `slides.panel.layers|themes|accessibility|linkedObjects` (the owning WP opens its
    `SidePanelSpec` with `shell.panels.open`); Comments and Assistant are the shell toggles.
  - Format: *Fill…*, *Border…*, *Effects…* are single items (the pickers come with SL-14);
    Code ▸ *Line numbers* = `slides.code.updateOptions {toggle: lineNumbers}`, *States…* =
    `slides.inspector.open {tab: format, section: code}`; Insert › Shape ▸ is a gallery slot
    (`insert.shape.gallery`) plus *All shapes…*; Insert › Table ▸ is the size picker slot.
  - Context menus: Animate ▸ = `slides.animate.addBuild {kind: in|action|out}`,
    `copyBuilds`, `pasteBuilds`, `deleteBuilds`; *Copy chart as image* =
    `slides.chart.copyAsImage` (new id); *Edit text* = `slides.element.activate`; *Remove link*
    = `slides.element.removeLink`; the element menu keeps only the kind additions of the
    selected kind.
  - Additional registered ids: `slides.slide.setBackground`, `slides.slide.applyBackgroundToAll`,
    `slides.slide.setHideMasterElements`, `slides.deck.setAppearance` (Slide tab),
    `slides.prefs.set` / `slides.presenter.set` (settings, MCP-operable),
    `slides.nav.goToSlide {slideId? | index?}` (without arguments it opens §13.10's dialog).
  - §13.10 is a `WonkyDialogSpec` with a select of all slides ("4 · Our mission — Intro"), not
    a fuzzy-search list; the palette finds the command *Go to slide…* (the shell has no
    palette providers). The shell's dialog description now carries `optionLabels`.
  - §13.16 has **four sections**: *New presentations* (+ Charts), *Editing* (+ Spelling),
    *Animations & code*, *Presenting* (`/settings/app/presentations|editing|animations|presenting`);
    keys and defaults in `SlidesUserDefaults` (A-04-2 + `defaultTransitionMs`; presenter keys
    `layout`, `notesSize`, `timerMode`, `timerTargetMinutes`, `laserColor`,
    `startFullscreen`, `startWithPresenterView`, `showSkippedInPresenter`). The snapping and
    *Collaborator cursors* View toggles change these synced settings. *This presentation*
    (`Deck.presentJson`) is SL-19's.
  - §16: the narrow navigator drawer opens from a button at the canvas' top-left (the title
    row has no app slot on the left); the 1,200–1,440 px "inspector collapses to a tab strip
    when a side panel opens" is not built (`TODO.md`). Below 600 px the status bar shows only
    the position and zoom; below 400 px *Present* has no chevron (its items are in View ›
    Present). Suite changes for 360 px: the menubar strip scrolls horizontally, and the title
    row hides *Star*/*Move* below 480 px (both stay in File).
- **Child routes** `/p/:uuid/present|print|history` show a *Coming soon* page with *Back to the
  presentation* until SL-19/SL-20/SL-39.
- **`mcpUiTools`** is empty (SL-42); the shared `ui.*` tools cover the chrome (menu tree,
  commands, dialogs, `ui.get_state` with the editor's `describeState`).

---

## 19.1 As built (SL-15): images and tables

- Insert › Image ▸ and Insert › Table ▸, Format › Image ▸ / Table ▸, the toolbar's Image and
  Table sections, the image and `context.table` context menus and Inspector › Image / Table /
  Cell are real (03 §6.12). Without values from the UI, `slides.image.adjust`,
  `slides.table.setCellFill`, `setBorders`, `setCellAlign` and `setOptions` open the inspector
  section; `slides.image.mask` opens a mask dialog (`dialog.slides.imageMask`, a select of the
  basic shapes — not a gallery submenu); `slides.insert.image` without a source opens
  `dialog.slides.imageSource`; *By URL* is `dialog.slides.imageUrl` (§13.2 without the preview);
  *From Wonky Drive* is `dialog.slides.imageDrive` (recent image files and search, MCP-operable);
  the palette's `slides.insert.table` asks rows/columns (`dialog.slides.insertTable`).
- New command ids: `slides.image.cropApply` / `cropCancel` (Enter/Esc, `slidesCrop`),
  `slides.image.retryUpload`, `slides.image.removeNotUploaded`, `slides.table.resizeAxes`,
  `slides.table.setCellPadding` (03 §19), `slides.table.clearCells`, `slides.table.selectCells`,
  `slides.table.select{Left,Right,Up,Down}`, `slides.table.extend{Left,Right,Up,Down}`,
  `slides.table.nextCell` / `previousCell`, `slides.table.editCell`,
  `slides.table.clearCellSelection` (the `slidesTable` scope). The menus' existing args are
  kept: `slides.table.insertRow {below}`, `insertColumn {right}`.

## 20. As built (SL-16)

The navigator and slide groups of §5, the speaker notes pane of §8 and the grid view of §9 are
built (Slides 12 SL-16).

- **Folders.** `features/navigator/` (no separate `groups/` folder: group behavior is the
  navigator's): `navigator_model.dart` (`buildNavRows` — group headers, slides, the empty
  group's drop zone, collapsed groups folded; `NavSelection` — selected groups + loose slides;
  `NavigatorOps` — moves of mixed selections as units in visible order (runs of adjacent
  units become one `MoveSlides`/`MoveGroups`), no-op detection, the ⌘↑/⌘↓ rules of §5.7 and
  the `to` vocabulary), `navigator_drop.dart` (`resolveNavDrop`, §5.10), `navigator_controller.dart`
  (`navigatorOf(editor)`: collapse state, rows, focus row and Shift anchor, click/keyboard
  selection, type-ahead, inline rename, insertion caret, live drag), `slide_navigator.dart`
  (`SlideNavigator`), `nav_thumbnail.dart`, `navigator_clipboard.dart`, `navigator_dialogs.dart`
  (§13.4 *Delete group*, *Add to group ▸ Choose a group…*), `deck_renderer.dart` (thumbnails
  draw with the canvas' `SlideRenderer`, else a shared one); `features/grid_view/`
  (`grid_layout.dart` pure geometry + drop resolution, `slide_grid_view.dart`);
  `features/notes/` (`notes_pane.dart`, `notes_edit_controller.dart`, `notes_view.dart`);
  `commands/navigator_commands.dart`. The SL-11 shells (`navigator_shell.dart` now only
  re-exports `OpenContextMenu`, `notes_pane.dart`, `GridViewShell`) are gone.
- **Commands.** Real: `slides.slide.new {layoutId?, after?, inGroup?, groupId?}` (insertion
  point, else after the current slide in its group; selects the title placeholder),
  `slides.slide.duplicate|delete|toggleSkip|move`, every `slides.group.*` of §5.13 plus
  `slides.group.rename`, `slides.group.move`, `slides.group.toggleCollapsed`,
  `slides.group.selectSlides`. Additions: `slides.slide.move` takes `groupIds` and
  `copy: true` (the Alt-drop: a same-deck `PasteSlides` at the target) — one drop is one
  command, so one undo step; `slides.nav.selectAllSlides` (⌘A in the navigator scope),
  `slides.navigator.copy|cut|paste` (⌘C/⌘X/⌘V in the navigator scope; the shell's Edit menu
  and context-menu `shell.edit.*` reach them through `DeckDocumentController` whenever the
  navigator owns the clipboard: the navigator or grid has focus, or nothing is selected on the
  canvas and no text/notes are edited); `slides.notes.zoom {percent}` (device pref
  `slides.notes.zoom`). Navigator-scope bindings: Delete/Backspace, ⌘D, ⌘↑/⌘↓ (and ⌘←/⌘→ in
  the grid), ⇧⌘↑/⇧⌘↓, ⌘G/⇧⌘G, F2; ↑/↓/Home/End/←/→/Enter/Esc and type-ahead are handled by
  the navigator widget (not commands). Delete with selected groups opens §13.4 for UI
  invocations; agents delete the groups with their slides (the slides count as selected) or
  call `slides.group.delete {withSlides}` (default false). Without ids, commands act on the
  navigator selection; group commands fall back to the current slide's group.
- **Group creation.** New groups are placed at the first slide's position, or right after its
  group when that slide is grouped (core: `CreateGroup.target`, which also makes the empty
  *New group* of §11.7 possible). Title: the lowest free "Group n" (planner). Color: the cycle
  color after the previous group's (blue when there is none) — never the previous group's.
- **Collapse state** is `collapsedGroups` (+ `gridThumbSize`) of `LocalViewState` under
  `slides.view.<deckId>` in the user store (merged with other keys), not synced, not
  undoable. A current slide set from elsewhere expands its group; one restored inside a
  collapsed group too.
- **Drag and drop.** Pointer tracking on the list (4 px threshold, mouse); rows have fixed
  heights (`itemExtentBuilder`), so indicators are computed from geometry; the ghost (stacked
  first slide + "3 slides" / "Intro · 5 slides", "+" when Alt is held) follows the pointer
  inside the navigator; dragged rows are dimmed (not collapsed). Auto-scroll within 32 px of
  the edges; Esc cancels. A click on the 3 px gap between two rows sets the insertion caret.
- **Speaker notes.** Read-only rich rendering of the notes subset; editors click (or Enter on
  the focused pane) to edit with super_editor and SL-13's `SlidesDeltaMapper`; writes after
  300 ms idle, on blur and on slide change as one coalesced `slides.rows` step per burst
  (`recordTypingStep`, key `slides.notes:<slideId>`); Mod+Z/⇧Mod+Z go to the shell's stack
  (pending typing written first); external changes are patched into the document. Mini toolbar
  in the handle row while editing: bold, italic, underline, bulleted/numbered list, link
  (`WonkyDialogSpec` `dialog.slides.notesLink`); Mod+B/I/U.
- **Grid view.** Sections laid out by `GridLayout` (pure), virtualized by the scroll offset;
  the size slider (120–480 px) is clamped to the view's width; ↑/↓ move to the nearest item of
  the previous/next line, ←/→ along the order; double-click/Enter opens Normal view.
- **Deviations.** No build badges yet (SL-30; comment badges: SL-38, at the bottom left of the
  thumbnail — 09 §3.7; presence dots: SL-21), no notes soft lock
  (SL-21) — `TODO.md`. (File re-homing on cross-deck paste, the system clipboard and the
  paste options chip: SL-18, 03 §12 "As built (SL-18)".)
- **Text (SL-13).** The Format › Text, Text style, Align & indent, Line & paragraph spacing,
  Bullets & numbering and Text fitting items, the contextual *Text* toolbar controls (04 §6.2:
  style and font dropdowns, a size field, color and highlight split buttons with the color
  picker, align/lists/line-spacing dropdowns) and Inspector › Text are real; new command ids
  `slides.format.letterSpacing`, `slides.format.insets`, `slides.text.removeLink`. The link
  popover of §13.5 is the `WonkyDialogSpec` `dialog.slides.link` (target select + address),
  not a custom popover with tabs. *Restart numbering* (`slides.format.listStart`) asks for the
  start number. Details: 03 §6.2.1.
