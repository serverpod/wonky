import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides/features/editor_screen/deck_editor_controller.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/testing.dart';

import '../harness/deck_harness.dart';

/// The accessibility checker's commands (Slides 03 §17.4; SL-34).
void main() {
  late DeckBuilder b;
  late String s1, s2, image;
  late DeckHarness d;

  setUp(() {
    b = DeckBuilder(title: 'Checks');
    s1 = b.slide(title: 'Intro', body: 'Hello');
    s2 = b.slide(layoutKey: 'blank');
    image = b.element(s2, ElementKind.image);
    d = DeckHarness.open(fixture: b);
  });
  tearDown(() => d.dispose());

  Future<Map<String, Object?>> check() async {
    final r = await d.h.invoke(
      'slides.tools.accessibilityCheck',
      const {},
      InvocationSource.mcp,
    );
    return (r.data! as Map).cast<String, Object?>();
  }

  List<String> rulesOf(Map<String, Object?> report) => [
    for (final i in report['issues']! as List) (i as Map)['rule'] as String,
  ];

  test('when an agent checks the deck then the report lists the issues with '
      'messages, and the panel stays closed', () async {
    final report = await check();

    expect(rulesOf(report), containsAll(['missingTitle', 'missingAltText']));
    final alt = (report['issues']! as List)
        .cast<Map<Object?, Object?>>()
        .firstWhere((i) => i['rule'] == 'missingAltText');
    expect(alt['elementId'], image);
    expect(alt['slideId'], s2);
    expect(alt['message'], 'Missing alt text');
    expect(alt['fixable'], isTrue);
    expect(report['errors'], 1);
    expect(d.services.panels.isOpen('slides.panel.accessibility'), isFalse);
  });

  test('when an issue is fixed with alt text then it is gone, and undo '
      'brings it back', () async {
    await d.run('slides.a11y.fix', {
      'rule': 'missingAltText',
      'slideId': s2,
      'elementId': image,
      'altText': 'A chart of sales',
    });

    expect(d.model.element(image)!.altText, 'A chart of sales');
    expect(rulesOf(await check()), isNot(contains('missingAltText')));
    await d.undo();
    expect(rulesOf(await check()), contains('missingAltText'));
  });

  test('when an agent fixes alt text without a text then it is refused; '
      'decorative works', () async {
    final r = await d.h.invoke('slides.a11y.fix', {
      'rule': 'missingAltText',
      'slideId': s2,
      'elementId': image,
    }, InvocationSource.mcp);
    expect(r.status, CommandStatus.failed);

    await d.h.invoke('slides.a11y.fix', {
      'rule': 'missingAltText',
      'slideId': s2,
      'elementId': image,
      'decorative': true,
    }, InvocationSource.mcp);
    expect(d.model.element(image)!.decorative, isTrue);
  });

  test('when an unfixable rule is asked for then the fix is disabled with '
      'a reason', () {
    final st = d.services.dispatcher.stateOf('slides.a11y.fix', {
      'rule': 'missingTitle',
      'slideId': s2,
    });
    expect(st.enabled, isFalse);
    expect(st.disabledReason, 'This issue has no automatic fix');
  });

  test('when Go to runs from the outline then Normal view shows the slide '
      'with the element selected', () async {
    d.editor.setMode(DeckViewMode.outline);

    await d.run('slides.a11y.goTo', {'slideId': s2, 'elementId': image});

    expect(d.editor.mode, DeckViewMode.normal);
    expect(d.editor.currentSlideId, s2);
    expect(d.editor.selectedElementIds, [image]);
    expect(s1, isNot(s2));
  });
}
