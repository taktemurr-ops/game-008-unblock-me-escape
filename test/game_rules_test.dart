import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:game_008_unblock_me_escape/game/rules.dart';
import 'package:game_008_unblock_me_escape/game/unblock_engine.dart';

void main() {
  final rules = UnblockRules();
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  test('blocks slide only along their axis into free cells', () {
    const blocks = [Block(true, 2, kExitRow), Block(false, 3, 3), Block(true, 1, 0, fixed: true)];
    final pos = [0, 1, 4];
    expect(reachable(blocks, pos, 0), equals([1]));
    expect(reachable(blocks, pos, 2), isEmpty, reason: 'walls never move');
    expect(reachable(blocks, pos, 1).contains(3), isTrue);
  });

  test('BFS finds the optimal escape', () {
    const blocks = [Block(true, 2, kExitRow), Block(false, 3, 3)];
    final sol = solveUnblock(blocks, [0, 1])!;
    expect(sol.length, 2);
  });

  test('following hints escapes in exactly par moves', () {
    final l = rules.build(planner.spec(25)).puzzle;
    final g = UnblockGame(l);
    while (!g.won) {
      final h = g.hint()!;
      expect(g.moveTo(h[0], h[1]), isTrue);
    }
    expect(g.moves, l.minMoves);
    expect(UnblockRules.stars(g), 3);
  });

  test('difficulty grows with level', () {
    final easy = rules.build(planner.spec(1)).puzzle.minMoves;
    final hard = rules.build(planner.spec(4090)).puzzle.minMoves;
    expect(hard, greaterThan(easy));
  });

  test('resume restores state', () {
    final l = rules.build(planner.spec(30)).puzzle;
    final g = UnblockGame(l);
    final h = g.hint()!;
    g.moveTo(h[0], h[1]);
    expect(UnblockGame.restore(l, g.serialize()).serialize(), g.serialize());
  });

  test('levels 1..60 valid', () {
    for (var n = 1; n <= 60; n++) {
      expect(rules.build(planner.spec(n)).validation.ok, isTrue, reason: 'level $n');
    }
  });
}
