import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mala_beads.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal harness: a counter driving [MalaBeads], so we can assert that
/// tapping the bead area increments the displayed count and the strand only
/// ever advances forward.
class _Harness extends StatefulWidget {
  const _Harness();
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  int _total = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text('count:$_total'),
            Expanded(
              child: MalaBeads(
                total: _total,
                beadInRound: _total % 108,
                beadsPerRound: 108,
                beadColor: const Color(0xFF8D6E63),
                threadColor: const Color(0xFFC62828),
                onTap: () => setState(() => _total++),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('tapping the bead area increments the displayed count',
      (tester) async {
    await tester.pumpWidget(const _Harness());
    expect(find.text('count:0'), findsOneWidget);

    await tester.tap(find.byType(MalaBeads));
    await tester.pump(); // start animation
    expect(find.text('count:1'), findsOneWidget);

    await tester.tap(find.byType(MalaBeads));
    await tester.pumpAndSettle();
    expect(find.text('count:2'), findsOneWidget);
  });

  testWidgets('disabled beads do not increment', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MalaBeads(
            total: 0,
            beadInRound: 0,
            beadsPerRound: 108,
            enabled: false,
            beadColor: const Color(0xFF8D6E63),
            threadColor: const Color(0xFFC62828),
            onTap: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MalaBeads));
    await tester.pump();
    expect(taps, 0);
  });
}
