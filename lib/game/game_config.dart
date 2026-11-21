import 'package:flutter/material.dart';

import 'package:studio_core/app/game_api.dart';
import 'rules.dart';
import 'unblock_view.dart';

final gameConfig = GameConfig(
  gameId: 'game-008-unblock-me-escape',
  title: const ['Bloğu Kurtar', 'Unblock Me Escape', 'Block-Ausbruch', 'Desbloquea y Escapa', 'Débloque et Évade-toi'],
  tagline: const [
    'Blokları kaydır, kırmızı bloğu kurtar!',
    'Slide the blocks, free the red block!',
    'Schiebe Blöcke, befreie den roten!',
    '¡Desliza bloques y libera el rojo!',
    'Glissez les blocs, libérez le rouge !',
  ],
  seedColor: const Color(0xFF8D6E63),
  icon: Icons.view_quilt,
  rules: UnblockRules(),
  buildPlay: (ctx) => UnblockView(ctx: ctx),
  tutorial: const [
    TutorialStep(Icons.open_with, [
      'Blokları yalnızca uzun kenarları yönünde sürükleyebilirsin.',
      'Blocks slide only along their long side.',
      'Blöcke gleiten nur entlang ihrer Längsseite.',
      'Los bloques solo se deslizan a lo largo.',
      'Les blocs glissent dans leur sens long.',
    ]),
    TutorialStep(Icons.keyboard_double_arrow_right, [
      'Kırmızı bloğu sağdaki sarı çıkışa ulaştır. Gri duvarlar hareket etmez.',
      'Get the red block to the yellow exit on the right. Grey walls never move.',
      'Bringe den roten Block zum gelben Ausgang. Graue Wände sind fest.',
      'Lleva el bloque rojo a la salida amarilla.',
      'Amenez le bloc rouge à la sortie jaune.',
    ]),
    TutorialStep(Icons.star, [
      'Par (en az hamle) kadar hamlede bitirirsen 3 yıldız alırsın.',
      'Finish in par (minimum) moves for 3 stars.',
      'Mit Par-Zügen gibt es 3 Sterne.',
      'Termina en par para 3 estrellas.',
      'Finissez au par pour 3 étoiles.',
    ]),
  ],
);
