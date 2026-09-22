import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';

/// The renderer reads the payload matching [FlowchartBlock.variant] with a
/// null assertion (six of them in topic_view.dart). That is only safe if the
/// block cannot exist without it, so the constructor must refuse one.
void main() {
  test('a FlowchartBlock without its variant payload is refused', () {
    expect(
      () => FlowchartBlock(variant: FlowchartVariant.severity),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => FlowchartBlock(
        variant: FlowchartVariant.cycle,
        linear: const LinearFlowchart(steps: []),
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('a FlowchartBlock with its payload is accepted', () {
    expect(
      const FlowchartBlock(
        variant: FlowchartVariant.linear,
        linear: LinearFlowchart(steps: []),
      ).linear,
      isNotNull,
    );
  });
}
