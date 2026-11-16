import 'package:flutter/material.dart';

void main() => runApp(const UnblockApp());

enum Axis { horizontal, vertical }

class SlidingBlock {
  SlidingBlock(this.id, this.row, this.col, this.length, this.axis,
      {this.target = false});

  final String id;
  int row;
  int col;
  final int length;
  final Axis axis;
  final bool target;
}

class UnblockBoard {
  UnblockBoard(this.blocks, {this.size = 6});

  final List<SlidingBlock> blocks;
  final int size;
  int moves = 0;

  SlidingBlock block(String id) => blocks.firstWhere((b) => b.id == id);

  String? occupant(int row, int col, {String? except}) {
    for (final b in blocks) {
      if (b.id == except) continue;
      for (var i = 0; i < b.length; i++) {
        final r = b.row + (b.axis == Axis.vertical ? i : 0);
        final c = b.col + (b.axis == Axis.horizontal ? i : 0);
        if (r == row && c == col) return b.id;
      }
    }
    return null;
  }

  bool canMove(String id, int delta) {
    if (delta == 0) return false;
    final b = block(id);
    final sign = delta > 0 ? 1 : -1;
    for (var step = 1; step <= delta.abs(); step++) {
      final leading = sign > 0 ? b.length - 1 + step : -step;
      final row = b.row + (b.axis == Axis.vertical ? leading : 0);
      final col = b.col + (b.axis == Axis.horizontal ? leading : 0);
      if (row < 0 || col < 0 || row >= size || col >= size) return false;
      if (occupant(row, col, except: id) != null) return false;
    }
    return true;
  }

  bool move(String id, int delta) {
    if (!canMove(id, delta)) return false;
    final b = block(id);
    if (b.axis == Axis.horizontal) {
      b.col += delta;
    } else {
      b.row += delta;
    }
    moves++;
    return true;
  }

  bool get solved {
    final target = blocks.firstWhere((b) => b.target);
    if (target.axis != Axis.horizontal) return false;
    for (var c = target.col + target.length; c < size; c++) {
      if (occupant(target.row, c, except: target.id) != null) return false;
    }
    return true;
  }
}

UnblockBoard createLevel(int level) {
  if (level.isEven) {
    return UnblockBoard([
      SlidingBlock('X', 2, 0, 2, Axis.horizontal, target: true),
      SlidingBlock('A', 0, 3, 3, Axis.vertical),
      SlidingBlock('B', 3, 1, 2, Axis.horizontal),
      SlidingBlock('C', 4, 4, 2, Axis.vertical),
    ]);
  }
  return UnblockBoard([
    SlidingBlock('X', 2, 1, 2, Axis.horizontal, target: true),
    SlidingBlock('A', 1, 3, 3, Axis.vertical),
    SlidingBlock('B', 0, 0, 2, Axis.horizontal),
    SlidingBlock('C', 4, 1, 3, Axis.horizontal),
  ]);
}

class UnblockApp extends StatelessWidget {
  const UnblockApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Unblock Me Escape',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        home: const UnblockScreen(),
      );
}

class UnblockScreen extends StatefulWidget {
  const UnblockScreen({super.key});

  @override
  State<UnblockScreen> createState() => _UnblockScreenState();
}

class _UnblockScreenState extends State<UnblockScreen> {
  int level = 0;
  late UnblockBoard board = createLevel(level);
  String selected = 'X';

  void moveSelected(int delta) => setState(() => board.move(selected, delta));

  @override
  Widget build(BuildContext context) {
    final block = board.block(selected);
    final solved = board.solved;
    return Scaffold(
      appBar: AppBar(title: const Text('Unblock Me Escape')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Level ${level + 1} • Moves ${board.moves}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Move the blocks to clear the red block\'s exit on the right.'),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(builder: (context, bounds) {
                    final cell = bounds.maxWidth / board.size;
                    return Stack(children: [
                      Container(color: Colors.blueGrey.shade50),
                      for (var i = 0; i <= board.size; i++)
                        Positioned(
                          left: i * cell,
                          top: 0,
                          bottom: 0,
                          child: Container(width: 1, color: Colors.blueGrey.shade200),
                        ),
                      for (var i = 0; i <= board.size; i++)
                        Positioned(
                          top: i * cell,
                          left: 0,
                          right: 0,
                          child: Container(height: 1, color: Colors.blueGrey.shade200),
                        ),
                      for (final b in board.blocks)
                        Positioned(
                          left: b.col * cell + 2,
                          top: b.row * cell + 2,
                          width: (b.axis == Axis.horizontal ? b.length : 1) * cell - 4,
                          height: (b.axis == Axis.vertical ? b.length : 1) * cell - 4,
                          child: Semantics(
                            button: true,
                            label: 'Select block ${b.id}',
                            child: InkWell(
                              key: ValueKey('block-${b.id}'),
                              onTap: () => setState(() => selected = b.id),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: b.target ? Colors.red.shade400 : Colors.teal.shade300,
                                  border: Border.all(
                                    color: selected == b.id ? Colors.black87 : Colors.transparent,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(b.id, style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20)),
                              ),
                            ),
                          ),
                        ),
                    ]);
                  }),
                ),
              ),
              const SizedBox(height: 16),
              Text(solved ? 'Exit cleared! Level complete.' : 'Selected: $selected',
                  key: const ValueKey('status')),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton.filledTonal(
                  tooltip: 'Move backward',
                  onPressed: board.canMove(selected, -1) ? () => moveSelected(-1) : null,
                  icon: Icon(block.axis == Axis.horizontal
                      ? Icons.arrow_back : Icons.arrow_upward),
                ),
                const SizedBox(width: 24),
                IconButton.filledTonal(
                  tooltip: 'Move forward',
                  onPressed: board.canMove(selected, 1) ? () => moveSelected(1) : null,
                  icon: Icon(block.axis == Axis.horizontal
                      ? Icons.arrow_forward : Icons.arrow_downward),
                ),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 12, children: [
                OutlinedButton(
                  onPressed: () => setState(() => board = createLevel(level)),
                  child: const Text('Restart'),
                ),
                FilledButton(
                  onPressed: solved ? () => setState(() {
                    level++;
                    board = createLevel(level);
                    selected = 'X';
                  }) : null,
                  child: const Text('Next level'),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
