import 'dart:math';

import 'package:flutter/material.dart';

/// Themed background for the library, one per category (ALL, CARD, LOGIC,
/// BOARD, MATH, WORD, MEMORY, ATTENTION, SPATIAL), each with a light and a
/// dark variant. Everything is drawn in code (no image assets, works
/// offline) and painted once behind the scrolling content inside a
/// RepaintBoundary, so scrolling stays cheap. Switching category crossfades.
class TableTextureBackground extends StatelessWidget {
  const TableTextureBackground({
    super.key,
    required this.child,
    this.category = 'ALL',
  });

  final Widget child;
  final String category;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(children: [
      Positioned.fill(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: RepaintBoundary(
            key: ValueKey('table_texture_${category}_$dark'),
            child: CustomPaint(
              painter: TableTexturePainter(category: category, dark: dark),
              size: Size.infinite,
            ),
          ),
        ),
      ),
      child,
    ]);
  }
}

class TableTexturePainter extends CustomPainter {
  TableTexturePainter({required this.category, required this.dark});
  final String category;
  final bool dark;

  /// (light top, light bottom, dark top, dark bottom, ink) per category.
  static const _palettes = <String, (Color, Color, Color, Color, Color)>{
    'ALL': (
      Color(0xFFF6EEDF),
      Color(0xFFEFE3CC),
      Color(0xFF1E2B25),
      Color(0xFF15201B),
      Color(0xFF6B4A22)
    ),
    'CARD': (
      Color(0xFFE6F1E7),
      Color(0xFFD5E8D8),
      Color(0xFF17432C),
      Color(0xFF0E2E1E),
      Color(0xFF1F5E3A)
    ),
    'LOGIC': (
      Color(0xFFF0F4FB),
      Color(0xFFE4ECF8),
      Color(0xFF172036),
      Color(0xFF101727),
      Color(0xFF3567B8)
    ),
    'BOARD': (
      Color(0xFFF4E6CF),
      Color(0xFFEAD6B5),
      Color(0xFF2E2016),
      Color(0xFF21160E),
      Color(0xFF7A4A22)
    ),
    'MATH': (
      Color(0xFFF2F6EC),
      Color(0xFFE6EEDB),
      Color(0xFF1F3329),
      Color(0xFF16261E),
      Color(0xFF3F6B45)
    ),
    'WORD': (
      Color(0xFFFAF3E6),
      Color(0xFFF1E5CD),
      Color(0xFF2C2620),
      Color(0xFF201B16),
      Color(0xFF8A6A3A)
    ),
    'MEMORY': (
      Color(0xFFF3EEFA),
      Color(0xFFE8E0F5),
      Color(0xFF231C33),
      Color(0xFF181325),
      Color(0xFF6C4BB0)
    ),
    'ATTENTION': (
      Color(0xFFFFF3E8),
      Color(0xFFFCE5D2),
      Color(0xFF30211A),
      Color(0xFF221712),
      Color(0xFFD06A1E)
    ),
    'SPATIAL': (
      Color(0xFFEDF7F2),
      Color(0xFFDDEFE6),
      Color(0xFF15302A),
      Color(0xFF0E231E),
      Color(0xFF2E8A66)
    ),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final p = _palettes[category] ?? _palettes['ALL']!;
    final ink = dark ? Colors.white : p.$5;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -.4),
          radius: 1.3,
          colors: dark ? [p.$3, p.$4] : [p.$1, p.$2],
        ).createShader(rect),
    );
    final rng = Random(category.hashCode & 0xffff);
    switch (category) {
      case 'CARD':
        _felt(canvas, size, ink, rng);
        _cards(canvas, size, ink, rng);
      case 'LOGIC':
        _grid(canvas, size, ink, 22, .07);
        _glyphs(
            canvas, size, ink, rng, const ['?', '!', '#', '≠', '✓', '✗'], 120);
      case 'BOARD':
        _checkers(canvas, size, ink);
        _icons(
            canvas,
            size,
            ink,
            rng,
            const [
              Icons.circle_outlined,
              Icons.casino_outlined,
              Icons.change_history_rounded,
            ],
            150,
            .07);
      case 'MATH':
        _grid(canvas, size, ink, 26, .06);
        _glyphs(
            canvas,
            size,
            ink,
            rng,
            const ['+', '−', '×', '÷', '=', '7', '3', '9', 'π', '√', '%', '2'],
            96);
      case 'WORD':
        _letterTiles(canvas, size, ink, rng);
      case 'MEMORY':
        _cardBacks(canvas, size, ink, rng);
      case 'ATTENTION':
        _targets(canvas, size, ink, rng);
      case 'SPATIAL':
        _cubes(canvas, size, ink);
      default:
        _threads(canvas, size, ink);
        _speckles(canvas, size, ink, rng);
        _icons(
            canvas,
            size,
            ink,
            rng,
            const [
              Icons.casino_outlined,
              Icons.extension_outlined,
              Icons.style_outlined,
              Icons.grid_4x4_rounded,
              Icons.diamond_outlined,
              Icons.favorite_border_rounded,
              Icons.circle_outlined,
              Icons.change_history_rounded,
              Icons.star_border_rounded,
              Icons.videogame_asset_outlined,
            ],
            132,
            .07);
    }
  }

  Color _a(Color ink, double light, [double? darkAlpha]) =>
      ink.withValues(alpha: dark ? (darkAlpha ?? light * .85) : light);

  void _threads(Canvas canvas, Size size, Color ink) {
    final thread = Paint()
      ..color = _a(ink, .035, .025)
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), thread);
    }
    for (var x = 0.0; x < size.width; x += 3) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), thread);
    }
  }

  void _speckles(Canvas canvas, Size size, Color ink, Random rng) {
    final speck = Paint()..color = _a(ink, .06, .05);
    final count = (size.width * size.height / 160).clamp(0, 40000).toInt();
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        .4 + rng.nextDouble() * .6,
        speck,
      );
    }
  }

  /// Jittered positions on a staggered grid, the same every time.
  Iterable<(Offset, double)> _scatter(
      Size size, Random rng, double cell) sync* {
    for (var row = 0; row * cell < size.height + cell; row++) {
      for (var col = 0; col * cell < size.width + cell; col++) {
        yield (
          Offset(
            col * cell +
                (row.isOdd ? cell / 2 : 0) +
                rng.nextDouble() * 30 -
                15,
            row * cell + rng.nextDouble() * 30 - 15,
          ),
          rng.nextDouble() * .9 - .45,
        );
      }
    }
  }

  void _drawText(
      Canvas canvas, String text, Offset at, double angle, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  void _icons(Canvas canvas, Size size, Color ink, Random rng,
      List<IconData> icons, double cell, double alpha) {
    var k = 0;
    for (final (at, angle) in _scatter(size, rng, cell)) {
      final icon = icons[k++ % icons.length];
      _drawText(
        canvas,
        String.fromCharCode(icon.codePoint),
        at,
        angle,
        TextStyle(
          fontSize: 30 + rng.nextDouble() * 14,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: _a(ink, alpha),
        ),
      );
    }
  }

  void _glyphs(Canvas canvas, Size size, Color ink, Random rng,
      List<String> glyphs, double cell) {
    var k = 0;
    for (final (at, angle) in _scatter(size, rng, cell)) {
      _drawText(
        canvas,
        glyphs[k++ % glyphs.length],
        at,
        angle,
        TextStyle(
          fontFamily: 'Geist',
          fontFamilyFallback: const ['GamesSymbols'],
          fontSize: 26 + rng.nextDouble() * 16,
          fontWeight: FontWeight.w700,
          color: _a(ink, .1, .09),
        ),
      );
    }
  }

  // ---- Cards: felt with soft, blurred playing cards ------------------------

  void _felt(Canvas canvas, Size size, Color ink, Random rng) {
    final fibre = Paint()
      ..color = _a(ink, .05, .06)
      ..strokeWidth = .8;
    final count = (size.width * size.height / 220).clamp(0, 30000).toInt();
    for (var i = 0; i < count; i++) {
      final o =
          Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      final a = rng.nextDouble() * pi;
      canvas.drawLine(o, o + Offset(cos(a), sin(a)) * 2.5, fibre);
    }
  }

  static const _suits = ['♠', '♥', '♦', '♣'];

  void _cards(Canvas canvas, Size size, Color ink, Random rng) {
    final blur = MaskFilter.blur(BlurStyle.normal, 2.4);
    final face = Paint()
      ..color = (dark ? Colors.white : Colors.white)
          .withValues(alpha: dark ? .07 : .55)
      ..maskFilter = blur;
    final edge = Paint()
      ..color = _a(ink, .14, .1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = blur;
    var k = 0;
    for (final (at, angle) in _scatter(size, rng, 118)) {
      final suit = _suits[k++ % 4];
      final red = suit == '♥' || suit == '♦';
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(angle * 1.3);
      final card = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 46, height: 64),
          const Radius.circular(6));
      canvas.drawRRect(card, face);
      canvas.drawRRect(card, edge);
      final pip = TextPainter(
        text: TextSpan(
          text: suit,
          style: TextStyle(
            fontFamily: 'GamesSymbols',
            fontSize: 26,
            foreground: Paint()
              ..color = (red ? const Color(0xFFC62828) : ink)
                  .withValues(alpha: dark ? .16 : .22)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.6),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      pip.paint(canvas, Offset(-pip.width / 2, -pip.height / 2));
      canvas.restore();
    }
  }

  // ---- Logic / Math: graph paper ------------------------------------------

  void _grid(Canvas canvas, Size size, Color ink, double step, double alpha) {
    final minor = Paint()
      ..color = _a(ink, alpha)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = _a(ink, alpha * 1.8)
      ..strokeWidth = 1.2;
    var i = 0;
    for (var x = 0.0; x < size.width; x += step, i++) {
      canvas.drawLine(
          Offset(x, 0), Offset(x, size.height), i % 5 == 0 ? major : minor);
    }
    i = 0;
    for (var y = 0.0; y < size.height; y += step, i++) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), i % 5 == 0 ? major : minor);
    }
  }

  // ---- Board: a large, soft checkerboard ------------------------------------

  void _checkers(Canvas canvas, Size size, Color ink) {
    const cell = 64.0;
    final square = Paint()
      ..color = _a(ink, .07, .06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    for (var r = 0; r * cell < size.height; r++) {
      for (var c = 0; c * cell < size.width; c++) {
        if ((r + c).isEven) {
          canvas.drawRect(
              Rect.fromLTWH(c * cell, r * cell, cell, cell), square);
        }
      }
    }
  }

  // ---- Word: scattered letter tiles ----------------------------------------

  void _letterTiles(Canvas canvas, Size size, Color ink, Random rng) {
    const letters = 'PUZZLEMASTERWORDGAME';
    final tile = Paint()
      ..color = (dark ? Colors.white : const Color(0xFFE9D3A6))
          .withValues(alpha: dark ? .06 : .55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    final edge = Paint()
      ..color = _a(ink, .16, .1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    var k = 0;
    for (final (at, angle) in _scatter(size, rng, 104)) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(angle);
      final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 40, height: 40),
          const Radius.circular(6));
      canvas.drawRRect(r, tile);
      canvas.drawRRect(r, edge);
      canvas.restore();
      _drawText(
        canvas,
        letters[k++ % letters.length],
        at,
        angle,
        TextStyle(
          fontFamily: 'Geist',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _a(ink, .28, .14),
        ),
      );
    }
  }

  // ---- Memory: face-down card backs ----------------------------------------

  void _cardBacks(Canvas canvas, Size size, Color ink, Random rng) {
    final back = Paint()
      ..color = _a(ink, .08, .07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    final lattice = Paint()
      ..color = _a(ink, .1, .08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final (at, angle) in _scatter(size, rng, 112)) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(angle * .6);
      final rect = Rect.fromCenter(center: Offset.zero, width: 50, height: 66);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)), back);
      canvas.save();
      canvas.clipRRect(
          RRect.fromRectAndRadius(rect.deflate(5), const Radius.circular(5)));
      for (var d = -80.0; d < 80; d += 10) {
        canvas.drawLine(Offset(d, -40), Offset(d + 80, 40), lattice);
        canvas.drawLine(Offset(d, 40), Offset(d + 80, -40), lattice);
      }
      canvas.restore();
      canvas.restore();
    }
  }

  // ---- Attention: focus targets --------------------------------------------

  void _targets(Canvas canvas, Size size, Color ink, Random rng) {
    final ring = Paint()
      ..color = _a(ink, .08, .07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final (at, _) in _scatter(size, rng, 170)) {
      for (var r = 12.0; r <= 48; r += 12) {
        canvas.drawCircle(at, r, ring);
      }
      canvas.drawCircle(at, 4, Paint()..color = _a(ink, .12, .1));
    }
  }

  // ---- Spatial: isometric cubes --------------------------------------------

  void _cubes(Canvas canvas, Size size, Color ink) {
    const s = 34.0; // edge length
    final h = s * sqrt(3) / 2;
    final top = Paint()..color = _a(ink, .035, .045);
    final left = Paint()..color = _a(ink, .065, .07);
    final line = Paint()
      ..color = _a(ink, .075, .08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var row = 0; row * s * 1.5 < size.height + s * 2; row++) {
      for (var col = 0; col * h * 2 < size.width + h * 2; col++) {
        final c = Offset(col * h * 2 + (row.isOdd ? h : 0), row * s * 1.5);
        final up = c + const Offset(0, -s);
        final ul = c + Offset(-h, -s / 2);
        final ur = c + Offset(h, -s / 2);
        final dl = c + Offset(-h, s / 2);
        final dr = c + Offset(h, s / 2);
        final down = c + const Offset(0, s);
        final topFace = Path()..addPolygon([c, ul, up, ur], true);
        final leftFace = Path()..addPolygon([c, ul, dl, down], true);
        final rightFace = Path()..addPolygon([c, ur, dr, down], true);
        canvas.drawPath(topFace, top);
        canvas.drawPath(leftFace, left);
        canvas.drawPath(topFace, line);
        canvas.drawPath(leftFace, line);
        canvas.drawPath(rightFace, line);
      }
    }
  }

  @override
  bool shouldRepaint(TableTexturePainter old) =>
      old.dark != dark || old.category != category;
}
