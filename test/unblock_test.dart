import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_008_unblock_me_escape/main.dart';

void main() {
  test('blocks cannot move through other blocks or board edges', () {
    final board = createLevel(0);
    expect(board.canMove('X', -1), isFalse);
    expect(board.canMove('X', 1), isTrue);
    expect(board.canMove('X', 2), isFalse);
    expect(board.move('X', 1), isTrue);
    expect(board.moves, 1);
    expect(board.block('X').col, 1);
    expect(board.move('X', 1), isFalse);
  });

  test('moving obstacle clears target exit', () {
    final board = createLevel(0);
    expect(board.solved, isFalse);
    expect(board.move('A', 3), isTrue);
    expect(board.solved, isTrue);
  });

  testWidgets('renders selectable blocks and move controls', (tester) async {
    await tester.pumpWidget(const UnblockApp());
    expect(find.byKey(const ValueKey('block-X')), findsOneWidget);
    expect(find.byKey(const ValueKey('block-A')), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
    expect(find.text('Next level'), findsOneWidget);
  });
}
