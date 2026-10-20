# Sheets 04 · Screens, Menus, Toolbar, Panels and Dialogs

This spec defines every screen of Wonky Sheets, the **complete menubar** (mirroring Google
Sheets), the toolbar, the sheet tab bar, context menus, side panels, dialogs, the status bar and
light/dark grid colors. It is the **canonical registry of menu-bound command ids**: specs that
implement the behavior (05–12) must use the ids listed here (or update this file when they need
to change one).

Behavior of grid interactions lives in [03-grid-and-editing.md](03-grid-and-editing.md);
formatting semantics in [06-formatting.md](06-formatting.md). Shared shell pieces (header, menus
framework, command palette, overlays) come from suite
[03-app-shell-and-navigation.md](../03-app-shell-and-navigation.md) and
[02-design-system.md](../02-design-system.md).

## 0. Conventions

- Shortcut columns: **macOS** uses ⌘ ⌥ ⇧ ⌃ glyphs; **Win/Linux** uses `Ctrl`, `Alt`, `Shift`.
  Browser-reserved chords are never bound (suite 08 §1.2). "—" = no default shortcut.
- **Enabled** column uses these predicates: `edit` = user role ≥ Editor and the spreadsheet is
  loaded; `view` = always; `sel1` = single range selection; `rows` / `cols` = whole rows /
  columns selected; `hasFilter` = sheet has a basic filter; `canDownload` = role ≥ Editor or
  owner allows non-editors to download (suite 06 §1). All mutating items are disabled for
  viewers/commenters with tooltip "You have view access".
- **Spec** column points to where behavior is specified: 03, 05–12 in this folder; "shell" =
  suite specs.
- Every menu is generated from a declarative `MenuSpec` (suite 02 §4.3) so that the same tree
  feeds `WonkyMenubar`, the macOS `PlatformMenuBar`, the command palette menu paths and MCP
  `ui.get_menu_tree`.
- Dynamic labels: `{n}` = count derived from the selection; `{rows}` = "row 5" / "rows 5 – 7";
  `{cols}` = "column B" / "columns B – D". Labels are computed by the command's `title()`.

```dart
// wonky_sheets/lib/config/menus/sheets_menu_spec.dart
final sheetsMenuSpec = MenuSpec.root([
  MenuSpec.submenu('file', 'File', [
    MenuSpec.submenu('file.new', 'New', [
      MenuSpec.command('shell.drive.newSpreadsheet'),
      MenuSpec.command('shell.drive.newDocument'),
      MenuSpec.command('shell.drive.newFromTemplate'),
    ]),
    MenuSpec.command('shell.nav.quickSwitcher', label: 'Open'),
    // …
  ]),
  // edit, view, insert, format, data, tools, extensions, help
]);
```

---

## 1. Screen inventory

| Route (suite 03 §2) | Screen | Class | Notes |
|---------------------|--------|-------|-------|
| `/` and drive routes | Home (v2: **only** spreadsheets and folders that contain them) | shell `DriveHomeScreen` with `SheetsAppConfig.homeScope = HomeScope.kind(spreadsheet)` | §12 |
| `/new?folder=&template=`, `/import?file=<fileItemUuid>` (v2) | Create a spreadsheet (client file UUID, offline-first) / import a Drive file with §11.15 | shell `NewItemRoutePage` (default `newItemRoute` → `SheetsAppConfig.createItem`), `ImportRoutePage` + `importDriveFileAsSpreadsheet` (`features/import/drive_file_import.dart`) | §12, Drive 02 §7.2 |
| `/templates` | Template gallery (Sheets categories) | shell | §12 |
| `/s/:uuid` (`?sheet=&range=&comment=`) | **Spreadsheet editor** | `SheetEditorScreen` | §2 |
| `/s/:uuid` while opening | "Opening spreadsheet…" (no percentage; viewport-first, [03 §2.8](03-grid-and-editing.md)); offline and not on the device: "This spreadsheet isn’t available offline" | `SpreadsheetLoadingView` | Skeleton grid + indeterminate `ShadProgress` |
| `/s/:uuid/history` | Version history (full-screen) | `SheetsVersionHistoryScreen` | [10](10-collaboration-history.md) |
| `/s/:uuid/print` | Print / PDF preview | `SheetsPrintPreviewScreen` | [11](11-import-export-print.md) |
| `/s/:uuid/script` | Script editor (full-screen) | `ScriptEditorScreen` | [09](09-scripting.md) |
| `/settings/app/defaults` (v2; `/settings/sheets` redirects) | Sheets settings › Defaults (user defaults) | app settings section | §11.24 |
| No access / not found | shell | shell | |

## 2. Spreadsheet editor layout

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│ [▦] Q3 Budget ☆ 📁 ☁ Saved            (A)(B)(+2)  💬3  [🔒 Share]  (me)                │ row 1 (48)
│ File Edit View Insert Format Data Tools Extensions Help                                   │ row 2 (32)
│ ↶ ↷ 🖨 🖌 100%▾ │ $ % .0 .00 123▾ │ Inter▾ │ − 10 + │ B I S A │ ◧ ⊞▾ ⊟▾ │ ≡▾ ⊥▾ ↵▾ ⟲▾ │ 🔗 💬 📊 ⏷▾ Σ▾ │     │ row 3 (40)
├────────────┬────┬───────────────────────────────────────────────────────────┬────┬───┤
│ B4       ▾ │ fx │ =SUM(B1:B3)                                                │ ✨ │ ⌄ │ formula bar (30)
├───┬────────┴────┴───────────────────────────────────────────────────────────┴────┴───┤──────────────┐
│   │  A       B       C       D  …                                                     │ Side panel   │
│ 1 │                                                                                    │ (WonkySplit- │
│ 2 │                 GRID (03)                                                          │  View)       │
│ … │                                                                                    │              │
├───┴────────────────────────────────────────────────────────────────────────────────────┤              │
│ + ≡ │ Sheet1 ▾ │ Budget ▾ │ ●Data ▾ │ ◂ ▸                     ✨Explore   Sum: 1,234 ▾ │ tab bar (36) │
├──────────────────────────────────────────────────────────────────────────────────────────┴──────────────┤
│ Enter · Sheet1 1,000×26 · 26,000 / 1,000,000 cells                                 − 100% +  ▣        │ status bar (24)
└─────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

- Rows 1–3 follow suite 03 §3.1. Title row: app icon (Sheets product icon, → Home), `DocumentTitleField`
  (rename = `shell.drive.rename`, 1 step on the shell stack), star, move, `SyncStatusIndicator`,
  `PresenceAvatarStack`, (M12) *Bugs & improvements* icon button (`shell.board.report`, suite 03
  §3.1/§3.4; replaced *Report a bug*), comments button (badge = open threads, toggles Comments panel), **Share**,
  account menu. No history or ✨ Assistant buttons: those are reached through the side panel
  host's icon rail (suite 03 §3.1) and their commands (`sheets.history.open`,
  `shell.ai.togglePanel`).
- Rows 1–3 are always shown (suite 03 §3.1: no compact mode or full screen).
- Viewer/commenter mode: toolbar shows only Print, Zoom, Filter views (temporary),
  and a `ShadBadge` "View only" (or "Comment only") with *Request edit access*.
- Side panel host = `WonkySplitView` (suite 02 §4.5); panels in §10.
- Folder layout:

```
lib/
  config/
    menus/sheets_menu_spec.dart            # MenuSpec tree (§3)
    menus/context_menu_specs.dart          # cell/row/column/tab/object menus (§9)
    toolbar/sheets_toolbar_spec.dart       # ToolbarSpec (§4)
    panels/sheets_panels.dart              # SidePanelSpec registry (§10)
    routes.dart                            # /s/:uuid… routes
  features/
    sheet_editor/                          # SheetEditorScreen, header composition (03 §1)
    menus/                                 # SheetsMenubar (WonkyMenubar instance), dynamic label helpers
    toolbar/                               # SheetsToolbar + custom controls (BorderPicker, NumberFormatMenu, ZoomSelect…)
    tab_bar/                               # SheetTabBar, SheetTab, AllSheetsMenu, TabRenameField
    status/                                # SheetsStatusBar, SelectionStatsButton, CellLimitIndicator
    dialogs/                               # one file per dialog (§11), each a WonkyDialogSpec or McpDescribableDialog
    panels/                                # panel shells; panel bodies live in their feature folders
    explore/                               # ExplorePanel (with 12)
    home/                                  # SheetsHomeConfig, thumbnails (§12)
```

---

## 3. Menubar

### 3.1 File

| Item | Command id | macOS | Win/Linux | Enabled | Spec |
|------|-----------|-------|-----------|---------|------|
| New ▸ Spreadsheet | `shell.drive.newSpreadsheet` | ⌥⌘N (desktop ⌘N) | Ctrl+Alt+N | view | shell 05 |
| New ▸ Document | `shell.drive.newDocument` | — | — | view | shell 05 |
| New ▸ Presentation (v2) | `shell.file.new {kind: presentation}` (opens Wonky Slides' `/new` in this tab) | — | — | view | suite 03 §3.3 |
| New ▸ From template… | `shell.drive.newFromTemplate` | — | — | view | shell 05 |
| Open… | `shell.nav.quickSwitcher` | ⌘O | Ctrl+O | view | shell 03 |
| Import… | `sheets.file.import` | — | — | view (some locations need edit) | [11](11-import-export-print.md), §11.15 |
| Make a copy… | `shell.drive.makeCopy` | — | — | canDownload | shell 05 |
| — | | | | | |
| Share ▸ Share with others | `shell.sharing.open` | — | — | view | shell 06 |
| Share ▸ Copy link | `shell.sharing.copyLink` | — | — | view | shell 06 |
| Download ▸ Microsoft Excel (.xlsx) | `sheets.file.download {format: xlsx}` | — | — | canDownload | 11 |
| Download ▸ OpenDocument (.ods) | `sheets.file.download {format: ods}` | — | — | canDownload | 11 (P1) |
| Download ▸ PDF (.pdf) | `sheets.file.download {format: pdf}` → opens print preview | — | — | canDownload | 11 |
| Download ▸ Web page (.html, zipped) | `sheets.file.download {format: html}` | — | — | canDownload | 11 (P1) |
| Download ▸ Comma-separated values (.csv, current sheet) | `sheets.file.download {format: csv}` | — | — | canDownload | 11 |
| Download ▸ Tab-separated values (.tsv, current sheet) | `sheets.file.download {format: tsv}` | — | — | canDownload | 11 |
| — | | | | | |
| Rename | `shell.drive.rename` (focuses title field) | — | — | edit | shell 02 §4.15 |
| Move… | `shell.drive.move` | — | — | edit | shell 05 |
| Add shortcut to Drive | `shell.drive.addShortcut` | — | — | view | shell 05 |
| Move to trash | `shell.drive.trash` | — | — | owner/editor | shell 05 |
| — | | | | | |
| Version history ▸ Name current version | `sheets.history.nameCurrentVersion` | — | — | edit | 10 |
| Version history ▸ See version history | `sheets.history.open` | ⌥⇧⌘H | Ctrl+Alt+Shift+H | edit | 10 |
| Make available offline ✓ | `shell.drive.toggleOffline` | — | — | view | suite 12, 17 part 6 §2.5 |
| Details | `shell.drive.details` | — | — | view | shell 05 |
| Settings | `sheets.file.settings` | — | — | edit (view: read-only) | §11.1 |
| — | | | | | |
| Print | `sheets.print.open` | ⌘P | Ctrl+P | canDownload | 11 |

No "Email" item (out of scope).

### 3.2 Edit

> **As built.** The menubar uses the shell's `shell.edit.undo/redo/cut/copy/paste/selectAll`
> (suite 08 §5: apps contribute behavior through the document controller, which runs
> `sheets.edit.cut/copy/paste` and `sheets.select.all`); `sheets.edit.undo/redo` exist as
> aliases (MCP, and the `grid`-scope Mod+Z/Mod+Shift+Z bindings, 03 §8.3).
> View › Mode uses `sheets.mode.editing` / `sheets.mode.viewing`. Items of features that are
> not built yet are registered as disabled placeholder commands
> (`commands/data_commands.dart` `placeholderCommands`); the feature replaces the handler.

| Item | Command id | macOS | Win/Linux | Enabled | Spec |
|------|-----------|-------|-----------|---------|------|
| Undo *label* | `sheets.edit.undo` | ⌘Z | Ctrl+Z | stack non-empty | suite 08 |
| Redo *label* | `sheets.edit.redo` | ⇧⌘Z | Ctrl+Y, Ctrl+Shift+Z | redo non-empty | suite 08 |
| Undo history… | `sheets.edit.undoHistory` | — | — | stack non-empty | suite 08 §3.5 |
| — | | | | | |
| Cut | `sheets.edit.cut` | ⌘X | Ctrl+X | edit, sel1 | 03 §12 |
| Copy | `sheets.edit.copy` | ⌘C | Ctrl+C | view (canDownload for non-editors), sel1 | 03 §12 |
| Paste | `sheets.edit.paste` | ⌘V | Ctrl+V | edit | 03 §12 |
| Paste special ▸ Values only | `sheets.edit.pasteSpecial {mode: values}` | ⇧⌘V | Ctrl+Shift+V | edit | 03 §12.4 |
| Paste special ▸ Format only | `… {mode: format}` | ⌥⌘V | Ctrl+Alt+V | edit | |
| Paste special ▸ Formula only | `… {mode: formulas}` | — | — | edit + internal clip | |
| Paste special ▸ Conditional formatting only | `… {mode: conditionalFormatting}` | — | — | edit + internal clip | |
| Paste special ▸ Data validation only | `… {mode: dataValidation}` | — | — | edit + internal clip | |
| Paste special ▸ Column widths only | `… {mode: columnWidths}` | — | — | edit + internal clip | |
| Paste special ▸ Transposed | `… {mode: transposed}` | — | — | edit | |
| Paste special ▸ All except borders | `… {mode: allExceptBorders}` | — | — | edit | |
| Paste special ▸ Paste special… | `sheets.edit.pasteSpecialDialog` | — | — | edit | §11.6 |
| — | | | | | |
| Move ▸ Row up / Rows up | `sheets.rows.moveUp` | — | — | edit, first row > 0 | 03 §13.4 |
| Move ▸ Row down | `sheets.rows.moveDown` | — | — | edit | |
| Move ▸ Column left | `sheets.cols.moveLeft` | — | — | edit | |
| Move ▸ Column right | `sheets.cols.moveRight` | — | — | edit | |
| Delete ▸ Values | `sheets.edit.clearValues` | ⌫ / Del | Delete | edit | 03 §7.2 |
| Delete ▸ {rows} | `sheets.rows.delete` | — | — | edit | 03 §13.2 |
| Delete ▸ {cols} | `sheets.cols.delete` | — | — | edit | |
| Delete ▸ Cells and shift left | `sheets.cells.deleteShiftLeft` | — | — | edit, sel1 | 03 §13.3 |
| Delete ▸ Cells and shift up | `sheets.cells.deleteShiftUp` | — | — | edit, sel1 | |
| Delete ▸ Notes | `sheets.notes.clear` | — | — | edit, any note in selection | 03 §14.5 |
| — | | | | | |
| Find and replace | `sheets.find.openReplace` | ⇧⌘H (⌘H hides the app on macOS) | Ctrl+H | view (replace needs edit) | [07](07-data-tools.md) |

`Mod+F` (`sheets.find.open`) opens the inline find bar and is listed only in the shortcuts dialog
(Google parity).

### 3.3 View

| Item | Command id | macOS | Win/Linux | Enabled | Spec |
|------|-----------|-------|-----------|---------|------|
| Show ▸ Formula bar ✓ | `sheets.view.toggleFormulaBar` | — | — | view | 03 §9 |
| Show ▸ Gridlines ✓ | `sheets.view.toggleGridlines` | — | — | edit (sheet property) | 03 §2.4 |
| Show ▸ Formulas ✓ | `sheets.view.toggleFormulas` | ⌃\` | Ctrl+\` | view | 03 §2.5 |
| Show ▸ Protected ranges ✓ | `sheets.view.toggleProtectedRanges` | — | — | view | 03 §16 |
| — | | | | | |
| Freeze ▸ No rows | `sheets.view.freezeRows {count: 0}` | — | — | edit | 03 §4 |
| Freeze ▸ 1 row / 2 rows | `sheets.view.freezeRows {count: 1\|2}` | — | — | edit | |
| Freeze ▸ Up to row {N} | `sheets.view.freezeRows {count: N}` (N = active row) | — | — | edit, N ≥ 1 | |
| Freeze ▸ No columns / 1 column / 2 columns / Up to column {X} | `sheets.view.freezeColumns {count}` | — | — | edit | |
| Group ▸ Group {rows} | `sheets.group.groupRows` | ⌥⇧→ (rows selected) | Alt+Shift+→ | edit, rows | [07](07-data-tools.md) |
| Group ▸ Group {cols} | `sheets.group.groupColumns` | ⌥⇧→ (cols selected) | Alt+Shift+→ | edit, cols | 07 |
| Group ▸ Ungroup {rows}/{cols} | `sheets.group.ungroupRows` / `…Columns` | ⌥⇧← | Alt+Shift+← | edit, in group | 07 |
| Group ▸ Expand all row groups / Collapse all row groups | `sheets.group.expandAll {dimension: rows}` / `collapseAll` | — | — | edit | 07 |
| Group ▸ Expand all column groups / Collapse all column groups | same `{dimension: columns}` | — | — | edit | 07 |
| Comments ▸ Show all comments | `sheets.comments.openPanel` | ⌥⌘⇧A | Ctrl+Alt+Shift+A | view (if comments visible) | 10 |
| Comments ▸ Hide comment indicators ✓ | `sheets.view.toggleCommentIndicators` | — | — | view | 03 §14.6 |
| Hidden sheets ({n}) ▸ *each hidden sheet* | `sheets.sheet.unhide {sheetId}` | — | — | edit, n > 0 | §6 |
| — | | | | | |
| Zoom ▸ 50 % / 75 % / 90 % / 100 % / 125 % / 150 % / 200 % | `sheets.view.zoom {percent}` | ⌘= / ⌘- (desktop) | Ctrl+= / Ctrl+- (desktop) | view | 03 §2.3 |
| Panels ▸ Comments / Assistant / Explore / Named ranges / … | `shell.panels.open {panelId}` | — | — | view | §10 |
| App theme ▸ System / Light / Dark (radio) | `shell.appearance.setTheme {mode}` | — | — | view | suite 02 §1 |
| Mode ▸ Editing / Viewing (radio) | `shell.view.setMode {mode}` | — | — | edit for Editing | shell 03 |

### 3.4 Insert

| Item | Command id | macOS | Win/Linux | Enabled | Spec |
|------|-----------|-------|-----------|---------|------|
| Cells ▸ Insert cells and shift right | `sheets.cells.insertShiftRight` | — | — | edit, sel1 | 03 §13.3 |
| Cells ▸ Insert cells and shift down | `sheets.cells.insertShiftDown` | — | — | edit, sel1 | |
| Rows ▸ Insert {n} row(s) above | `sheets.rows.insertAbove` | ⌥⌘= (rows sel.) | Ctrl+Alt+= | edit | 03 §13.1 |
| Rows ▸ Insert {n} row(s) below | `sheets.rows.insertBelow` | — | — | edit | |
| Columns ▸ Insert {n} column(s) left | `sheets.cols.insertLeft` | ⌥⌘= (cols sel.) | Ctrl+Alt+= | edit | |
| Columns ▸ Insert {n} column(s) right | `sheets.cols.insertRight` | — | — | edit | |
| Sheet | `sheets.sheet.add` | ⇧F11 | Shift+F11 | edit, < 200 sheets | §6 |
| — | | | | | |
| Chart | `sheets.chart.insert` | — | — | edit | [08](08-charts-and-objects.md) |
| Pivot table | `sheets.insert.pivotTable` | — | — | edit | [07](07-data-tools.md) |
| Image ▸ Insert image in cell | `sheets.image.insertInCell` | — | — | edit | 08 |
| Image ▸ Insert image over cells | `sheets.image.insertOverCells` | — | — | edit | 08 |
| Drawing (P2) | `sheets.drawing.insert` | — | — | edit | 08 |
| — | | | | | |
| Function ▸ SUM / AVERAGE / COUNT / MAX / MIN | `sheets.insert.function {name}` | — | — | edit | 03 §8.7, [05](05-formula-engine.md) |
| Function ▸ All ▸ *category* ▸ *function* (Array, Database, Date, Engineering, Filter, Financial, Info, Logical, Lookup, Math, Operator, Parser, Statistical, Text, Web-free; plus Named functions, Custom functions) | `sheets.insert.function {name}` | — | — | edit | 05 |
| Function ▸ Learn more about functions… | `sheets.help.functionList` | — | — | view | §11.20 |
| — | | | | | |
| Link | `sheets.insert.link` | ⌘K | Ctrl+K | edit | 03 §14.4 |
| Checkbox | `sheets.insert.checkbox` | — | — | edit | 03 §14.1, 07 |
| Dropdown | `sheets.insert.dropdown` | — | — | edit | 03 §14.2, 07 |
| Emoji (P2) | `sheets.insert.emoji` | — | — | edit | Emoji picker popover |
| Smart chips ▸ People / Date / Dropdown / File (P2) | `sheets.insert.smartChip {kind}` | — | — | edit | 03 §14.3 |
| — | | | | | |
| Comment | `shell.comments.create` | ⌥⌘M | Ctrl+Alt+M | comment | 10 |
| Note | `sheets.notes.insert` | ⇧F2 | Shift+F2 | edit | 03 §14.5 |

`Mod+K` is bound to Insert link in the `grid`/`cellEditor` scopes (Google parity); the command
palette is therefore opened with **`Mod+Shift+P`** inside Sheets (suite 08 binds both; the more
specific scope wins).

### 3.5 Format

| Item | Command id | macOS | Win/Linux | Enabled | Spec |
|------|-----------|-------|-----------|---------|------|
| Theme | `sheets.theme.openPanel` | — | — | edit | [06 §13](06-formatting.md#13-spreadsheet-theme) |
| Number ▸ Automatic | `sheets.format.numberFormat {preset: automatic}` | — | — | edit | 06 §5 |
| Number ▸ Plain text | `… {preset: plainText}` | — | — | edit | |
| Number ▸ Number `1,000.12` | `… {preset: number}` | ⇧⌘1 | Ctrl+Shift+1 | edit | |
| Number ▸ Percent `10.12%` | `… {preset: percent}` | ⇧⌘5 | Ctrl+Shift+5 | edit | |
| Number ▸ Scientific `1.01E+03` | `… {preset: scientific}` | ⇧⌘6 | Ctrl+Shift+6 | edit | |
| Number ▸ Accounting `$ (1,000.12)` | `… {preset: accounting}` | — | — | edit | |
| Number ▸ Financial `(1,000.12)` | `… {preset: financial}` | — | — | edit | |
| Number ▸ Currency `$1,000.12` | `… {preset: currency}` | ⇧⌘4 | Ctrl+Shift+4 | edit | |
| Number ▸ Currency rounded `$1,000` | `… {preset: currencyRounded}` | — | — | edit | |
| Number ▸ Date `9/26/2008` | `… {preset: date}` | ⇧⌘3 | Ctrl+Shift+3 | edit | |
| Number ▸ Time `3:59:00 PM` | `… {preset: time}` | ⇧⌘2 | Ctrl+Shift+2 | edit | |
| Number ▸ Date time `9/26/2008 15:59:00` | `… {preset: dateTime}` | — | — | edit | |
| Number ▸ Duration `24:01:00` | `… {preset: duration}` | — | — | edit | |
| Number ▸ *recently used custom formats (≤ 5)* | `sheets.format.numberFormat {pattern}` | — | — | edit | |
| Number ▸ Custom currency | `sheets.format.openCustomCurrency` | — | — | edit | §11.4 |
| Number ▸ Custom date and time | `sheets.format.openCustomDateTime` | — | — | edit | §11.3 |
| Number ▸ Custom number format | `sheets.format.openCustomNumberFormat` | — | — | edit | §11.2 |
| Text ▸ Bold | `sheets.format.bold` | ⌘B | Ctrl+B | edit | 06 §6 |
| Text ▸ Italic | `sheets.format.italic` | ⌘I | Ctrl+I | edit | |
| Text ▸ Underline | `sheets.format.underline` | ⌘U | Ctrl+U | edit | |
| Text ▸ Strikethrough | `sheets.format.strikethrough` | ⇧⌘X | Alt+Shift+5 | edit | |
| Alignment ▸ Left / Center / Right | `sheets.format.hAlign {align}` | ⇧⌘L / ⇧⌘E / ⇧⌘R | Ctrl+Shift+L / E / R | edit | 06 §9 |
| Alignment ▸ Top / Middle / Bottom | `sheets.format.vAlign {align}` | — | — | edit | |
| Wrapping ▸ Overflow / Wrap / Clip | `sheets.format.wrap {strategy}` | — | — | edit | 06 §9.3 |
| Rotation ▸ None / Tilt up / Tilt down / Stack vertically / Rotate up / Rotate down / Custom angle… | `sheets.format.rotation {angle}` (0, 45, -45, 255, 90, -90, custom) | — | — | edit | 06 §9.4 |
| Font size ▸ 6 7 8 9 10 11 12 14 18 24 36 | `sheets.format.fontSize {size}` | — | — | edit | 06 §6 |
| Merge cells ▸ Merge all / Merge horizontally / Merge vertically / Unmerge | `sheets.format.merge {mode: all\|horizontal\|vertical}` / `sheets.format.unmerge` | — | — | edit, multi-cell | 06 §10 |
| Convert to table (P2) | `sheets.format.convertToTable` | ⌥⌘T | Ctrl+Alt+T | edit | 07 (P2) |
| — | | | | | |
| Conditional formatting | `sheets.cf.openPanel` | — | — | edit | 06 §15 |
| Alternating colors | `sheets.banding.openPanel` | — | — | edit | 06 §14 |
| — | | | | | |
| Clear formatting | `sheets.format.clear` | ⌘\\ | Ctrl+\\ | edit | 06 §3 |

### 3.6 Data

All behaviors in [07-data-tools.md](07-data-tools.md) unless noted.

| Item | Command id | macOS | Win/Linux | Enabled |
|------|-----------|-------|-----------|---------|
| Sort sheet ▸ Sort sheet by column {X} (A to Z) | `sheets.data.sortSheet {colId, ascending: true}` | — | — | edit |
| Sort sheet ▸ Sort sheet by column {X} (Z to A) | `sheets.data.sortSheet {colId, ascending: false}` | — | — | edit |
| Sort range ▸ Sort range by column {X} (A to Z) / (Z to A) | `sheets.data.sortRange {range, colId, ascending}` | — | — | edit, sel1 multi-row |
| Sort range ▸ Advanced range sorting options | `sheets.data.openSortDialog` | — | — | edit, sel1 |
| — | | | | |
| Create a filter / Remove filter | `sheets.filter.toggle` | ⌥⇧⌘L | Ctrl+Alt+Shift+L | edit (viewers: disabled; use filter views) |
| Create filter view | `sheets.filterView.create` | — | — | view (temporary for viewers) |
| Change view ▸ *filter views list* / None | `sheets.filterView.activate {viewId?}` | — | — | view |
| Add a slicer (P2) | `sheets.slicer.add` | — | — | edit |
| — | | | | |
| Protect sheets and ranges | `sheets.protect.openPanel` | — | — | edit |
| Named ranges | `sheets.namedRanges.openPanel` | — | — | view (edit to change) |
| Named functions | `sheets.namedFunctions.openPanel` | — | — | view (edit to change) |
| Randomize range | `sheets.data.randomizeRange` | — | — | edit, sel1 |
| — | | | | |
| Column stats | `sheets.data.columnStats` | — | — | view |
| Data validation | `sheets.dv.openPanel` | — | — | edit |
| Data cleanup ▸ Cleanup suggestions (P2) | `sheets.cleanup.openSuggestions` | — | — | edit |
| Data cleanup ▸ Remove duplicates | `sheets.cleanup.openRemoveDuplicates` | — | — | edit, sel1 |
| Data cleanup ▸ Trim whitespace | `sheets.cleanup.trimWhitespace` | — | — | edit |
| Split text to columns | `sheets.data.splitTextToColumns` | — | — | edit, single column |
| Data extraction (P2) | `sheets.data.extraction` | — | — | edit |
| — | | | | |
| Analyze with AI | `sheets.ai.analyze` | — | — | view (AI enabled) |

### 3.7 Tools

| Item | Command id | macOS | Win/Linux | Enabled | Spec |
|------|-----------|-------|-----------|---------|------|
| Assistant | `shell.ai.togglePanel` | ⌘J | Ctrl+J | AI enabled | suite 10 |
| Explore | `sheets.explore.toggle` | ⌥⇧X | Alt+Shift+X | view | §7, 12 |
| Spelling ▸ Spell check / Personal dictionary (P2) | `sheets.tools.spellCheck` / `sheets.tools.personalDictionary` | — | — | edit | — |
| Autocomplete ✓ | `sheets.tools.toggleAutocomplete` | — | — | view | 03 §8.5 |
| Formula suggestions ✓ (AI inline) | `sheets.tools.toggleFormulaSuggestions` | — | — | view | 12 |
| Notification settings ▸ Comment notifications | `sheets.notifications.openSettings {itemUuid}` | — | — | view | 10 |
| Notification settings ▸ Notification rules (P2) | `sheets.notifications.openRules` | — | — | edit | 10 |
| Accessibility settings | `shell.settings.accessibility` | — | — | view | shell 03 |
| Keyboard shortcuts | `shell.help.shortcuts` | ⌘/ | Ctrl+/ | view | §11.19 |
| Sheets settings… (v2) | `shell.settings.openApp` | ⌘, (desktop) | — | view | §11.24 |
| Wonky Work settings… (v2) | `shell.settings.open {section: account}` | — | — | view | suite 04 §4 |

### 3.8 Extensions

| Item | Command id | macOS | Win/Linux | Enabled | Spec |
|------|-----------|-------|-----------|---------|------|
| Scripts ▸ Open script editor | `sheets.script.openEditor` | — | — | edit | [09](09-scripting.md) |
| Scripts ▸ Macros ▸ Record macro | `sheets.macro.record` | — | — | edit | 09 |
| Scripts ▸ Macros ▸ Import macro | `sheets.macro.import` | — | — | edit | 09 |
| Scripts ▸ Macros ▸ Manage macros | `sheets.macro.manage` | — | — | edit | 09 |
| Scripts ▸ Macros ▸ *each macro* | `sheets.macro.m<macroId hex>` | ⌥⇧⌘1…0 (slot) | Ctrl+Alt+Shift+1…0 | edit, scripts enabled | 09 |
| Scripts ▸ Triggers | `sheets.script.openTriggers` | — | — | edit | 09 |
| Scripts ▸ Executions | `sheets.script.openExecutions` | — | — | edit | 09 |
| Scripts ▸ Script settings | `sheets.script.openSettings` | — | — | edit, project | 09 §14.7 |
| *each script menu* (also top level after Extensions) | `sheets.script.runMenuItem` | — | — | view | 09 §16.1 |
| AI ▸ Suggest a formula | `sheets.ai.suggestFormula` | — | — | edit, AI | suite 10, 12 |
| AI ▸ Explain formula | `sheets.ai.explainFormula` | — | — | view, formula cell, AI | 12 |
| AI ▸ Fill with AI | `sheets.ai.fillRange` | — | — | edit, sel1, AI | 12 |
| AI ▸ Analyze data | `sheets.ai.analyze` | — | — | view, AI | 12 |
| MCP ▸ Copy MCP connection info | `shell.mcp.copyConnectionInfo` | — | — | view | suite 09 |

Note: the `Ctrl+Alt+Shift+<digit>` macro slots conflict with nothing in Sheets because border
shortcuts use `Alt+Shift+<digit>` (no Ctrl).

### 3.9 Help

| Item | Command id | macOS | Win/Linux |
|------|-----------|-------|-----------|
| Keyboard shortcuts | `shell.help.shortcuts` | ⌘/ | Ctrl+/ |
| Function list | `sheets.help.functionList` | — | — |
| Script API reference | `sheets.help.scriptApiReference` | — | — |
| — | | | |
| Bugs & improvements… (M12; replaces *Report a bug*, suite 03 §3.2) | `shell.board.report` | — | — |
| Browse Bugs & improvements (M12) | `shell.board.open` | — | — |
| What's new | `shell.help.whatsNew` | — | — |
| About | `shell.help.about` | — | — |

### 3.10 Menu behavior

- Opening: click, or `Alt+F/E/V/I/O/D/T/N/H` on Win/Linux, `⌃⌥F…` on macOS (suite 02 §4.3);
  Format uses `O`, Extensions `N`. Arrow keys traverse; type-ahead jumps.
- Only one menu is open at a time (suite 02 §4.2).
- Disabled items show a reason tooltip on hover (from `Command.isEnabled` reason).
- Checked items (`isChecked`) render ✓; radio groups render ●.
- macOS desktop (deferred, v2 is web only): `PlatformMenuBar` generated from the same spec
  (suite 03 §6); the in-window menubar is hidden when native menus are active.

---

## 4. Toolbar

`SheetsToolbar` is a `WonkyToolbar` (suite 02 §4.1). Items in order (left → right). **Priority**
drives overflow: when space is short, lowest-priority items move into the trailing "⋯" menu,
preserving groups (priority 1 = never hidden).

| # | Control | Widget | Command(s) | Tooltip (shortcut) | Prio |
|---|---------|--------|-----------|--------------------|------|
>>>

| 2 | Undo | `ToolbarButton` (long-press → undo history popover) | `sheets.edit.undo` | Undo (⌘Z) | 1 |
| 3 | Redo | `ToolbarButton` | `sheets.edit.redo` | Redo (⇧⌘Z / Ctrl+Y) | 1 |
| 4 | Print | `ToolbarButton` | `sheets.print.open` | Print (⌘P) | 6 |
| 5 | Paint format | `ToolbarToggleButton` (checked while armed; double-click = sticky) | `sheets.format.paintFormat {sticky}` | Paint format | 3 |
| 6 | Zoom | `ToolbarSelect` (50/75/90/100/125/150/200 + "Fit"?) | `sheets.view.zoom` | Zoom | 5 |
| — | separator | | | | |
| 7 | Format as currency | `ToolbarButton` ($) | `sheets.format.numberFormat {preset: currency}` | Format as currency | 4 |
| 8 | Format as percent | `ToolbarButton` (%) | `… {preset: percent}` | Format as percent | 4 |
| 9 | Decrease decimal places | `ToolbarButton` (.0←) | `sheets.format.decreaseDecimals` | Decrease decimal places | 4 |
| 10 | Increase decimal places | `ToolbarButton` (.00→) | `sheets.format.increaseDecimals` | Increase decimal places | 4 |
| 11 | More formats | `ToolbarDropdownButton` ("123 ▾") → `NumberFormatMenu` (same items as Format › Number) | `sheets.format.numberFormat` | More formats | 4 |
| — | separator | | | | |
| 12 | Font | `ToolbarDropdownButton` → `FontPicker` (suite 02 §4.11; sections Theme fonts / Recent / All bundled cell fonts; "More fonts" disabled — bundled only) | `sheets.format.fontFamily {family}` | Font | 3 |
| — | separator | | | | |
| 13 | Font size | `ToolbarNumberField` (− [10] +, dropdown of preset sizes on focus) | `sheets.format.fontSize {size}`, `sheets.format.decreaseFontSize` / `increaseFontSize` (⇧⌘, / ⇧⌘.) | Font size | 2 |
| — | separator | | | | |
| 14 | Bold | `ToolbarToggleButton` | `sheets.format.bold` | Bold (⌘B) | 1 |
| 15 | Italic | `ToolbarToggleButton` | `sheets.format.italic` | Italic (⌘I) | 1 |
| 16 | Strikethrough | `ToolbarToggleButton` | `sheets.format.strikethrough` | Strikethrough (⇧⌘X) | 2 |
| 17 | Text color | `ToolbarSplitButton` (A with color bar) → `WonkyColorPicker` (Reset = Automatic) | `sheets.format.textColor {color}` | Text color | 2 |
| — | separator | | | | |
| 18 | Fill color | `ToolbarSplitButton` (bucket with color bar) → `WonkyColorPicker` (Reset = None; *Alternating colors* link → panel) | `sheets.format.fillColor {color}` | Fill color | 2 |
| 19 | Borders | `ToolbarDropdownButton` → `BorderPicker` (§4.1) | `sheets.format.borders {…}` | Borders | 3 |
| 20 | Merge cells | `ToolbarSplitButton` (main = merge all/unmerge toggle) → Merge all / horizontally / vertically / Unmerge | `sheets.format.merge` / `unmerge` | Merge cells | 3 |
| — | separator | | | | |
| 21 | Horizontal align | `ToolbarDropdownButton` (icon reflects current) → icon row Left/Center/Right | `sheets.format.hAlign` | Horizontal align | 3 |
| 22 | Vertical align | dropdown → Top/Middle/Bottom | `sheets.format.vAlign` | Vertical align | 5 |
| 23 | Text wrapping | dropdown → Overflow/Wrap/Clip | `sheets.format.wrap` | Text wrapping | 4 |
| 24 | Text rotation | dropdown → None, Tilt up, Tilt down, Stack vertically, Rotate up, Rotate down, custom angle `WonkyNumberStepper` (−90…90) | `sheets.format.rotation` | Text rotation | 6 |
| — | separator | | | | |
| 25 | Insert link | `ToolbarButton` | `sheets.insert.link` | Insert link (⌘K) | 5 |
| 26 | Insert comment | `ToolbarButton` | `shell.comments.create` | Insert comment (⌥⌘M) | 5 |
| 27 | Insert chart | `ToolbarButton` | `sheets.chart.insert` | Insert chart | 6 |
| 28 | Create a filter | `ToolbarSplitButton` (funnel; main toggles basic filter) → filter views menu: Create new filter view, *saved views*, None | `sheets.filter.toggle`, `sheets.filterView.*` | Create a filter | 4 |
| 29 | Functions | `ToolbarDropdownButton` (Σ) → SUM, AVERAGE, COUNT, MAX, MIN, sep, categories ▸ (as Insert › Function) | `sheets.insert.function {name}` | Functions | 5 |
>>>


Toolbar state: toggles reflect the **active cell's** effective format (bold checked if the active
cell is bold); dropdowns show the active cell's value (font name, size, number format label
"123"). Selection with mixed values shows the active cell's value (Google behavior). When a cell
editor with a text selection is active, Bold/Italic/Strike/Underline/Text color/Link apply to
the selected run (03 §8.8) and other controls are disabled.

### 4.1 `BorderPicker` (app widget, `features/toolbar/border_picker.dart`)

Popover content, 2 columns:

```
┌──────────────────────────────┬──────────┐
│ ⊞ all    ┼ inner   ═ horiz.   ║ vert.   │  ✎ color ▾  │
│ ▢ outer  ▏left     ▔ top      ▕ right   │  ≡ style ▾  │
│ ▁ bottom ⊘ clear                         │             │
└──────────────────────────────┴──────────┘
```

- Left: 10 preset buttons: all, inner, horizontal, vertical, outer, left, top, right, bottom,
  clear. Right: border **color** (`WonkyColorPicker`, default Automatic = theme text color) and
  **style** menu (thin, medium, thick, dashed, dotted, double — drawn as line previews).
- Color/style selections persist for the session and apply to the next preset click.
- Click on a preset → `sheets.format.borders {preset, style, color}` (1 step). Mapping of presets
  to cell edges: [06 §8.3](06-formatting.md#8-borders).
- Keyboard: roving focus over the grid of presets, Enter applies.

### 4.2 Other custom toolbar controls

| Widget | Where | Package |
|--------|-------|---------|
| `NumberFormatMenu` (preset list with right-aligned live examples of the active cell's value) | toolbar 123 ▾ + Format › Number | app (`features/number_format/`) |
| `ZoomSelect` | toolbar | app (`ToolbarSelect` config) |
| `BorderPicker` | toolbar | app |
| `AlignIconMenu` (horizontal icon row menu) | toolbar | `wonky_ui` (generic `IconChoiceMenu`) |
| `RotationMenu` | toolbar | app |
| `FilterSplitButton` | toolbar | app |

---

## 5. Formula bar

Specified in [03 §9](03-grid-and-editing.md#9-formula-bar). Hidden via View › Show › Formula bar.

---

## 6. Sheet tab bar (`features/tab_bar/`)

```
┌───┬───┬───────────────┬────────────┬────────────┬───────────────┬──┬──┐ … ┌───────────┬──────────────────┐
│ + │ ≡ │ ▍Sheet1    ▾  │ Budget   ▾ │ ●Data    ▾ │ ⚠ Sheet2 (2) ▾│ ◂│ ▸│   │ ✨ Explore │ Sum: 1,234.00 ▾ │
└───┴───┴───────────────┴────────────┴────────────┴───────────────┴──┴──┘   └───────────┴──────────────────┘
```

| Element | Behavior | Command |
|---------|----------|---------|
| **+** Add sheet | Appends `SheetN` (next free number) after the active sheet and activates it | `sheets.sheet.add {afterSheetId?, name?}` (1 step) |
| **≡** All sheets | Menu listing all sheets (hidden ones greyed with "hidden" label), click activates (unhides if hidden, with confirm for editors) | `sheets.sheet.activate {sheetId}` |
| **Tab** | Name (ellipsized at 160 px), 3 px **color strip** at the bottom in `tabColor`, chevron ▾ opens the tab menu; active tab: `background` bg + bold + raised; inactive: `muted`; chart sheets show a chart icon; duplicate names (02 §3.1) show ⚠ with tooltip; collaborator dots (presence colors) for people on that sheet; protected sheets show 🔒 | click = `sheets.sheet.activate` |
| Rename | Double-click the tab → inline `ShadInput`; Enter/blur commits, Esc cancels; validation (01 §3) inline | `sheets.sheet.rename {sheetId, name}` (1 step) |
| Reorder | Drag a tab horizontally; drop indicator between tabs; auto-scroll the strip | `sheets.sheet.move {sheetId, beforeSheetId?}` (1 step, sortKey) |
| Scroll arrows ◂ ▸ | Visible when tabs overflow; scroll the strip by one tab; wheel scrolls too | — |
| Hidden count | When sheets are hidden, the ≡ button shows a small badge with the count | — |
| Keyboard | Mod+Shift+PgUp/PgDn activate previous/next (03 §7.1); tab strip is focusable with roving focus; Shift+F10 opens the tab menu | |

**Tab context menu** (right-click or ▾):

| Item | Command id | Enabled |
|------|-----------|---------|
| Delete | `sheets.sheet.delete {sheetId}` → confirm dialog §11.14 | edit, > 1 visible sheet |
| Duplicate | `sheets.sheet.duplicate {sheetId}` ("Copy of Sheet1", inserted after) | edit |
| Copy to ▸ New spreadsheet | `sheets.sheet.copyToNew {sheetId}` (creates a spreadsheet like *New*, [02 §4](02-data-model.md); toast with *Open spreadsheet*) | canDownload |
| Copy to ▸ Existing spreadsheet… | `sheets.sheet.copyToExisting {sheetId, targetItemUuid}` (drive picker dialog; target must be available locally or is subscribed first) | canDownload |
| Rename | `sheets.sheet.startRename` (inline field) | edit |
| Change color ▸ | `WonkyColorPicker` (Reset = none) → `sheets.sheet.setColor {sheetId, color?}` | edit |
| Protect sheet | `sheets.protect.openPanel {sheetId, mode: sheet}` | edit |
| Hide sheet | `sheets.sheet.hide {sheetId}` | edit, > 1 visible sheet |
| View comments | `sheets.comments.openPanel {scope: sheet}` | view |
| Move right / Move left | `sheets.sheet.moveRight` / `moveLeft` | edit, not last/first |
| Right-to-left ✓ (P2) | `sheets.sheet.setRightToLeft` | edit |

All sheet commands are one undo step (delete restores the sheet with all rows, cells and rules by
re-inserting the same ids).

**Mobile (T-1).** In the read-only mobile layout (suite 02 §6.1) the bar is 48 px tall
(`SheetTabBar.mobileHeight`) with 42 px tabs (`mobileTabHeight`) in 15 px text, and shows the
**≡** all-sheets menu (40 px) and the tabs only: no **+**, no tab menu (▾ or right-click), no
scroll arrows (the strip scrolls with a swipe), no Explore and no selection stats (there is no
cell selection, 03 §5). A tap activates a tab at once (no double-tap rename). The desktop bar is
unchanged.

---

## 7. Selection statistics and Explore

- **Selection stats button** (`SelectionStatsButton`, right of the tab bar): shows one aggregate
  of the current selection: `Sum`, `Average`, `Min`, `Max`, `Count` (non-empty), `Count numbers`.
  Default: `Sum` if the selection contains numbers, else `Count`. Click → `WonkyDropdownMenu`
  listing **all** six with their values (click one to make it the shown one; persisted per user
  `sheetsDefaults.selectionStat`); values formatted with the active cell's number format when all
  numbers share it. Hidden when the selection is a single cell. Computation per 03 §6.4 (shows a
  spinner for > 100k cells). *As built (CQ-41):* values and number formats are read from the
  engine (never through the grid's render cache), comparing formats stops once they differ;
  the button computes in steps of 50,000 cells (the first right after the 100 ms debounce, the
  rest in later event-loop turns, aborted by any selection or content change) and keeps the
  previous value until a large selection is done; Explore and MCP cap at 200,000 cells.
  Command: `sheets.stats.setShown {fn}` (—).
- **Explore** button (✨ Explore) toggles the Explore panel (`sheets.explore.toggle`): quick
  stats of the selection, suggested charts and pivot tables for the current data region (click to
  insert), and an "Ask a question about this data" box that hands off to the Assistant. Details in
  [12](12-mcp-and-ai.md).

## 8. Status bar (`features/status/`, suite 02 §4.13)

| Slot | Content |
|------|---------|
| Left | Editor mode indicator (Ready / Enter / Edit / Point, if enabled, 03 §8.1) · active sheet name and grid size "1,000 × 26" · **cell count** "26,000 / 1,000,000 cells" (`CellLimitIndicator`, turns `warning` at ≥ 80 %, `destructive` at ≥ 95 % with tooltip "This spreadsheet is close to the cell limit") · calculation status ("Calculating… 42 %" while the engine recalculates > 200 ms) |
| Center | offline storage warning (suite 12, IndexedDB fallback) |
| Right | Zoom (− [100 %] + and click → zoom menu) · View toggles: gridlines, formulas (icon toggles) |

The status bar contains only these Sheets items (suite 02 §4.13; no shell sync indicator or
theme toggle — the sync status is in the title row) and is always shown.

---

## 9. Context menus

All built with `ShadContextMenuRegion` + `WonkyDropdownMenu` items from `context_menu_specs.dart`
(also exposed via MCP `ui.get_menu_tree {menu: 'context.cell'}`).

### 9.1 Cell context menu (`context.cell`)

| Item | Command | Notes |
|------|---------|-------|
| Cut / Copy / Paste | `sheets.edit.cut` / `copy` / `paste` | shortcuts shown |
| Paste special ▸ | same items as Edit › Paste special | |
| — | | |
| Insert {n} row(s) above | `sheets.rows.insertAbove` | |
| Insert {n} column(s) left | `sheets.cols.insertLeft` | |
| Insert cells ▸ Shift right / Shift down | `sheets.cells.insertShiftRight` / `…Down` | |
| Delete {rows} | `sheets.rows.delete` | |
| Delete {cols} | `sheets.cols.delete` | |
| Delete cells ▸ Shift left / Shift up | `sheets.cells.deleteShiftLeft` / `…Up` | |
| — | | |
| Create a filter / Remove filter | `sheets.filter.toggle` | |
| Filter by cell value | `sheets.filter.byCellValue` | creates/extends the basic filter with "= value" on the column (07) |
| — | | |
| Conditional formatting | `sheets.cf.openPanel {range: selection}` | |
| Data validation | `sheets.dv.openPanel {range: selection}` | |
| — | | |
| View more cell actions ▸ Comment | `shell.comments.create` | |
| ▸ Insert note | `sheets.notes.insert` | |
| ▸ Insert link | `sheets.insert.link` | link cells also get *Copy link* `sheets.link.copy` in the link card |
| ▸ Smart chips (P2) | `sheets.insert.smartChip {kind?}` | as built: one item opening the chip menu at the cell (03 §14.3) |
| ▸ Explain formula (AI) | `sheets.ai.explainFormula` | formula cells |
| ▸ Protect range | `sheets.protect.openPanel {range: selection}` | |
| ▸ Define named range | `sheets.namedRanges.openPanel {create: selection}` | |
| ▸ Get link to this cell / range | `sheets.cell.copyLink` | |
| ▸ Randomize range | `sheets.data.randomizeRange` | |
| ▸ Show edit history | `sheets.history.showCellHistory` | [10](10-collaboration-history.md); single cell |
| ▸ Clear notes | `sheets.notes.clear` | |

Context variants: on a **pivot** cell, the top adds *Edit pivot table*, *Refresh*, *Show details*
(`sheets.pivot.drillDown`, value cells), *Create pivot group* (`sheets.pivot.groupSelection`,
when row/column labels of one field are selected), *Delete pivot table*; on a
**chart/image**, the object context menu from 08 replaces this one; on a **link** cell, *Open
link*, *Edit link*, *Remove link* are added at the top; on a **dropdown** cell, *Edit dropdown*.

### 9.2 Row header menu (`context.rowHeader`)

Cut, Copy, Paste, Paste special ▸ · Insert {n} rows above (`sheets.rows.insertAbove`), Insert {n}
rows below (`…insertBelow`) · Delete {rows} · Clear {rows} (`sheets.edit.clearAll`) · Hide {rows}
(`sheets.rows.hide`) · Resize {rows} (`sheets.rows.openResizeDialog`) · — · Group {rows}
(`sheets.group.groupRows`) / Ungroup · Create a filter · Conditional formatting · Data validation
· — · View more row actions ▸ Freeze up to row {N} (`sheets.view.freezeRows {N}`), Move row up/down,
Get link to this range, Define named range, Protect range, Fit to data (`sheets.rows.autoFit`).

### 9.3 Column header menu (`context.columnHeader`)

| Item | Command |
|------|---------|
| Cut / Copy / Paste / Paste special ▸ | |
| Insert {n} columns left / right | `sheets.cols.insertLeft` / `insertRight` |
| Delete {cols} | `sheets.cols.delete` |
| Clear {cols} | `sheets.edit.clearAll` |
| Hide {cols} | `sheets.cols.hide` |
| Resize {cols} | `sheets.cols.openResizeDialog` |
| — | |
| Create a filter | `sheets.filter.toggle` |
| Sort sheet A to Z / Z to A | `sheets.data.sortSheet {colId, ascending}` |
| — | |
| Conditional formatting | `sheets.cf.openPanel` |
| Data validation | `sheets.dv.openPanel` |
| Column stats | `sheets.data.columnStats {colId}` |
| Convert to dropdown | `sheets.insert.dropdown {fromValues: true}` (07: builds options from distinct values) |
| Smart chips ▸ (P2) | `sheets.insert.smartChip` |
| — | |
| View more column actions ▸ Freeze up to column {X}, Group/Ungroup columns, Move column left/right, Randomize range, Get link to this range, Define named range, Protect range, Fit to data (`sheets.cols.autoFit`) | |

### 9.4 Sheet tab menu (`context.sheetTab`) — §6.

### 9.5 Corner (select-all) menu
Paste, Paste special ▸, Clear all formatting, Fit all columns to data, Unhide all rows/columns.

---

## 10. Side panels

All panels are `SidePanelSpec`s hosted by `WonkySplitView` (suite 02 §4.5: one active; collapsed
panels show as a 44 px icon rail at the right edge, Sheets panels first, then History; the header
shows the panel icons, header actions and collapse; all panels share one width — default 360,
min 300, max 640, device pref `panel.width`; Esc collapses; `Mod+Alt+Shift+{n}` cycles). Panels operate on the **current
selection** by default and expose a `RangeInput` (§13) to change it. **Rule editors** (CF, DV,
banding, protection, named ranges, theme) edit a *draft*: the grid shows a live, non-persisted
preview, *Done* commits the draft as **one undo step** and *Cancel* discards it. List-level actions
(delete a rule, reorder by drag, enable/disable) commit immediately (1 step each). Object editors
(chart, pivot, slicer) follow [08](08-charts-and-objects.md) / [07](07-data-tools.md).

| Panel id | Title | Opened by | Body spec |
|----------|-------|-----------|-----------|
| `sheets.panel.conditionalFormatting` | Conditional format rules | `sheets.cf.openPanel` | [06 §15.9](06-formatting.md#15-conditional-formatting) |
| `sheets.panel.alternatingColors` | Alternating colors | `sheets.banding.openPanel` | 06 §14 |
| `sheets.panel.theme` | Themes | `sheets.theme.openPanel` | 06 §13 |
| `sheets.panel.dataValidation` | Data validation rules | `sheets.dv.openPanel` | 07 |
| `sheets.panel.namedRanges` | Named ranges | `sheets.namedRanges.openPanel` | 07 |
| `sheets.panel.namedFunctions` | Named functions | `sheets.namedFunctions.openPanel` | 07 / 05 |
| `sheets.panel.protected` | Protected sheets & ranges | `sheets.protect.openPanel` | 07 |
| `sheets.panel.chartEditor` | Chart editor (Setup / Customize tabs) | chart select + edit, `sheets.chart.insert` | 08 |
| `sheets.panel.pivotEditor` | Pivot table editor | pivot *Edit*, `sheets.insert.pivotTable` | 07 |
| `sheets.panel.slicer` | Slicer (P2) | `sheets.slicer.add` | 07 |
| `sheets.panel.filterViews` | Filter views | Data › Change view ▸ Manage | 07 |
| `sheets.panel.columnStats` | Column stats | `sheets.data.columnStats` | 07 |
| `sheets.panel.explore` | Explore | `sheets.explore.toggle` | 12 |
| — | Edit history (single cell) | `sheets.history.showCellHistory` — a popover, not a panel | [10 §6](10-collaboration-history.md) |
| `sheets.panel.cleanupSuggestions` | Cleanup suggestions (P2) | `sheets.cleanup.openSuggestions` | 07 |
| `comments` (shell) | Comments | header button, `sheets.comments.openPanel` | 10 / suite 07 |
| `assistant` (shell) | Assistant | rail icon, `shell.ai.togglePanel` | suite 10, 12 |
| — | Version history | full-screen route `/s/:uuid/history` | 10 |
| — | Script editor | full-screen route `/s/:uuid/script` | 09 |

Panel chrome: host header with the panel icons (no title; the name is the icon's tooltip), the
panel's header actions (e.g. help (?) link) and collapse; body in `WonkyScrollArea`; footer with
primary *Done*. Below 768 px the open panel overlays the grid from the right over a scrim.

---

## 11. Dialogs

All dialogs are `WonkyFormDialog`s built from a `WonkyDialogSpec` (suite 09 §6.2) so MCP can
describe/fill/press them, unless marked *custom* (then `McpDescribableDialog`). Field ids in
`code` are the MCP field ids. Primary button is right-most; Esc = Cancel; Enter = primary when
valid.

### 11.1 Spreadsheet settings (`sheets.file.settings`)

`ShadDialog` 560 px with `ShadTabs`:

- **General**: `locale` (`ShadSelect.withSearch`, all `intl` locales with display names; affects
  number/date/currency formats, function argument separator `,` vs `;`, input parsing), `timeZone`
  (`ShadSelect.withSearch` of IANA zones with current offset), `displayLanguage` (P2: function
  names & error names language; addition to 02, §15), live preview line: "1,234.56 · $1,234.56 ·
  9/26/2008 · 3:59:00 PM · =SUM(1, 2)" in the selected locale.
  **As built:** *Function language* (`ShadSelect`: English, Deutsch, Français, Español, Svenska;
  `sheets.settings.update {displayLanguage}`, `''` = English, MCP field `displayLanguage`). The
  preview's `SUM` follows it. Core `FormulaLanguage` (`formula/parser/formula_language.dart`)
  maps ~120 common functions and TRUE/FALSE per language; `FormulaLocale.withLanguage` carries it
  to the lexer, parser, codec, autocomplete, signature help and validation. The stored form stays
  English and English names are always accepted (also by agents); only the editor UI renders
  localized names (`EngineFormulaHooks(displayLanguage: true)`, `SheetEditorController.
  formulaLocale`); booleans display translated in cells (`CellDisplayResolver`). Error literals
  stay English; untranslated functions keep their English names.
- **Calculation**: `recalcMode` (`ShadSelect`: On change / On change and every minute / On change
  and every hour), `iterativeCalc` (`ShadSwitch`), `maxIterations` (`WonkyNumberStepper` 1–1,000,
  default 50; enabled when iterative), `convergenceThreshold` (`ShadInput` numeric ≥ 0, default
  0.05).
- Buttons: [Cancel] [Save settings] → `sheets.settings.update {locale?, timeZone?, recalcMode?,
  iterativeCalc?, maxIterations?, convergenceThreshold?}` (1 step; writes only changed columns).
  Changing the locale shows an inline note: "Formats like 'Currency' and dates will display using
  the new locale. Existing values are not changed."

### 11.2 Custom number format (`sheets.format.openCustomNumberFormat`) — *custom*

Input `pattern` (GeistMono) with live **preview** of the active cell's value (and of sample values
positive/negative/zero/text), error message under the input for invalid patterns, list of
examples (built-ins + this spreadsheet's recently used custom formats) clickable to load, and a
"Format codes" help accordion (06 §5). Buttons: [Cancel] [Apply] →
`sheets.format.numberFormat {pattern}`.

### 11.3 Custom date and time (`sheets.format.openCustomDateTime`) — *custom*

Preset list (e.g. "Tuesday, September 26, 2008", "26-Sep-2008 15:59", ISO) + **token builder**:
an input showing chips (`Day ▾`, `/`, `Month ▾`, `/`, `Year ▾`, …); each chip has a dropdown
choosing the representation (e.g. Month: `1`, `01`, `Jan`, `January`, `J`; Year: `08`, `2008`;
Hour: `3`, `03`, 24h/12h, elapsed; Remove). Free text between chips is a literal. Add-chip menu
(▾) lists Day, Day of week, Month, Year, Hour, Minute, Second, Millisecond, AM/PM, Elapsed
hours/minutes/seconds. Preview of the active cell. [Cancel] [Apply] → pattern (06 §5.6).

### 11.4 Custom currency (`sheets.format.openCustomCurrency`) — *custom*

Search input; list of currencies (ISO code, symbol, name; from `intl` `currencySymbols`) — each
row expands to format variants (`$1,000.12`, `$1,000`, `$(1,000.12)`, `$ 1,000.12`, `1,000.12 $`,
`USD 1,000.12`, red negatives). [Cancel] [Apply] → pattern with locale tag `[$€-407]` etc.
(06 §5.7).

### 11.5 Sort range (advanced) (`sheets.data.openSortDialog`)

Fields: `range` (read-only label "Sort range from A1 to D20"), `hasHeader` (checkbox "Data has
header row" — when checked, sort-by selects show header names), `sortBy` list of
`{column (ShadSelect), order (ShadRadioGroup A→Z / Z→A)}` rows with ✕, "+ Add another sort column"
(up to number of columns). [Cancel] [Sort] → `sheets.data.sortRange {range, specs:[…], hasHeader}`
(07).

### 11.6 Paste special… (`sheets.edit.pasteSpecialDialog`)

For keyboard/MCP users: `mode` radio (8 modes from 03 §12.4), [Cancel] [Paste]. Disabled modes
greyed with reason.

### 11.7 Find and replace (`sheets.find.openReplace`)

Fields: `find` (input), `replace` (input), `searchIn` (`ShadSelect`: All sheets / This sheet /
Specific range → `RangeInput`), `matchCase` (checkbox), `matchEntireCell`, `useRegex` (with help
link), `searchFormulas` ("Also search within formulas"), `searchLinks` ("Also search within
links"). Buttons: [Find] (next; shows "3 of 12" status), [Replace], [Replace all], [Done]. Replace
all → one undo step, toast "Replaced 12 instances of 'x' with 'y'". Non-modal: the grid stays
interactive while open (dialog draggable). Behavior in [07](07-data-tools.md).

### 11.8 Insert rows/columns (`sheets.rows.openInsertDialog`, `sheets.cols.openInsertDialog`)

Fields: `count` (`WonkyNumberStepper` 1–10,000 bounded by the cell limit), `position` (radio
Above/Below or Left/Right). [Cancel] [Insert]. Reached from the command palette ("Insert rows…")
and from `Mod+Alt+=` with a cell selection (then shows *Insert cells*: radio Shift right / Shift
down / Entire row / Entire column).

### 11.9 Delete cells (`sheets.structure.openDeleteDialog`)

Radio Shift left / Shift up / Entire row / Entire column. [Cancel] [Delete].

### 11.10 Resize rows / columns (`sheets.rows.openResizeDialog`, `sheets.cols.openResizeDialog`)

Title "Resize rows 5 – 7". Radio: "Specify row height" + `size` input px (default current or 21) /
"Fit to data". [Cancel] [OK] → `sheets.rows.resize` or `sheets.rows.autoFit`.

### 11.11 Merge warning

`ShadDialog.alert`: "Merging cells will only preserve the top-leftmost value. Merge anyway?"
[Cancel] [OK] (06 §10). Variant for vertical/horizontal merges: "…only preserve the top value of
each column/leftmost value of each row".

### 11.12 Remove duplicates (`sheets.cleanup.openRemoveDuplicates`)

Fields: `hasHeader` (checkbox "Data has header row"), `columns` (checkbox list "Columns to
analyze" with *Select all*). [Cancel] [Remove duplicates] → result dialog: "N duplicate rows
found and removed. M unique rows remain." [OK]. (07)

### 11.13 Split text to columns (`sheets.data.splitTextToColumns`)

Not modal: splits immediately with automatic detection and shows a floating **Separator** chip
(popover anchored below the range): Detect automatically / Comma / Semicolon / Period / Space /
Custom [input]. Changing the separator re-runs the split as a replacement of the same undo step
(the previous split is undone first). Warning dialog if it would overwrite data to the right:
"Do you want to replace existing data?" [Cancel] [Replace].

### 11.14 Delete sheet confirm

`ShadDialog.alert`: "Delete 'Budget'? — You can undo this." (no permanent loss; undoable) [Cancel]
[Delete] (destructive variant). Shown only when the sheet has content; empty sheets delete
immediately.

### 11.15 Import file (`sheets.file.import`) — *custom*

Owned by [11 §2](11-import-export-print.md). Summary: source step with tabs *Upload* (drop zone +
*Browse*, `file_picker`; `.xlsx .xls .ods .csv .tsv .txt`, size limits 01 §3), *Recent uploads*
(P2), *Drive* (P2); options step with **Import location** (Create new spreadsheet / Insert new
sheet(s) / Replace spreadsheet / Replace current sheet / Append to current sheet / Replace data
at selected cell), *Separator type* (Detect automatically / Tab / Comma / Custom), *Encoding*,
*Locale for numbers & dates*, *Convert text to numbers, dates, and formulas*, *Sheets to import*
(XLSX/ODS), *Unsupported formulas*, and a 20-row preview (`two_dimensional_scrollables`
`TableView`). [Cancel] [Import data] → progress toast; one undo step unless a new spreadsheet is
created.

### 11.16 Protected range warning / blocked — 03 §16.

### 11.17 Invalid entry (data validation) — 03 §8.4.

### 11.18 Go to range (`sheets.nav.goTo`)

Small dialog with `target` input (accepts A1, ranges, `Sheet!A1`, named ranges; autocomplete of
sheets and named ranges), [Cancel] [Go]. When the name box is visible, the command just focuses
the name box instead.

### 11.19 Keyboard shortcuts (`shell.help.shortcuts`)

Shell dialog (suite 08 §1.2) with Sheets categories: Common actions, Cell formatting, Navigation,
Editing, Rows & columns, Formulas, Data, Comments & notes, Menus, Macros. Toggle "Enable
compatible spreadsheet shortcuts" (P2: Excel-only bindings such as `F4` absolute in grid, `Ctrl+1`
format cells). Link "Customize" → Settings › Keyboard shortcuts.

### 11.20 Function help (`sheets.help.functionList`) — *custom*

Two-pane dialog 760 × 560: left = search input + category list (`ShadAccordion`) of all functions
(built-in, named, custom); right = details: syntax line, summary, arguments table, examples (with
*Insert* buttons), "See also" links. [Insert function] inserts `NAME(` into the editor/active cell
(starts editing). Content generated from the function registry metadata (05).

### 11.21 Rotation custom angle

Small popover with `WonkyNumberStepper` (−90…90°) and a dial preview → `sheets.format.rotation`.

### 11.22 Cell limit exceeded

`ShadDialog.alert`: "This action would increase the number of cells in the spreadsheet above the
limit of 1,000,000 cells." [OK].

### 11.23 Randomize range (`sheets.data.randomizeRange`)

Executes immediately (Google behavior, 1 step), no confirmation. Formulas in moved rows are
adjusted exactly like sort (see [07-data-tools.md](07-data-tools.md)).

### 11.24 Sheets settings › Defaults (user defaults; v2: app settings)

(v2) The **app settings** of the Sheets app (`/settings/app/defaults`, suite 04 §4), shown only
in Sheets — no longer a section of the shared settings page, and Write no longer shows Sheets
toggles. *Default locale for new spreadsheets* moves here from Language & region.

Default locale for new spreadsheets, default time zone, default font/size, *Enter key starts
editing*, *Formula autocomplete*, *Formula help*, *Show editor mode in status bar*, *Custom fill
lists* (editable list of lists), *Enable scripts on this device*, *Reduce grid animations*.
Stored in `UserPreferences.sheetsDefaults` (suite 04). Built as the Sheets app's section
(v2: `WonkyAppConfig.appSettingsSections`, replacing `sheetsSettings`); keys in
`SheetsUserDefaults` (06 §20). Custom fill lists are
edited as one list per line, items separated by commas. Write shows only the shared toggles.
The locale, time zone and default font/size also apply to spreadsheets the **server** creates
(`drive.createSpreadsheet` with `initialize: true`, built-in templates, imports and MCP
`drive.create_spreadsheet`): `SheetsCreateDefaults.of(session, userId)` reads the creator's
`sheetsDefaults`; explicit `locale`/`timeZone` arguments win. Copies of user templates keep the
template's settings.

As built (D-12): `wonky_sheets/lib/features/settings/` (`sheetsSettingsSections`,
`SheetsSettingsSection` moved from `formatting/`); groups *New spreadsheets*, *Editing* (incl.
*Autocomplete values from the column* and *Distinguish chart series by pattern*), *Custom fill
lists*. Every control goes through **`sheets.prefs.set {key, value}`** (not in the palette;
validates the key against `sheetsSettingKeys` and the value's type; works without an open
spreadsheet), so MCP can change every setting.

### 11.25 Copy sheet to existing spreadsheet

Drive picker dialog (shell `DrivePickerDialog`, filtered to spreadsheets where user is Editor) →
[Select]. Then toast "Sheet copied successfully — Open spreadsheet".

---

## 12. Home screen (Sheets variant of suite 05 §3)

- (v2) The Sheets home lists **only spreadsheets** (no type filter) and the folders that contain
  spreadsheets (suite 05 §3.2); the left menu (suite 03 §3.3) has the four app links, Recent /
  My files / Shared with me / Starred / Offline / Trash, then *Sheets settings*, *Wonky Work
  settings*, *Bugs & improvements* (was *Report a bug*) and the storage meter; folder management and other kinds are in
  Wonky Drive (*Open in Wonky Drive*). Search is filtered to spreadsheets ("Search all of Wonky
  Drive" row).
- `SheetsAppConfig.homeScope = HomeScope.kind(spreadsheet)` (D-16); `+ New` = *Spreadsheet*
  (works offline: the file UUID is generated on the device and the drive create is queued,
  [02 §4](02-data-model.md)), *From template…* and *Import file…*
  (`.xlsx .ods .csv .tsv .txt`). The empty home reads "Welcome to Wonky Sheets".
- (v2, as built D-16) `/import?file=` loads the file's bytes (`drive.fileContentUrl`), shows
  the import dialog (§11.15) with only *Create new spreadsheet* enabled, and runs
  `drive.convertFile` with the chosen options (`optionsJson`) — the stored file is converted on
  the server, not uploaded again. Cancel goes back to Drive (`history.back`); errors stay in
  Sheets with a toast. Images over cells whose upload was refused on quota show "Not uploaded —
  out of storage" with *Retry* / *Remove* (`ImageOutOfStorageOverlay`); in-cell `IMAGE()`
  images show no overlay (TODO.md).
- **Template strip**: Blank, To-do list, Annual budget, Monthly budget, Schedule, Invoice, Project
  timeline (Gantt via CF), Expense report, Attendance, Team roster. Templates are spreadsheets
  with `DriveItem.templateOf` (suite 05); category "Finance" etc. on `/templates`.
- **Thumbnails**: generated by the client. After an editing session (on route exit, or every 10 min
  of continuous editing, only by an editor), `SpreadsheetThumbnailer` paints the first visible
  sheet's top-left region (A1 to the cell covering 640 × 400 logical px at 100 % zoom, light
  theme) with the same `GridPainter` layers (no selection/presence) into an offscreen
  `PictureRecorder`, encodes 320 × 200 PNG and uploads it via the files endpoint, then calls
  `drive.setThumbnail(itemUuid, fileUuid)` (**addition to suite 05 DriveEndpoint**). Skipped if the
  rendered region hash is unchanged. Grid view cards show the thumbnail; list view shows the green
  Sheets icon.
- Drag-and-drop of `.xlsx/.xls/.ods/.csv/.tsv` onto the list imports as new spreadsheets (suite
  05 §3.2), using the server import pipeline for files > 5 MB (11). (v2) Imports and images
  over cells count against the storage quota (Drive 03 §7.2): a refused import or image shows
  the *Out of storage* dialog; images queued offline stay placeholders "Not uploaded — out of
  storage" (08 §10).
- Offline: spreadsheets fully in the device's cache (opened in the last 14 days, max 50, or
  pinned; 17 part 6 §2.5) are marked available offline; others are dimmed when offline.
- **Settings › Offline & storage** (suite 12) gets the Sheets numbers from `RevOfflineProvider`
  (`wonky_revlog_flutter`): spreadsheets on the device, pinned, spreadsheets with pending
  changes (outbox rows) and bytes used, plus the warning "Offline storage is limited in this
  browser" without OPFS (200,000 cells kept offline). *Clear local data* empties the cache.
  **As built:** it doesn't export unsent outboxes first (17 part 6 §8, As built 15).

---

## 13. Shared custom widgets introduced by Sheets

| Widget | Package | Description |
|--------|---------|-------------|
| `RangeInput` | `wonky_sheets/lib/features/common/range_input.dart` (app — needs grid) | `ShadInput` for A1 ranges (multiple via `,`) with validation and a ⊞ button that enters **range-picking mode**: the panel/dialog dims, a floating "Select a data range" card appears with the input and [Cancel] [OK]; selecting on the grid (incl. Mod+click multi ranges and switching sheets) updates the input live. Used by CF, DV, protected ranges, named ranges, charts, pivot, find. **As built:** no dimming/floating card — picking is on while the input is focused and stays on when focus goes to the grid (ends with an `onCommitted` when focus moves elsewhere or on Enter); the ⊞ toggle keeps it on. Used by CF, DV, banding, protection, chart editor and the pivot editor's source range (written on commit). |
| `FormulaEditor` | app (`features/cell_editor/formula/formula_field.dart`) | Single-line formula input with highlighting, autocomplete and signature help (03 §8.7) for panels (CF custom formula, DV custom formula, named functions). Supports point mode on the grid like `RangeInput`. |
| `BorderPicker` | app | §4.1 |
| `NumberFormatPicker` / `NumberFormatMenu` | app | §4.2, dialogs §11.2–11.4 |
| `IconChoiceMenu` | `wonky_ui` | Row of icon toggles inside a dropdown (alignment, wrapping) |
| `ColorSwatchPreview` | `wonky_ui` | Tiny swatch + label used in rule lists |
| `RulePreviewSwatch` | app | "Aa" preview of a CF/banding format (06 §15.9) |
| `SheetTabBar` | app | §6 |
| `SelectionStatsButton` | app | §7 |
| `DropdownPickerPopover`, `LinkHoverCard`, `NotePopover` | app | 03 §14 |

---

## 14. Light and dark grid colors

> **As built.** The tokens are the constants `GridPaintTokens.light` / `.dark` in
> `wonky_sheets/lib/theme/sheets_tokens.dart`, chosen by the shad theme brightness.

`wonky_sheets/lib/theme/sheets_tokens.dart` registers these as `ShadColorScheme.custom`
entries (suite 02 §2); the generic `gridLine…`/`selection…`/`fillHandle` tokens are defined in
`wonky_ui` with the same values.

| Token | Light | Dark | Use |
|-------|-------|------|-----|
| `sheetBackground` | `#FFFFFF` | `#1F1F1F` | Cell background when fill = none |
| `gridLine` | `#E1E1E1` | `#3A3A3A` | Gridlines |
| `gridHeaderBg` | `#F8F9FA` | `#262626` | Headers, corner |
| `gridHeaderFg` | `#5F6368` | `#A8A8A8` | Header labels |
| `gridHeaderSelectedBg` | `#D3E3FD` | `#2B3F5C` | Headers intersecting selection |
| `gridHeaderFullBg` | `#0B57D0` @ 25 % | `#8AB4F8` @ 30 % | Fully selected row/col header |
| `selectionFill` | `#1A73E8` @ 10 % | `#8AB4F8` @ 16 % | Selected cells |
| `selectionBorder` | `#1A73E8` | `#8AB4F8` | Range outline, active cell frame |
| `fillHandle` | `#1A73E8` | `#8AB4F8` | Fill handle |
| `frozenDivider` | `#BDC1C6` | `#5F6368` | Freeze lines & bars |
| `autoText` | `#000000` | `#E8EAED` | "Automatic" text color |
| `autoBorder` | `#000000` | `#E8EAED` | "Automatic" border color |
| `linkText` | theme link color (`#1155CC` default) | lightened theme link (`#8AB4F8` default) | Hyperlinks |
| `noteTriangle` | `#000000` | `#E8EAED` | Note indicator |
| `commentHighlight` | `#FBBC04` | `#FDD663` | Comment indicator |
| `errorTriangle` | `#D93025` | `#F28B82` | Error indicator |
| `invalidTriangle` | `#E37400` | `#FCAD70` | DV warning |
| `protectedStripe` | `#5F6368` @ 25 % | `#BDC1C6` @ 25 % | Protected ranges |
| `spillFrame` | `#4285F4` @ 60 % | `#8AB4F8` @ 60 % | Spill outline |
| `skeleton` | shad `muted` | shad `muted` | Loading cells |
| `referenceColors[0..9]` | `#1A73E8 #D93025 #188038 #9334E6 #E37400 #12B5CB #E52592 #7CB342 #F9AB00 #5F6368` | lighter variants `#8AB4F8 #F28B82 #81C995 #C58AF9 #FCAD70 #78D9EC #FF8BCB #AED581 #FDD663 #BDC1C6` | Formula refs |
| `formulaNumber` / `formulaString` | `#1967D2` / `#188038` | `#8AB4F8` / `#81C995` | Formula syntax |

Rules:
- **User-set cell colors are absolute** (suite 02 §8): text `#000000` stays black in dark mode. To
  keep defaults readable, "Automatic" text/border colors and no-fill backgrounds follow the
  tokens above.
- P2 view option *View › Show › Dark mode cell colors* (`sheets.view.toggleAdaptiveCellColors`,
  per user): renders explicit colors with lightness inverted in HSL (hue kept) for display only.
- Printing/PDF/thumbnails always use the light tokens (suite 02 §8).
- Contrast: header labels and selection borders meet ≥ 3:1 against their backgrounds in both
  themes (verified by a token test).

---

## 15. Additions to 02-data-model (proposed)

| Addition | Purpose |
|----------|---------|
| `Spreadsheet.displayLanguage: String?` (null = English function names) | Settings › General "Display language" (P2) |
| `UserPreferences.sheetsDefaults.selectionStat`, `…enterStartsEditing`, `…customLists`, `…formulaSuggestions` | Per-user UI preferences (suite 04) |
| `DriveEndpoint.setThumbnail(itemUuid, fileUuid)` (suite 05) | Client-generated thumbnails (§12) |

## 16. Acceptance criteria

- AC-M1: Every menu item in §3 dispatches exactly the listed command id (test iterates the
  `MenuSpec` and compares against a golden list); every command id in the menus exists in the
  registry at startup (fails fast in debug).
- AC-M2: `ui.get_menu_tree` returns the same tree with enabled/checked states; disabled items
  carry a reason.
- AC-M3: Toolbar overflow: at 1,024 px width, items with priority ≥ 5 are in the overflow menu;
  at 1,600 px, nothing overflows; the overflow menu invokes the same commands.
- AC-M4: Toolbar toggles reflect the active cell's effective format within one frame of a
  selection change.
- AC-M5: Tab bar: drag-reorder, rename (double-click), color, hide/unhide, delete + undo all work
  and sync to a second client within 3 s.
- AC-M6: Every dialog in §11 is describable via `ui.get_dialog` and completable with
  `ui.fill_dialog` + `ui.press_dialog_button`.
- AC-M7: Light/dark switch updates grid chrome and automatic colors without changing user-set
  colors (golden tests in both modes).
- AC-M8: Viewer mode hides/disables every mutating control and shows "View only".
