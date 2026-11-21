import 'dart:collection';

import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/rng.dart';

const int kBoard = 6;
const int kExitRow = 2;

class Block {
  final bool horizontal;
  final int len;
  final bool fixed; // walls never move
  final int line; // row for horizontal, column for vertical
  const Block(this.horizontal, this.len, this.line, {this.fixed = false});
}

class UnblockLevel {
  final List<Block> blocks; // block 0 = the red target
  final List<int> start; // position along the axis per block
  final int minMoves;
  final int moveLimit;
  final int timeLimit;
  final int difficulty;
  final int seed;

  const UnblockLevel({
    required this.blocks,
    required this.start,
    required this.minMoves,
    required this.moveLimit,
    required this.timeLimit,
    required this.difficulty,
    required this.seed,
  });
}

List<int> _cellsOf(Block b, int pos) => [
      for (var k = 0; k < b.len; k++) b.horizontal ? b.line * kBoard + pos + k : (pos + k) * kBoard + b.line
    ];

List<int> occupancy(List<Block> blocks, List<int> pos, {int skip = -1}) {
  final g = List<int>.filled(kBoard * kBoard, -1);
  for (var i = 0; i < blocks.length; i++) {
    if (i == skip) continue;
    for (final c in _cellsOf(blocks[i], pos[i])) {
      g[c] = i;
    }
  }
  return g;
}

/// All positions block [i] can slide to.
List<int> reachable(List<Block> blocks, List<int> pos, int i) {
  final b = blocks[i];
  if (b.fixed) return const [];
  final occ = occupancy(blocks, pos);
  final out = <int>[];
  bool free(int p) {
    if (p < 0 || p + b.len > kBoard) return false;
    for (final c in _cellsOf(b, p)) {
      if (occ[c] != -1 && occ[c] != i) return false;
    }
    return true;
  }

  for (var p = pos[i] - 1; free(p); p--) {
    out.add(p);
  }
  for (var p = pos[i] + 1; free(p); p++) {
    out.add(p);
  }
  return out;
}

bool isSolved(List<Block> blocks, List<int> pos) => pos[0] + blocks[0].len == kBoard;

/// Breadth-first search: shortest solution as (block, newPos) moves.
/// States are packed into one int (3 bits per block; <= 16 blocks keeps
/// the key below 2^53 so it is exact on the web too).
List<List<int>>? solveUnblock(List<Block> blocks, List<int> start, {int maxStates = 120000}) {
  final n = blocks.length;
  int pack(List<int> p) {
    var k = 0;
    for (var i = n - 1; i >= 0; i--) {
      k = k * 8 + p[i];
    }
    return k;
  }

  final prev = <int, int>{}; // state -> parent state
  final how = <int, int>{}; // state -> block * 8 + newPos
  final startKey = pack(start);
  prev[startKey] = -1;
  final q = Queue<List<int>>()..add(start);
  final occ = List<int>.filled(kBoard * kBoard, -1);
  while (q.isNotEmpty) {
    final s = q.removeFirst();
    final sk = pack(s);
    if (s[0] + blocks[0].len == kBoard) {
      final path = <List<int>>[];
      var k = sk;
      while (prev[k] != -1) {
        final h = how[k]!;
        path.add([h ~/ 8, h % 8]);
        k = prev[k]!;
      }
      return path.reversed.toList();
    }
    if (prev.length > maxStates) return null;
    occ.fillRange(0, occ.length, -1);
    for (var i = 0; i < n; i++) {
      final b = blocks[i];
      for (var t = 0; t < b.len; t++) {
        occ[b.horizontal ? b.line * kBoard + s[i] + t : (s[i] + t) * kBoard + b.line] = i;
      }
    }
    for (var i = 0; i < n; i++) {
      final b = blocks[i];
      if (b.fixed) continue;
      for (final dir in const [-1, 1]) {
        var p = s[i];
        while (true) {
          p += dir;
          if (p < 0 || p + b.len > kBoard) break;
          final edge = dir < 0 ? p : p + b.len - 1;
          final cell = b.horizontal ? b.line * kBoard + edge : edge * kBoard + b.line;
          if (occ[cell] != -1) break;
          final ns = List.of(s);
          ns[i] = p;
          final k = pack(ns);
          if (prev.containsKey(k)) continue;
          prev[k] = sk;
          how[k] = i * 8 + p;
          q.add(ns);
        }
      }
    }
  }
  return null;
}

UnblockLevel generateUnblock(LevelSpec spec) {
  final r = SeededRandom(spec.seed);
  final d = spec.difficulty;
  // Target band of optimal moves per difficulty.
  const bands = [[2, 5], [4, 8], [6, 10], [8, 13], [10, 16], [12, 19], [14, 22], [16, 26], [18, 30], [20, 40]];
  final band = bands[(d - 1).clamp(0, 9)];
  List<Block>? bestBlocks;
  List<int>? bestPos;
  var bestMoves = -1;
  final tries = 8 + d * 2;
  for (var t = 0; t < tries; t++) {
    final blocks = <Block>[const Block(true, 2, kExitRow)];
    final pos = <int>[r.range(0, 2)];
    final count = 5 + d + r.nextInt(3);
    final walls = spec.has('wall') ? 1 + r.nextInt(2) : 0;
    var guard = 0;
    while (blocks.length < count + walls && guard++ < 300) {
      final isWall = blocks.length >= count;
      final horizontal = isWall ? true : r.chance(0.5);
      final len = isWall ? 1 : (r.chance(0.25) ? 3 : 2);
      final line = r.nextInt(kBoard);
      if (horizontal && line == kExitRow && !isWall) continue; // would block the exit forever
      final p = r.nextInt(kBoard - len + 1);
      final b = Block(horizontal, len, line, fixed: isWall);
      if (isWall && line == kExitRow) continue;
      final occ = occupancy(blocks, pos);
      if (_cellsOf(b, p).any((c) => occ[c] != -1)) continue;
      blocks.add(b);
      pos.add(p);
    }
    if (isSolved(blocks, pos)) continue;
    final sol = solveUnblock(blocks, pos, maxStates: 25000);
    if (sol == null) continue;
    final m = sol.length;
    final inBand = m >= band[0] && m <= band[1];
    final bestInBand = bestMoves >= band[0] && bestMoves <= band[1];
    if (bestBlocks == null || (inBand && (!bestInBand || m > bestMoves)) || (!bestInBand && m > bestMoves)) {
      bestBlocks = blocks;
      bestPos = pos;
      bestMoves = m;
    }
    if (inBand && m >= (band[0] + band[1]) ~/ 2) break;
  }
  bestBlocks ??= const [Block(true, 2, kExitRow), Block(false, 2, 4)];
  bestPos ??= [0, 1];
  return UnblockLevel(
    blocks: bestBlocks,
    start: bestPos,
    minMoves: bestMoves,
    moveLimit: spec.has('move_limit') && bestMoves > 0 ? bestMoves * 2 + 3 : 0,
    timeLimit: spec.mode == GameModeId.timeAttack ? 90 : (spec.has('timer') ? 30 + bestMoves * 8 : 0),
    difficulty: d,
    seed: spec.seed,
  );
}

class UnblockGame {
  final UnblockLevel level;
  late List<int> pos;
  int moves = 0;
  int bonusMoves = 0;
  final List<String> _undo = [];
  List<List<int>> _plan = [];
  String _planKey = '';

  UnblockGame(this.level) {
    pos = List.of(level.start);
  }

  List<Block> get blocks => level.blocks;
  bool get won => isSolved(blocks, pos);
  int get movesLeft => level.moveLimit == 0 ? -1 : level.moveLimit + bonusMoves - moves;
  bool get lost => !won && level.moveLimit > 0 && movesLeft <= 0;

  List<int> options(int i) => reachable(blocks, pos, i);

  bool moveTo(int i, int p) {
    if (!options(i).contains(p)) return false;
    _undo.add(_snap());
    if (_undo.length > 80) _undo.removeAt(0);
    pos[i] = p;
    moves++;
    if (_plan.isNotEmpty && _plan.first[0] == i && _plan.first[1] == p) {
      _plan = _plan.sublist(1);
      _planKey = pos.join(',');
    } else {
      _plan = [];
    }
    return true;
  }

  /// Next optimal move (block, position).
  List<int>? hint() {
    if (_plan.isNotEmpty && _planKey == pos.join(',')) return _plan.first;
    final s = solveUnblock(blocks, pos);
    if (s == null || s.isEmpty) return null;
    _plan = s;
    _planKey = pos.join(',');
    return s.first;
  }

  bool get canUndo => _undo.isNotEmpty;
  void undo() {
    if (_undo.isNotEmpty) _restore(_undo.removeLast());
  }

  void rescue() => bonusMoves += 10;

  String _snap() => '${pos.join(',')}#$moves#$bonusMoves';
  void _restore(String s) {
    final p = s.split('#');
    pos = p[0].split(',').map(int.parse).toList();
    moves = int.parse(p[1]);
    bonusMoves = int.parse(p[2]);
  }

  String serialize() => _snap();
  static UnblockGame restore(UnblockLevel l, String s) => UnblockGame(l).._restore(s);
}
