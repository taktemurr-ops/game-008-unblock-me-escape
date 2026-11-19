import 'package:flutter/material.dart';

import '../app/game_api.dart';
import '../app/play_kit.dart';
import '../app/services/audio.dart';
import '../core/game_rules.dart';
import '../core/level_plan.dart';
import '../core/rng.dart';
import 'rules.dart';
import 'unblock_engine.dart';

/// Drag blocks along their axis; the red block must leave through the gap.
class UnblockView extends StatefulWidget {
  final PlayContext ctx;
  const UnblockView({super.key, required this.ctx});

  @override
  State<UnblockView> createState() => _UnblockViewState();
}

class _UnblockViewState extends State<UnblockView> with RoundClock {
  late UnblockGame game;
  int? _drag;
  double _dragOffset = 0;
  List<int>? _hint;
  int _hints = 0;
  int _undos = 0;
  int _solved = 0;
  int _moved = 0;
  bool _ended = false;

  PlayContext get ctx => widget.ctx;
  bool get _chain => const [GameModeId.endless, GameModeId.timeAttack, GameModeId.zen].contains(ctx.spec.mode);

  @override
  void initState() {
    super.initState();
    final level = (ctx.generated as GeneratedLevel<UnblockLevel>).puzzle;
    final snap = ctx.resume['snap'];
    game = snap is String ? UnblockGame.restore(level, snap) : UnblockGame(level);
    _hints = (ctx.resume['hints'] as num?)?.toInt() ?? 0;
    _solved = (ctx.resume['solved'] as num?)?.toInt() ?? 0;
    startClock(initialSeconds: (ctx.resume['secs'] as num?)?.toInt() ?? 0, limit: level.timeLimit);
  }

  @override
  void dispose() {
    stopClock();
    super.dispose();
  }

  @override
  void onTimeUp() => _end(_chain ? _solved > 0 : game.won);

  void _persist() => ctx.saveResume({'snap': game.serialize(), 'secs': seconds, 'hints': _hints, 'solved': _solved});

  void _commit(int i, int target) {
    if (target == game.pos[i]) return;
    if (!game.moveTo(i, target)) {
      ctx.sfx(Sfx.error);
      return;
    }
    _moved++;
    _hint = null;
    ctx.sfx(Sfx.place);
    _persist();
    if (game.won) {
      ctx.sfx(Sfx.win);
      if (_chain) {
        _solved++;
        final next = ctx.spec.copyWith(seed: mixSeed([ctx.spec.seed, _solved]));
        setState(() => game = UnblockGame(UnblockRules().build(next).puzzle));
        _persist();
        return;
      }
      _end(true);
    } else if (game.lost) {
      _offerContinue();
    }
  }

  Future<void> _offerContinue() async {
    clockPaused = true;
    final again = await ctx.requestContinue();
    clockPaused = false;
    if (!mounted) return;
    if (again) {
      setState(game.rescue);
    } else {
      _end(false);
    }
  }

  void _end(bool won) {
    if (_ended) return;
    _ended = true;
    stopClock();
    final stars = _chain ? (_solved >= 8 ? 3 : _solved >= 3 ? 2 : 1) : UnblockRules.stars(game);
    ctx.finish(RoundResult(
      won: won,
      score: _chain ? _solved * 300 : (won ? (2000 - (game.moves - game.level.minMoves) * 50).clamp(100, 2000) : 0),
      stars: won ? stars : 0,
      seconds: seconds,
      moves: game.moves,
      hintsUsed: _hints,
      undosUsed: _undos,
      gameStats: {
        'blocks_moved': _moved,
        'perfect_escapes': won && !_chain && game.moves <= game.level.minMoves ? 1 : 0,
        'escapes': won ? 1 + _solved : _solved,
      },
    ));
  }

  Future<void> _useHint() async {
    final h = game.hint();
    if (h == null) return;
    if (!await ctx.requestHint()) return;
    _hints++;
    setState(() => _hint = h);
  }

  @override
  Widget build(BuildContext context) {
    final t = ctx.t;
    return Column(children: [
      PlayHud(items: [
        (Icons.swipe, '${t('moves')}: ${game.moves}'),
        (Icons.flag, 'Par ${game.level.minMoves}'),
        if (game.movesLeft >= 0) (Icons.hourglass_bottom, '${t('moves_left')}: ${game.movesLeft}'),
        (Icons.timer, timeText),
        if (_chain) (Icons.emoji_events, '$_solved'),
      ]),
      Expanded(
        child: LayoutBuilder(builder: (context, c) {
          final side = (c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight) - 32;
          final cell = side / kBoard;
          return Center(
            child: Container(
              width: side + 16,
              height: side + 16,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6D4C41),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(child: CustomPaint(painter: _FloorPainter(cell))),
                Positioned(
                  left: side,
                  top: kExitRow * cell + 4,
                  width: 12,
                  height: cell - 8,
                  child: Container(color: Colors.yellowAccent),
                ),
                for (var i = 0; i < game.blocks.length; i++) _block(i, cell),
              ]),
            ),
          );
        }),
      ),
      BoosterBar(buttons: [
        BoosterButton(Icons.lightbulb, t('hint'), _useHint),
        BoosterButton(Icons.undo, t('undo'), game.canUndo
            ? () {
                setState(() {
                  game.undo();
                  _undos++;
                });
                _persist();
              }
            : null),
        BoosterButton(Icons.refresh, t('restart'), () {
          setState(() {
            while (game.canUndo) {
              game.undo();
            }
          });
          _persist();
        }),
      ]),
    ]);
  }

  Widget _block(int i, double cell) {
    final b = game.blocks[i];
    var p = game.pos[i].toDouble();
    if (_drag == i) {
      final opts = game.options(i)..add(game.pos[i]);
      final lo = opts.reduce((a, b) => a < b ? a : b).toDouble();
      final hi = opts.reduce((a, b) => a > b ? a : b).toDouble();
      p = (p + _dragOffset / cell).clamp(lo, hi);
    }
    final left = b.horizontal ? p * cell : b.line * cell;
    final top = b.horizontal ? b.line * cell : p * cell;
    final w = b.horizontal ? b.len * cell : cell;
    final h = b.horizontal ? cell : b.len * cell;
    final hinted = _hint != null && _hint![0] == i;
    final color = i == 0
        ? const Color(0xFFE53935)
        : b.fixed
            ? const Color(0xFF424242)
            : ctx.pieceColors[(i * 3) % ctx.pieceColors.length];
    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: Semantics(
        label: i == 0 ? 'red block' : (b.fixed ? 'wall' : 'block'),
        child: GestureDetector(
          onPanStart: b.fixed
              ? null
              : (_) => setState(() {
                    _drag = i;
                    _dragOffset = 0;
                  }),
          onPanUpdate: b.fixed
              ? null
              : (d) => setState(() => _dragOffset += b.horizontal ? d.delta.dx : d.delta.dy),
          onPanEnd: b.fixed
              ? null
              : (_) {
                  final opts = game.options(i)..add(game.pos[i]);
                  final lo = opts.reduce((a, b) => a < b ? a : b);
                  final hi = opts.reduce((a, b) => a > b ? a : b);
                  final target = (game.pos[i] + (_dragOffset / cell).round()).clamp(lo, hi);
                  setState(() => _drag = null);
                  _commit(i, target);
                },
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: hinted ? Colors.yellowAccent : Colors.black26, width: hinted ? 4 : 1),
              boxShadow: const [BoxShadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 2)],
            ),
            child: i == 0
                ? const Icon(Icons.keyboard_double_arrow_right, color: Colors.white)
                : (hinted
                    ? Icon(b.horizontal ? Icons.swap_horiz : Icons.swap_vert, color: Colors.white)
                    : null),
          ),
        ),
      ),
    );
  }
}

class _FloorPainter extends CustomPainter {
  final double cell;
  _FloorPainter(this.cell);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF8D6E63);
    for (var y = 0; y < kBoard; y++) {
      for (var x = 0; x < kBoard; x++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x * cell + 2, y * cell + 2, cell - 4, cell - 4), const Radius.circular(6)),
          p,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FloorPainter old) => old.cell != cell;
}
