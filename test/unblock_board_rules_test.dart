import 'package:flutter_test/flutter_test.dart';
import 'package:game_008_unblock_me_escape/main.dart';

void main() {
  test('blocks cannot cross another block or leave the board', () {
    final board = UnblockBoard([
      SlidingBlock('X', 2, 0, 2, Axis.horizontal, target: true),
      SlidingBlock('A', 0, 3, 3, Axis.vertical),
    ]);
    expect(board.canMove('X', 2), isFalse);
    expect(board.move('X', 2), isFalse);
    expect(board.moves, 0);
    expect(board.canMove('X', -1), isFalse);
    expect(board.canMove('A', -1), isFalse);
  });

  test('successful moves change only selected axis and count once', () {
    final board = UnblockBoard([
      SlidingBlock('X', 2, 0, 2, Axis.horizontal, target: true),
      SlidingBlock('A', 0, 3, 2, Axis.vertical),
    ]);
    expect(board.move('A', 1), isTrue);
    expect(board.block('A').row, 1);
    expect(board.block('A').col, 3);
    expect(board.moves, 1);
    expect(board.move('X', 1), isTrue);
    expect(board.block('X').row, 2);
    expect(board.block('X').col, 1);
    expect(board.moves, 2);
  });
}
