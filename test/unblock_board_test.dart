import 'package:flutter_test/flutter_test.dart';
import 'package:game_008_unblock_me_escape/main.dart';

void main() {
  group('UnblockBoard movement', () {
    test('rejects collisions and out-of-bounds movement', () {
      final board = UnblockBoard([
        SlidingBlock('X', 2, 0, 2, Axis.horizontal, target: true),
        SlidingBlock('A', 2, 3, 2, Axis.vertical),
      ]);
      expect(board.canMove('X', 2), isFalse);
      expect(board.move('X', 2), isFalse);
      expect(board.moves, 0);
      expect(board.canMove('X', -1), isFalse);
    });

    test('moves only along block axis and increments move count once', () {
      final board = UnblockBoard([
        SlidingBlock('X', 2, 0, 2, Axis.horizontal, target: true),
        SlidingBlock('A', 0, 4, 2, Axis.vertical),
      ]);
      expect(board.move('X', 2), isTrue);
      expect(board.block('X').col, 2);
      expect(board.block('X').row, 2);
      expect(board.moves, 1);
      expect(board.move('A', 1), isTrue);
      expect(board.block('A').row, 1);
      expect(board.block('A').col, 4);
      expect(board.moves, 2);
    });

    test('exit is blocked until target lane is cleared', () {
      final board = UnblockBoard([
        SlidingBlock('X', 2, 0, 2, Axis.horizontal, target: true),
        SlidingBlock('A', 1, 3, 3, Axis.vertical),
      ]);
      expect(board.solved, isFalse);
      expect(board.move('A', -1), isTrue);
      expect(board.solved, isFalse);
      expect(board.move('A', 2), isTrue);
      expect(board.solved, isFalse);
    });

    test('level factories create boards with a target', () {
      for (final level in [0, 1, 2, 3]) {
        final board = createLevel(level);
        expect(board.blocks.where((b) => b.target).length, 1);
        expect(board.size, 6);
      }
    });
  });
}
