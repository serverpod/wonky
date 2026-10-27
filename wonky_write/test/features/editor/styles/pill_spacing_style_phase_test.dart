import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write/features/editor/attributions/wonky_attributions.dart';
import 'package:wonky_write/features/editor/styles/style_phases.dart';

ParagraphComponentViewModel _paragraph(AttributionStyleBuilder styler) {
  final text = AttributedText('Use New now')
    ..addAttribution(ChipAttribution.plain, const SpanRange(4, 6));
  return ParagraphComponentViewModel(
    nodeId: 'p',
    blockType: paragraphAttribution,
    text: text,
    textStyleBuilder: styler,
    selectionColor: const Color(0x00000000),
  );
}

void main() {
  final document = MutableDocument(nodes: []);

  TextComponentViewModel styleOnce(
    PillSpacingStylePhase phase,
    AttributionStyleBuilder styler,
  ) =>
      phase
              .style(
                document,
                SingleColumnLayoutViewModel(
                  componentViewModels: [_paragraph(styler)],
                ),
              )
              .componentViewModels
              .single
          as TextComponentViewModel;

  test('when the text gets pill gaps then the spaces next to the chip and '
      'its last character are widened (Write 11 §7.2)', () {
    final out = styleOnce(PillSpacingStylePhase(), (_) => const TextStyle());

    expect(
      out.text.getAllAttributionsAt(3),
      contains(PillGapAttribution.space),
    );
    expect(out.text.getAllAttributionsAt(6), contains(PillGapAttribution.pill));
    expect(
      out.text.getAllAttributionsAt(7),
      contains(PillGapAttribution.space),
    );
  });

  test('when the theme changes then the output carries the new text style '
      'builder (dark mode shows the light colors otherwise)', () {
    final phase = PillSpacingStylePhase();
    TextStyle light(Set<Attribution> _) =>
        const TextStyle(color: Color(0xff000000));
    TextStyle dark(Set<Attribution> _) =>
        const TextStyle(color: Color(0xffffffff));

    styleOnce(phase, light);
    final out = styleOnce(phase, dark);

    expect(out.textStyleBuilder({}).color, const Color(0xffffffff));
  });
}
