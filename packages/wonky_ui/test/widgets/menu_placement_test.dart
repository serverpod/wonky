import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/testing.dart';
import 'package:wonky_ui/wonky_ui.dart';

const _screen = Size(1280, 800);
const _trigger = ValueKey('trigger');

List<WonkyMenuEntry> _items(int n, {String prefix = 'm'}) => [
  for (var i = 0; i < n; i++)
    WonkyMenuItem(
      key: ValueKey('$prefix.item$i'),
      label: 'A rather long menu item $i',
      onSelected: () {},
    ),
];

Widget _dropdown(
  List<WonkyMenuEntry> Function() entries, {
  ShadAnchorBase? anchor,
}) => WonkyDropdownMenu(
  anchor: anchor,
  entries: entries,
  builder: (context, c) => ShadButton(
    key: _trigger,
    size: ShadButtonSize.sm,
    onPressed: c.toggle,
    child: const Text('Menu'),
  ),
);

/// Pumps [child] at [alignment] in a window of [size].
Future<void> _pumpAt(
  WidgetTester tester,
  Widget child,
  Alignment alignment, {
  Size size = _screen,
  Brightness brightness = Brightness.light,
}) => pumpWonky(
  tester,
  Align(alignment: alignment, child: child),
  size: size,
  brightness: brightness,
);

Future<void> _openDropdown(WidgetTester tester) async {
  await tester.tap(find.byKey(_trigger));
  await tester.pumpAndSettle();
}

/// The rendered box of the open menu that shows [item]: its popover surface
/// (border and padding included).
Rect _menuOf(WidgetTester tester, Finder item) => tester.getRect(
  find.ancestor(of: item, matching: find.byType(FocusScope)).first,
);

void _expectOnScreen(Rect menu, Size screen) {
  expect(menu.left, greaterThanOrEqualTo(0), reason: 'menu $menu');
  expect(menu.top, greaterThanOrEqualTo(0), reason: 'menu $menu');
  expect(menu.right, lessThanOrEqualTo(screen.width), reason: 'menu $menu');
  expect(menu.bottom, lessThanOrEqualTo(screen.height), reason: 'menu $menu');
}

void main() {
  group('Given a dropdown whose trigger is in the bottom-right corner', () {
    for (final b in Brightness.values) {
      testWidgets('(${b.name}) when it opens then it opens above the trigger, '
          'shifted left, fully on screen and in the theme\'s menu colours', (
        tester,
      ) async {
        await _pumpAt(
          tester,
          _dropdown(() => _items(6)),
          Alignment.bottomRight,
          brightness: b,
        );
        await _openDropdown(tester);

        final item = find.byKey(const ValueKey('m.item0'));
        final menu = _menuOf(tester, item);
        final trigger = tester.getRect(find.byKey(_trigger));
        _expectOnScreen(menu, _screen);
        expect(menu.bottom, lessThanOrEqualTo(trigger.top));

        final popover = ShadTheme.of(tester.element(item)).colorScheme.popover;
        expect(
          find.ancestor(
            of: item,
            matching: find.byWidgetPredicate(
              (w) => w is ShadDecorator && w.decoration?.color == popover,
            ),
          ),
          findsWidgets,
        );
      });
    }
  });

  testWidgets('Given a dropdown at the bottom-left (the sheet tab menu) when '
      'it opens then it opens upwards and stays on screen (it ran off the '
      'bottom edge)', (tester) async {
    await _pumpAt(tester, _dropdown(() => _items(8)), Alignment.bottomLeft);
    await _openDropdown(tester);

    final menu = _menuOf(tester, find.byKey(const ValueKey('m.item0')));
    final trigger = tester.getRect(find.byKey(_trigger));
    _expectOnScreen(menu, _screen);
    expect(menu.bottom, lessThanOrEqualTo(trigger.top));
    expect(menu.left, trigger.left);
  });

  testWidgets('Given a start-aligned dropdown near the right edge when it '
      'opens then it still opens below the trigger, shifted left to stay on '
      'screen', (tester) async {
    await _pumpAt(tester, _dropdown(() => _items(3)), Alignment.topRight);
    await _openDropdown(tester);

    final menu = _menuOf(tester, find.byKey(const ValueKey('m.item0')));
    final trigger = tester.getRect(find.byKey(_trigger));
    _expectOnScreen(menu, _screen);
    expect(menu.top, greaterThanOrEqualTo(trigger.bottom));
    expect(menu.width, greaterThan(trigger.width));
  });

  testWidgets('Given an end-aligned dropdown near the left edge when it opens '
      'then it shifts right to stay on screen', (tester) async {
    await _pumpAt(
      tester,
      _dropdown(
        () => _items(3),
        anchor: const ShadAnchor(
          childAlignment: AlignmentDirectional.bottomEnd,
          overlayAlignment: AlignmentDirectional.topEnd,
          offset: Offset(0, 4),
        ),
      ),
      Alignment.topLeft,
    );
    await _openDropdown(tester);

    _expectOnScreen(
      _menuOf(tester, find.byKey(const ValueKey('m.item0'))),
      _screen,
    );
  });

  testWidgets('Given a dropdown taller than the room above and below its '
      'trigger when it opens then it fits beside the trigger and scrolls to '
      'its last item', (tester) async {
    const size = Size(800, 400);
    await _pumpAt(
      tester,
      _dropdown(() => _items(40)),
      const Alignment(0, 0.2),
      size: size,
    );
    await _openDropdown(tester);

    final menu = _menuOf(tester, find.byKey(const ValueKey('m.item0')));
    final trigger = tester.getRect(find.byKey(_trigger));
    _expectOnScreen(menu, size);
    // The larger side, above the trigger.
    expect(menu.bottom, lessThanOrEqualTo(trigger.top));

    final last = find.byKey(const ValueKey('m.item39'));
    await tester.scrollUntilVisible(
      last,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.getRect(last).bottom, lessThanOrEqualTo(size.height));
  });

  testWidgets('Given a dropdown near the bottom-right corner when a submenu '
      'opens then the submenu stays on screen', (tester) async {
    await _pumpAt(
      tester,
      _dropdown(
        () => [
          ..._items(2),
          WonkyMenuSubmenu(
            key: const ValueKey('m.sub'),
            label: 'More',
            children: _items(12, prefix: 's'),
          ),
        ],
      ),
      Alignment.bottomRight,
    );
    await _openDropdown(tester);
    await tester.tap(find.byKey(const ValueKey('m.sub')));
    await tester.pumpAndSettle();

    final sub = _menuOf(tester, find.byKey(const ValueKey('s.item0')));
    _expectOnScreen(sub, _screen);
  });

  for (final corner in [Alignment.bottomRight, Alignment.bottomLeft]) {
    testWidgets('Given a context menu region when right-clicked near the '
        '$corner corner then the menu stays on screen', (tester) async {
      await pumpWonky(
        tester,
        WonkyContextMenuRegion(
          entries: () => _items(12),
          child: const SizedBox.expand(),
        ),
        size: _screen,
      );
      final at =
          corner.alongSize(_screen) - corner.alongOffset(const Offset(10, 10));
      await tester.tapAt(at, buttons: kSecondaryButton);
      await tester.pumpAndSettle();

      _expectOnScreen(
        _menuOf(tester, find.byKey(const ValueKey('m.item0'))),
        _screen,
      );
    });
  }

  testWidgets('Given a context menu taller than the room above and below the '
      'pointer when right-clicked then it fits on screen and scrolls', (
    tester,
  ) async {
    const size = Size(800, 400);
    await pumpWonky(
      tester,
      WonkyContextMenuRegion(
        entries: () => _items(40),
        child: const SizedBox.expand(),
      ),
      size: size,
    );
    await tester.tapAt(const Offset(400, 220), buttons: kSecondaryButton);
    await tester.pumpAndSettle();

    _expectOnScreen(
      _menuOf(tester, find.byKey(const ValueKey('m.item0'))),
      size,
    );
  });

  group('Given WonkyMenuPlacement', () {
    test('when mirroring a below-the-trigger anchor then the fallback opens '
        'above it with the gap mirrored', () {
      final a = WonkyMenuPlacement.onScreen(
        const ShadAnchor(
          childAlignment: AlignmentDirectional.bottomStart,
          overlayAlignment: AlignmentDirectional.topStart,
          offset: Offset(0, 4),
        ),
      );
      expect(a.targetAnchor, AlignmentDirectional.bottomStart);
      expect(a.followerAnchor, AlignmentDirectional.bottomEnd);
      expect(a.offset, const Offset(0, 4));
      expect(a.fallback!.targetAnchor, AlignmentDirectional.topStart);
      expect(a.fallback!.followerAnchor, AlignmentDirectional.topEnd);
      expect(a.fallback!.offset, const Offset(0, -4));
    });

    test('when sizing a menu then it may use the larger side of its '
        'trigger', () {
      // 800 - 100 - 8 margin - 10 chrome.
      expect(
        WonkyMenuPlacement.itemsMaxHeight(800, below: 100, above: 80),
        682,
      );
      // 700 above the trigger is more than 800 - 720 below it.
      expect(
        WonkyMenuPlacement.itemsMaxHeight(800, below: 720, above: 700),
        682,
      );
      // Tiny windows still show a few items.
      expect(
        WonkyMenuPlacement.itemsMaxHeight(100, below: 50, above: 50),
        WonkyMenuPlacement.minItemsHeight,
      );
    });
  });
}
