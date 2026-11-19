import '../core/game_rules.dart';
import '../core/level_plan.dart';
import '../core/missions.dart';
import '../core/stats.dart';
import 'unblock_engine.dart';

class UnblockRules extends GameRules<UnblockLevel> {
  @override
  String get gameId => 'game-008-unblock-me-escape';

  @override
  List<String> get optionalMechanics => const ['wall', 'timer', 'move_limit'];

  @override
  List<GameModeId> get modes => const [
        GameModeId.campaign,
        GameModeId.endless,
        GameModeId.timeAttack,
        GameModeId.zen,
        GameModeId.daily,
        GameModeId.weekly,
        GameModeId.challenge,
      ];

  @override
  List<GameStat> get gameStats => const [
        GameStat('blocks_moved', 'Kaydırılan blok', 'Blocks moved', scale: 100),
        GameStat('perfect_escapes', 'Kusursuz kaçış', 'Perfect escapes', scale: 5),
        GameStat('escapes', 'Kaçış', 'Escapes', scale: 10),
      ];

  @override
  List<MissionTemplate> get missionTemplates => const [
        MissionTemplate('moved', 'blocks_moved', [40, 100, 200]),
        MissionTemplate('perfect', 'perfect_escapes', [1, 3, 5], coinReward: 80),
      ];

  @override
  UnblockLevel generate(LevelSpec spec) => generateUnblock(spec);

  @override
  Validation validate(UnblockLevel l, LevelSpec spec) {
    final occ = <int>{};
    for (var i = 0; i < l.blocks.length; i++) {
      final b = l.blocks[i];
      for (var k = 0; k < b.len; k++) {
        final c = b.horizontal ? b.line * kBoard + l.start[i] + k : (l.start[i] + k) * kBoard + b.line;
        if (!occ.add(c)) return const Validation.fail('overlap');
      }
    }
    if (isSolved(l.blocks, l.start)) return const Validation.fail('already solved');
    final sol = solveUnblock(l.blocks, l.start);
    if (sol == null) return const Validation.fail('unsolvable');
    if (sol.length != l.minMoves) return const Validation.fail('par mismatch');
    if (l.minMoves < 2) return const Validation.fail('too easy');
    return Validation.ok(sol.length);
  }

  static int stars(UnblockGame g) {
    if (!g.won) return 0;
    final par = g.level.minMoves;
    if (g.moves <= par) return 3;
    if (g.moves <= (par * 1.5).ceil() + 1) return 2;
    return 1;
  }
}

GameRules createRules() => UnblockRules();
