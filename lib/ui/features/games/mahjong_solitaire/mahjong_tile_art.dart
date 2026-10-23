import 'dart:math';

import 'package:flutter/material.dart';

import 'engine/mahjong_tile.dart';

/// Vector tile faces in the traditional style. Everything is drawn, not
/// taken from a font, so the tiles look the same offline on every platform
/// (no CJK font needs to be downloaded).
class MahjongFacePainter extends CustomPainter {
  const MahjongFacePainter(this.tile);
  final MahjongTile tile;

  static const red = Color(0xFFC62828);
  static const green = Color(0xFF2E7D32);
  static const blue = Color(0xFF1A3C8C);
  static const navy = Color(0xFF14213D);

  @override
  void paint(Canvas canvas, Size size) {
    final i = tile.index;
    if (i < 9) {
      _character(canvas, size, i + 1);
    } else if (i < 18) {
      _bamboo(canvas, size, i - 8);
    } else if (i < 27) {
      _dots(canvas, size, i - 17);
    } else if (i < 31) {
      _season(canvas, size, i - 26);
    } else if (i < 35) {
      _flower(canvas, size, i - 30);
    } else if (i < 39) {
      _wind(canvas, size, i - 34);
    } else {
      _dragon(canvas, size, i - 38);
    }
  }

  Offset _at(Size s, double x, double y) => Offset(s.width * x, s.height * y);

  // ---- Dots (circles) ------------------------------------------------------

  static const _dotLayouts = <List<(double, double)>>[
    [(.5, .5)],
    [(.5, .27), (.5, .73)],
    [(.24, .2), (.5, .5), (.76, .8)],
    [(.28, .27), (.72, .27), (.28, .73), (.72, .73)],
    [(.26, .22), (.74, .22), (.5, .5), (.26, .78), (.74, .78)],
    [(.3, .18), (.7, .18), (.3, .5), (.7, .5), (.3, .82), (.7, .82)],
    [
      (.22, .13),
      (.5, .25),
      (.78, .37),
      (.3, .62),
      (.7, .62),
      (.3, .87),
      (.7, .87)
    ],
    [
      (.3, .13),
      (.7, .13),
      (.3, .38),
      (.7, .38),
      (.3, .62),
      (.7, .62),
      (.3, .87),
      (.7, .87)
    ],
    [
      (.2, .18),
      (.5, .18),
      (.8, .18),
      (.2, .5),
      (.5, .5),
      (.8, .5),
      (.2, .82),
      (.5, .82),
      (.8, .82)
    ],
  ];

  Color _dotColour(int n, int k) => switch (n) {
        2 => k == 0 ? green : blue,
        3 => [blue, red, green][k],
        4 => k == 0 || k == 3 ? blue : green,
        5 => k == 2 ? red : (k == 0 || k == 4 ? blue : green),
        6 => k < 2 ? green : red,
        7 => k < 3 ? green : red,
        8 => blue,
        9 => [blue, red, green][k ~/ 3],
        _ => red,
      };

  void _dots(Canvas canvas, Size s, int n) {
    final layout = _dotLayouts[n - 1];
    final r = n == 1
        ? s.width * .36
        : n <= 4
            ? s.width * .17
            : n <= 6
                ? s.width * .15
                : s.width * .125;
    for (var k = 0; k < layout.length; k++) {
      final c = _at(s, layout[k].$1, layout[k].$2);
      if (n == 1) {
        _ornateDot(canvas, c, r);
      } else {
        _dot(canvas, c, r, _dotColour(n, k));
      }
    }
  }

  void _dot(Canvas canvas, Offset c, double r, Color colour) {
    canvas.drawCircle(c, r, Paint()..color = colour);
    canvas.drawCircle(c, r * .72, Paint()..color = const Color(0xFFFFFBF0));
    canvas.drawCircle(c, r * .5, Paint()..color = colour);
    canvas.drawCircle(c, r * .18, Paint()..color = const Color(0xFFFFFBF0));
  }

  void _ornateDot(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = green);
    canvas.drawCircle(c, r * .86, Paint()..color = const Color(0xFFFFFBF0));
    // Petal ring.
    final petal = Paint()..color = blue;
    for (var k = 0; k < 12; k++) {
      final a = k * pi / 6;
      canvas.drawCircle(c + Offset(cos(a), sin(a)) * r * .66, r * .12, petal);
    }
    canvas.drawCircle(c, r * .46, Paint()..color = red);
    canvas.drawCircle(c, r * .3, Paint()..color = const Color(0xFFFFFBF0));
    canvas.drawCircle(c, r * .16, Paint()..color = green);
  }

  // ---- Bamboo --------------------------------------------------------------

  static const _bambooLayouts = <List<(double, double, bool)>>[
    [],
    [(.5, .27, false), (.5, .73, false)],
    [(.5, .27, false), (.3, .73, false), (.7, .73, false)],
    [(.3, .27, false), (.7, .27, false), (.3, .73, false), (.7, .73, false)],
    [
      (.24, .27, false),
      (.76, .27, false),
      (.5, .5, true),
      (.24, .73, false),
      (.76, .73, false)
    ],
    [
      (.22, .27, false),
      (.5, .27, false),
      (.78, .27, false),
      (.22, .73, false),
      (.5, .73, false),
      (.78, .73, false)
    ],
    [
      (.5, .17, true),
      (.22, .5, false),
      (.5, .5, false),
      (.78, .5, false),
      (.22, .83, false),
      (.5, .83, false),
      (.78, .83, false)
    ],
    [
      (.18, .27, false),
      (.39, .27, true),
      (.61, .27, true),
      (.82, .27, false),
      (.18, .73, false),
      (.39, .73, true),
      (.61, .73, true),
      (.82, .73, false)
    ],
    [
      (.22, .17, false),
      (.5, .17, true),
      (.78, .17, false),
      (.22, .5, false),
      (.5, .5, true),
      (.78, .5, false),
      (.22, .83, false),
      (.5, .83, true),
      (.78, .83, false)
    ],
  ];

  void _bamboo(Canvas canvas, Size s, int n) {
    if (n == 1) {
      _bigBamboo(canvas, s);
      return;
    }
    final layout = _bambooLayouts[n - 1];
    final rows = n >= 7 && n != 8 ? 3 : 2;
    final length = s.height * (rows == 3 ? .26 : .38);
    final width = s.width * (n == 8 ? .13 : .15);
    for (final (x, y, isRed) in layout) {
      _stick(canvas, _at(s, x, y), width, length, isRed ? red : green);
    }
  }

  void _stick(Canvas canvas, Offset c, double w, double l, Color colour) {
    final rect = Rect.fromCenter(center: c, width: w, height: l);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(w / 2)),
      Paint()
        ..shader = LinearGradient(colors: [
          Color.lerp(colour, Colors.white, .35)!,
          colour,
          Color.lerp(colour, Colors.black, .3)!,
        ]).createShader(rect),
    );
    final node = Paint()
      ..color = const Color(0xFFFFFBF0)
      ..strokeWidth = max(1, w * .16);
    for (final f in const [.22, .5, .78]) {
      final y = rect.top + rect.height * f;
      canvas.drawLine(
          Offset(rect.left + w * .1, y), Offset(rect.right - w * .1, y), node);
    }
  }

  void _bigBamboo(Canvas canvas, Size s) {
    _stick(canvas, _at(s, .5, .55), s.width * .2, s.height * .7, green);
    final leaf = Paint()..color = green;
    for (final dir in const [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(s.width * .5, s.height * .32)
        ..quadraticBezierTo(s.width * (.5 + .3 * dir), s.height * .1,
            s.width * (.5 + .38 * dir), s.height * .3)
        ..quadraticBezierTo(s.width * (.5 + .2 * dir), s.height * .3,
            s.width * .5, s.height * .36)
        ..close();
      canvas.drawPath(path, leaf);
    }
    canvas.drawCircle(_at(s, .5, .2), s.width * .1, Paint()..color = red);
  }

  // ---- Characters ----------------------------------------------------------

  void _character(Canvas canvas, Size s, int n) {
    _text(canvas, '$n', _at(s, .5, .27), s.height * .38, navy);
    // A drawn red seal evoking the "wan" (ten thousand) character.
    final p = Paint()
      ..color = red
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s.width * .07;
    final w = s.width, h = s.height;
    canvas.drawLine(Offset(w * .22, h * .56), Offset(w * .78, h * .56), p);
    canvas.drawLine(Offset(w * .38, h * .51), Offset(w * .38, h * .61), p);
    canvas.drawLine(Offset(w * .62, h * .51), Offset(w * .62, h * .61), p);
    canvas.drawRect(Rect.fromLTRB(w * .3, h * .65, w * .7, h * .77), p);
    canvas.drawLine(Offset(w * .5, h * .65), Offset(w * .5, h * .77), p);
    final hook = Path()
      ..moveTo(w * .28, h * .83)
      ..lineTo(w * .72, h * .83)
      ..quadraticBezierTo(w * .74, h * .92, w * .62, h * .93);
    canvas.drawPath(hook, p);
    canvas.drawLine(Offset(w * .44, h * .85), Offset(w * .34, h * .93), p);
  }

  // ---- Honours -------------------------------------------------------------

  void _wind(Canvas canvas, Size s, int n) {
    final c = _at(s, .5, .5);
    final faint = Paint()
      ..color = blue.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * .05;
    canvas.drawCircle(c, s.width * .38, faint);
    for (var k = 0; k < 4; k++) {
      final a = k * pi / 2;
      canvas.drawLine(c + Offset(cos(a), sin(a)) * s.width * .3,
          c + Offset(cos(a), sin(a)) * s.width * .46, faint);
    }
    _text(canvas, const ['E', 'S', 'W', 'N'][n - 1], c, s.height * .48, navy);
  }

  void _dragon(Canvas canvas, Size s, int n) {
    final w = s.width, h = s.height;
    switch (n) {
      case 1: // Red dragon: the "centre" character.
        final p = Paint()
          ..color = red
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = w * .11;
        canvas.drawRRect(
            RRect.fromLTRBR(
                w * .2, h * .32, w * .8, h * .62, Radius.circular(w * .05)),
            p);
        canvas.drawLine(Offset(w * .5, h * .14), Offset(w * .5, h * .88), p);
      case 2: // Green dragon: a coiled green emblem.
        final p = Paint()
          ..color = green
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = w * .09;
        final path = Path();
        for (var t = 0.0; t <= 3 * pi; t += .1) {
          final r = w * (.05 + .1 * t / pi);
          final pt = Offset(w * .5 + cos(t) * r, h * .5 + sin(t) * r * 1.25);
          t == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(path, p);
        canvas.drawCircle(_at(s, .5, .5), w * .06, Paint()..color = red);
      default: // White dragon: the blue frame.
        final p = Paint()
          ..color = blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .07;
        canvas.drawRect(Rect.fromLTRB(w * .16, h * .14, w * .84, h * .86), p);
        canvas.drawRect(Rect.fromLTRB(w * .3, h * .26, w * .7, h * .74),
            p..strokeWidth = w * .04);
    }
  }

  // ---- Bonus tiles ---------------------------------------------------------

  static const _flowerColours = [
    Color(0xFFE91E63),
    Color(0xFF8E24AA),
    Color(0xFFF9A825),
    Color(0xFFE64A19),
  ];

  void _flower(Canvas canvas, Size s, int n) {
    final c = _at(s, .5, .46);
    final colour = _flowerColours[n - 1];
    final stem = Paint()
      ..color = green
      ..strokeWidth = s.width * .06
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, _at(s, .5, .92), stem);
    canvas.drawOval(
        Rect.fromCenter(
            center: _at(s, .64, .76),
            width: s.width * .3,
            height: s.height * .1),
        Paint()..color = green);
    final petal = Paint()..color = colour;
    for (var k = 0; k < 5; k++) {
      final a = k * 2 * pi / 5 - pi / 2;
      canvas.drawCircle(
          c + Offset(cos(a), sin(a)) * s.width * .17, s.width * .14, petal);
    }
    canvas.drawCircle(
        c, s.width * .1, Paint()..color = const Color(0xFFFFD54F));
    _text(canvas, '$n', _at(s, .16, .12), s.height * .16, red);
  }

  static const _seasonIcons = [
    (Icons.spa, green),
    (Icons.wb_sunny, Color(0xFFEF6C00)),
    (Icons.park, Color(0xFF8D6E63)),
    (Icons.ac_unit, Color(0xFF1565C0)),
  ];

  void _season(Canvas canvas, Size s, int n) {
    final (icon, colour) = _seasonIcons[n - 1];
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
            fontSize: s.width * .78,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: colour),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas,
        _at(s, .5, .55) - Offset(painter.width / 2, painter.height / 2));
    _text(canvas, '$n', _at(s, .16, .12), s.height * .16, blue);
  }

  void _text(
      Canvas canvas, String text, Offset centre, double size, Color colour) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          height: 1,
          fontFamily: 'Geist',
          fontWeight: FontWeight.w700,
          color: colour,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
        canvas, centre - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(MahjongFacePainter old) => old.tile != tile;
}
