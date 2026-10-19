# 02 · Design System — `wonky_ui`

All UI is built with **`shad`** (Serverpod's high-fidelity shadcn/ui port, `shad: ^0.99.4`,
docs: <https://shad.serverpod.dev/>; the package ships an agent skill at
`skills/shad-overview/SKILL.md` — read it before building UI). Where shad lacks a component,
we build a **matching widget** in `packages/wonky_ui` that uses only shad tokens
(`ShadTheme.of(context)`), shad primitives (`ShadPortal`, `ShadPopover`, `ShadFocusable`,
`ShadRovingFocus`) and Lucide icons — so it is indistinguishable from native shad components and
follows light/dark automatically.

Material widgets are **not** used directly in feature code (shad derives a Material `ThemeData`
for interop only; `Scaffold`-free layouts are preferred). `wonky_ui` must not depend on Serverpod,
the client, or any feature package — pure presentation.

## 1. App setup

```dart
ShadApp.router(
  title: 'Wonky Write',
  theme: WonkyTheme.light(prefs),     // ShadThemeData
  darkTheme: WonkyTheme.dark(prefs),
  themeMode: prefs.themeMode,         // system | light | dark
  routerConfig: router,
  localizationsDelegates: [GlobalShadLocalizations.delegate, ...WonkyL10n.delegates],
)
```

- `WonkyTheme` builds `ShadThemeData` from: style tokens (`ShadStyleTokens.vega` default),
  color scheme (`ShadZincColorScheme`; `WonkyThemeConfig.accent` exists but the apps don't
  offer an accent choice), radius, density (`ShadSpacing` scale: comfortable / compact), and
  **custom tokens** (below).
- Themes are cached and compared by value: `ShadThemeData` inequality triggers a 200 ms lerp
  on every rebuild, so `WonkyTheme` memoizes per (brightness, accent, density) key.
  Don't `copyWith(radius:)` — rebuild the theme instead (component themes are not re-derived).
- App theme mode switch: `shell.appearance.setTheme(system|light|dark)` command; the top bar
  toggle cycles them. Switching animates via `ShadAnimatedTheme` (honours *Reduce motion*).

## 2. Tokens

Use shad tokens: `background`, `foreground`, `card`, `popover`, `primary`, `secondary`, `muted`,
`accent`, `destructive`, `border`, `input`, `ring`, `selection`, `chart1–5`, `sidebar*`,
`ShadRadii`, `ShadTextTheme` (`h1…h4`, `p`, `large`, `small`, `muted`), spacing steps
(`ShadPadding`, `ShadGap`).

Custom tokens (registered via `ShadColorScheme.custom`, read through a `WonkyColors` extension
on `ShadColorScheme`), each defined for light and dark:

| Token | Use |
|-------|-----|
| `canvas` | Area behind document pages (Write) / outside grid |
| `page` | Write page surface (follows the Write theme's page color, default white / #1e1e1e) |
| `gridLine`, `gridHeaderBg`, `gridHeaderFg`, `gridHeaderSelectedBg` | Sheets grid |
| `selectionFill`, `selectionBorder` | Sheets range selection |
| `fillHandle` | Sheets fill handle |
| `commentHighlight`, `commentHighlightActive` | Anchored comments |
| `suggestionInsert`, `suggestionDelete` | Write suggestion mode |
| `findMatch`, `findMatchActive` | Find & replace highlights |
| `presence1…presence12` | Collaborator colors (cursor, selection, avatar ring); assigned by hash of user id |
| `success`, `warning`, `info` | Status badges, toasts |
| `offline` | Offline banner |

Typography: shad bundles **Inter**, **Geist** and **GeistMono**. App chrome uses Geist (UI) and
GeistMono (formulas, code, shortcuts). Document fonts (Write themes, Sheets cell fonts) come from
a curated font list (see each app spec) loaded via bundled assets (no runtime Google Fonts on
web for privacy/offline; `google_fonts` is used only at build-time to fetch files into assets).

Icons: `LucideIcons.*` only, except the product icons (§5) that stand for a product (app). Icon size 16 in toolbars/menus, 20 in sidebars, 24 in empty states.

## 3. shad components we use (mapping)

| Need | shad component |
|------|----------------|
| Menu bar (File/Edit/View…) | `ShadMenubar` + `ShadMenubarItem` + `ShadContextMenuItem` (submenus via `items:`) |
| Context menus | `ShadContextMenuRegion` |
| Dropdown menus (toolbar dropdowns, ⋮ menus) | `ShadContextMenu` with controller + anchor, wrapped as `WonkyDropdownMenu` |
| Buttons, toggles | `ShadButton.*`, `ShadIconButton`, `ShadToggle`, `ShadToggleGroup` |
| Selects / combobox | `ShadSelect`, `ShadSelect.withSearch` |
| Text fields | `ShadInput`, `ShadTextarea`, `ShadInputOTP` |
| Markdown text fields (board composer) | `WonkyRichEditor` (`wonky_rich_editor`): super_editor styled exactly like `ShadTextarea` (border, radius, padding, focus ring, disabled), with a `ShadToggle` formatting toolbar, spelling squiggles and a right-click menu (suggestions, Cut / Copy / Paste) when given a spell checker (16 §7.3) |
| Forms | `ShadForm` + `Shad*FormField` |
| Dialogs | `ShadDialog` (X: `WonkyDialogCloseButton`, §4.20), `ShadDialog.alert`, `showShadDialog` |
| Side sheets (mobile-ish / narrow) | `ShadSheet` |
| Popovers / tooltips | `ShadPopover`, `ShadTooltip` |
| Toasts | `ShadSonner` (stacked), `ShadToast.destructive` for errors |
| Tabs | `ShadTabs` |
| Accordions | `ShadAccordion` (side panels, CF rules list) |
| Resizable side panels | `ShadResizablePanelGroup` / `ShadResizablePanel` |
| App sidebar | `ShadSidebarScaffold`, `ShadSidebarMenu…` |
| Command palette | `ShadCommand`, `ShadCommandGroup`, `ShadCommandItem` in a `ShadDialog` |
| Tables (drive list, settings tables, version list) | `ShadTable` / `ShadDataTable` |
| Calendar / date picker | `ShadCalendar`, `ShadDatePicker` (DV date picker, version filters) |
| Avatars, badges, cards, alerts, kbd, empty, skeleton, spinner, progress | `ShadAvatar`, `ShadBadge`, `ShadCard`, `ShadAlert`, `ShadKbd`, `ShadEmpty`, `ShadSkeleton`, `ShadSpinner`, `ShadProgress` |
| Checkbox, switch, radio, slider | `ShadCheckbox`, `ShadSwitch`, `ShadRadioGroup`, `ShadSlider` |
| Breadcrumbs | `ShadBreadcrumb` |

## 4. Custom widgets in `wonky_ui` (matching shad)

Each custom widget gets: a `previews.dart` widget preview (light + dark), a widget test, and a
theme slot (`WonkyThemeExtension`) for overrides. Spec for each:

### 4.1 `WonkyToolbar`
Horizontal formatting toolbar with **overflow handling**: children are `ToolbarItem`s with a
priority; when width is insufficient, lowest-priority items move into a trailing "⋯" overflow
dropdown (preserving groups). Supports `ToolbarGroup` (separated by `ShadSeparator.vertical`),
`ToolbarToggleButton` (wraps `ShadToggle`, 28×28, tooltip with title + `ShadKbd` shortcut),
`ToolbarDropdownButton` (label + chevron, opens `WonkyDropdownMenu`), `ToolbarSplitButton`
(action + chevron, e.g. text color / borders), `ToolbarNumberField` (font size: − / input / +),
`ToolbarSelect` (zoom, styles). Keyboard: `Alt+/` (or `Mod+Alt+.`) focuses toolbar, arrows move
(`ShadRovingFocus`), Esc returns focus to the editor. Height 40 px (compact 36).

### 4.2 `WonkyDropdownMenu` and menu item variants
Thin wrapper over `ShadContextMenu` (controller + anchor) adding:
- `MenuItem.command(commandId)` — title/icon/shortcut/enabled/checked from the command registry.
- `MenuCheckItem` (✓ leading when checked), `MenuRadioItem` (● leading), `MenuSubmenu`,
  `MenuSeparator`, `MenuLabel` (section header), `MenuCustom` (e.g. color grid, table-size grid).
- Trailing shortcut rendered with `ShadKbd` (platform glyphs: ⌘ ⌥ ⇧ ⌃ on macOS; Ctrl+Alt+Shift
  elsewhere).
- `WonkyMenuItem.leading`: a 16 px widget shown instead of the icon (e.g. an app's product icon,
  §5).
- Type-ahead: typing letters jumps to items.
- Used both in `ShadMenubar` items and standalone dropdowns.
- **Only one menu is open at a time**: menubar menus, dropdown menus and context menus claim the
  `OpenMenu` slot when they open, which closes the menu that was open before (shad puts a menu,
  its trigger and its popover in one tap-region group, so a tap on another menu's trigger would
  otherwise not close it).

### 4.3 `WonkyMenubar`
`ShadMenubar` whose items are built from a declarative `MenuSpec` tree
(`MenuSpec.command`, `.submenu`, `.separator`, `.custom`) so that the **same spec** generates the
menubar, the command-palette menu paths and the MCP `ui.get_menu_tree` output. `Alt` (Win/Linux)
or `Ctrl+F2`-style focus shortcut (`Alt+F` opens File etc. on Win/Linux; on macOS, `Ctrl+Alt+F`)
to avoid conflicts. Menu commands are found through the command palette (suite 08); there is no
separate menu search. The strip is flat: the shad menubar's `controlShadow` is clipped away
(`ClipRect`), so it has no drop shadow; the menus themselves are unchanged.

### 4.4 `WonkyColorPicker`
Popover content used for text color (Sheets), fill color, border color, tab color, chart colors,
theme colors:
- Header row: **Reset** (`Automatic`/`None`) button.
- Grid of 10×8 swatches (Google-like palette) + **Theme colors** row (document/theme palette) +
  **Recent/custom colors** row (stored per user).
- **Custom…** opens an inline panel: saturation/value square, hue slider, alpha slider (when
  allowed), hex input, RGB inputs, eyedropper (desktop only, where supported).
- Keyboard: arrows over grid, Enter selects. Each swatch has an accessible name ("light red 2").
- Returns `WonkyColor` (`{hex, themeRef?}`), so theme-referenced colors can update when the theme
  changes.

### 4.5 `WonkySplitView` / side panel host
A right-side **panel host** used by both apps: hosts Outline, Comments, Version history,
Assistant, Find & replace (Sheets uses a dialog), Script editor sidebar, Named ranges, Data
validation, Conditional formatting, Chart editor, Pivot editor, etc. Built on
`ShadResizablePanelGroup`. Behaviors:
- One active panel at a time. **All panels share one width** (default 360, min 300, max 640,
  persisted as the device pref `panel.width`).
- **Collapse, not close** (`rail: true`, the editors): a collapsed host shows a 44 px vertical
  **icon rail** at the right edge (`panel.rail`, buttons `panel.rail.<id>`), one icon per
  `showAsTab` panel; clicking an icon opens that panel. The open panel's header shows only icon
  buttons (one per `showAsTab` panel, the open one highlighted; the panel name is the icon's
  tooltip and the body's semantics label — there is no heading), then the panel's header actions
  and a collapse button (`panel.collapse`, `panelRightClose` icon). Esc and the narrow-window scrim
  collapse the panel too.
- `rail: false` (the drive's single details panel): no rail; the header keeps a close button
  (`panel.close`) and the host hides.
- One left border: the resize handle draws its 1 px line at its left edge on the panel
  background (a centered line read as a double border).
- `Mod+Alt+Shift+[` / `Mod+Alt+Shift+]` cycle panels (`Mod+Alt+Shift+0–9` is reserved for Sheets
  macros).

Panels (`SidePanelSpec`) declare `id`, `title`, `icon`, `builder`, `headerActions` and
`showAsTab` (default true; false for panels opened only by their command, e.g. File › Details,
which are not in the rail). They declare no width of their own.

### 4.6 `WonkyTreeView`
Lazy tree (drive folder tree, document outline, script file tree): expand/collapse, keyboard
navigation (arrows, Home/End, `*` expand all), drag-and-drop reordering with drop indicators,
inline rename, virtualized for > 1000 nodes.

### 4.7 `PresenceAvatarStack`
Overlapping avatars of collaborators currently in the file (max 4 + "+N" chip), ring in
presence color, tooltip with name + "Editing"/"Viewing"/"Idle"; click avatar → jump to their
cursor; click "+N" → popover list.

### 4.8 `RemoteCursorOverlay` primitives
Shared painters for remote carets (2 px bar + name flag in presence color, flag fades after 3 s
of inactivity and on hover reappears) and remote selection fills (presence color at 20% alpha).
Used by Write (text layer) and Sheets (cell rect).

### 4.9 `WonkyNumberStepper`
`ShadInput` with −/+ buttons, min/max/step, scroll-to-change, arrow keys, validation. Used for
font size, decimal places, row counts, page margins.

### 4.10 `WonkyTableSizePicker`
Grid (max 10×10, grows to 20×20 on hover) to pick rows×columns for "Insert table" (Write) —
custom menu content.

### 4.11 `FontPicker`
`ShadSelect.withSearch` variant showing each font rendered in its own face, sections "Recent",
"Theme fonts", "All fonts".

### 4.12 `WonkyScrollArea`
Styled scrollbars (thin, auto-hide, shad colors) used around the editor canvas and panels.
Includes "scroll shadow" top/bottom edges.

### 4.13 `StatusBar`
Bottom bar (24 px) slot used by both apps; it contains only the items the app passes (Write: the
word count; Sheets: sum-avg-count of selection, cell limit, zoom). It has no built-in items: the
sync status lives in the title row (§4.14) and the app theme in View › App theme. The editor
scaffold shows it only when the app asks for it (`showStatusBar`).

### 4.14 `SyncStatusIndicator`
Icon + label: *Saved*, *Saving…*, *Offline*, *Sync error* (clickable → details dialog with retry
& log). Offline, the label is just *Offline* (`syncOfflineShort`); the tooltip and the details
dialog say *Offline — changes saved on this device*. Lives in each app's title row.

### 4.15 `DocumentTitleField`
Inline-editable title in the editor header: looks like text, becomes `ShadInput` on click,
Enter/blur commits via a rename command (undoable), Esc reverts; auto-width up to 400 px.

### 4.16 `KeyboardShortcutRecorder`
Captures a key chord for the keyboard settings page; displays with `ShadKbd`.

### 4.17 `EmptyStateIllustration`
Light/dark-aware SVG illustrations (`flutter_svg`, via shad dep) for empty states.

### 4.18 `LoadingShimmer` patterns
Skeleton layouts for drive list, document page, grid (built from `ShadSkeleton`).

### 4.19 `WonkyStackedBar` (v2)
Horizontal stacked bar with a legend (segments with color, label, value; a trailing "free"
segment in `muted`), 8 px high (4 px compact variant for meters), rounded ends, one
`Semantics` label listing the segments. Used by the storage meter, the Storage page and
Settings › Storage ([Drive 03 §6](wonky_drive/03-storage-quota.md)). Colors from `chart1–5`;
threshold tints (`warning`, `destructive`) are passed in by the caller.

### 4.20 `WonkyDialogCloseButton`
The X of every `ShadDialog` with one (`closeIcon: const WonkyDialogCloseButton()`): shad's
default close button has no accessible label, so it fails `labeledTapTargetGuideline`. Same look
(20 px ghost icon button, foreground at 50 %), labelled *Close*; it closes with
`Navigator.maybePop` (a dialog's `PopScope` is honored), or runs `onPressed` instead — dialogs
with a draft pass their cancel path so the X asks before discarding, like *Cancel* and Esc
(e.g. the Write table editor). Dialogs without an X pass `closeIcon: const SizedBox.shrink()`.

## 5. Product icons

Each product has its own icon (a rounded app tile, `packages/wonky_app/assets/icons/*.webp`,
sources in `/icons`): `WonkyProductIcon(WonkyProduct.work | drive | write | sheets | slides,
size:)` in `wonky_app` (`branding/product_icon.dart`; semantics label = product name, `''` for
decorative use). Product icons stand for the **apps** only; files keep plain glyphs:

- **App logo** (`WonkyAppConfig.logo`): drive top bar (with the short name, "Write" / "Sheets",
  `WonkyAppConfig.shortAppName`), editor title row, page frames and the boot overlay.
- **Sign-in screens**: the suite icon (`WonkyProduct.work`) with "Wonky Work" as the headline
  (one sign-in covers the suite).
- **App menus and settings** (`WonkyMenuItem.leading`, §4.2): the account menu's *Open ▸*
  items, (v2) the app links of every home's left menu (Drive, Write, Sheets, Slides; 03 §3.3)
  and the group headers of the settings screen (the app's icon for *<App> settings*, the Work
  icon for *Wonky Work settings*, 04 §4.2).
- **File kind icons** are not product icons: `DriveKindIcon(kind)` draws the Lucide glyphs
  (folder / file-text / sheet; (v2) presentation for decks and per-category glyphs for uploaded
  files — file-image, file-text (PDF), file-code, file-audio, file-video, file-archive, file —
  [Drive 04 §11](wonky_drive/04-screens-menus.md)) in their kind colors — drive list/grid, details panel, search
  suggestions, quick switcher, command palette rows (`PaletteRow.leading`), drag chip. The *New*
  menu and *My Drive* keep their glyphs too.
- **Platform icons** are generated from the same sources: web `favicon.png` (32 px) and PWA
  `icons/Icon-192.png` / `Icon-512.png` (no maskable variants), macOS `AppIcon.appiconset`.
  Write's HTML splash (`web/index.html`) shows the Write icon.

## 6. Layout, responsiveness, motion

- Breakpoints: shad `ShadBreakpoints`. Desktop-first. At `< MD` the sidebar collapses to a drawer
  (`ShadSheet`), below 768 px the open side panel overlays the content from the right over a
  scrim (§4.5), toolbars overflow aggressively. Nothing
  may overflow at 360 px width.
- **Mobile layout** (T-9, §6.1): below 640 px, documents are read-only.
- Motion: 150–200 ms ease-out for popovers/panels; disabled when *Reduce motion* is on or
  `MediaQuery.disableAnimations`.
- Focus: visible focus ring (`ring` token) on all interactive elements; never remove outlines.

### 6.1 Mobile layout (T-9)

`WonkyLayout.isMobile(context)` (`wonky_ui`) decides it: windows narrower than shad's `sm`
(640 px), and phone browsers (Android/iOS on the web) whose shortest side is below 600 px, so a
phone turned to landscape stays mobile. `WonkyLayout.override` forces it on or off (previews,
tests). There is no mobile editing; v2 apps are the same Flutter web builds.

- **Homes** (Drive and the app homes) work as on the desktop with the narrow rules above: the
  left menu is a drawer, the list shows the name and ⋮ only, and the selection action bar
  scrolls horizontally. One tap on an item opens it (desktop: the first click selects, the
  second opens). (T-12) Phones only read, so the homes show no *Start a new …* template strip,
  and always the list: the grid/list toggle is hidden and a grid chosen on the desktop
  (`drive.layout` / `drive.view.layout`) is kept, not shown. The left menu (suite 03 §3.3)
  keeps *Report a bug* and the storage meter at the bottom (*Settings*, *Contribute & build*
  and *Suggest an improvement* are hidden; the account menu has the settings), and its rows are
  48 px tall (`SidebarNavButton.mobileHeight`, 20 px icons, 15 px text; the folder-tree toggle
  44 px).
- **Editors** (`EditorScaffold`, suite 03 §3.1) show the **read-only view**: a 52 px title row
  (home logo, read-only title, compact sync status, *View only* badge, the app's
  `mobileTitleActions`, account menu) over the document — no menubar, toolbar, mode line, side
  panels, rail or status bar. The scaffold calls `DocumentController.setReadOnlyView(true)` after
  the frame the layout starts in, and `false` when it ends; the apps fold it into their view
  mode, so no edit command is enabled whatever the role and View › Mode › Editing is off. It is
  layout, not a change of the document: nothing is undoable or remembered, and widening the
  window restores the mode the user had. Write: Viewing, no comment margin, and (T-12) 16 px
  beside the text (`WriteDocumentScreen.mobileTextPadding` as `WonkyEditor.compactPadding`)
  instead of the page margins — the page fills the width — or the pageless padding; the page
  setup itself is unchanged. Sheets: the grid and sheet tabs (no formula bar or filter-view
  bar), with (T-12) a 1 px line in the theme's `border` color between the title row and the
  grid (`sheets.mobile.separator`). Slides: Slides 04 §16.1 and the presenter mode of
  Slides 10 §1.6.
- **Presenter bar** (`WonkyPresenterBar`, `wonky_ui`): the 52 px top bar of the mobile presenter
  mode — close (*Exit presenter mode*), title with "3 of 12", *Previous slide* / *Next slide*
  (44 px targets; a null callback disables the button), in the app theme's `background`/`border`
  colors, light and dark.

## 7. Accessibility

- All interactive widgets have semantics labels; icons-only buttons have tooltips.
- Contrast ≥ 4.5:1 for text in both themes (verify custom tokens).
- Full keyboard operability: menus, toolbars, dialogs, grid, editor, panels.
- Screen-reader announcements (`SemanticsService.announce`) for: undo/redo labels, cell
  navigation (Sheets: "B4, 42, formula =SUM(…)"), remote join/leave, sync errors.

## 8. Theming the document vs. the app

- **App theme** (light/dark) affects the chrome **and** the default rendering of document
  surfaces (dark page, light text) unless a Write theme explicitly defines dark colors.
- Write themes define both `light` and `dark` variants (see Write theme spec); Sheets cell
  colors are absolute, but the grid chrome, default text color (when "automatic") and default
  fill follow the app theme. Exports/prints always use the light variant unless the user picks
  "Export with dark theme".
