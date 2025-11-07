import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// A single tile component with flip animation
class TileComponent extends PositionComponent with TapCallbacks {
  final int index;
  final int value;
  final double tileSize;
  final VoidCallback onTap;

  bool _isFlipped = false;
  bool _isLocked = false;
  double _flipProgress = 0.0; // 0.0 = face down, 1.0 = face up

  // Colors for different tile values
  static const List<Color> tileColors = [
    Color(0xFFE57373), // Red
    Color(0xFF64B5F6), // Blue
    Color(0xFF81C784), // Green
    Color(0xFFFFD54F), // Yellow
    Color(0xFFBA68C8), // Purple
    Color(0xFFFF8A65), // Deep Orange
    Color(0xFF4DB6AC), // Teal
    Color(0xFFFFB74D), // Orange
  ];

  TileComponent({
    required this.index,
    required this.value,
    required this.tileSize,
    required Vector2 position,
    required this.onTap,
  }) : super(
          position: position,
          size: Vector2.all(tileSize),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Calculate the visual scale based on flip progress
    // At 0.5 flip progress (90 degrees), tile appears thinnest
    final scaleX = (1.0 - _flipProgress * 2).abs();

    // Determine if we should show front or back
    final showFront = _flipProgress > 0.5;

    // Save canvas state
    canvas.save();

    // Apply horizontal scale for 3D flip effect
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(scaleX, 1.0);
    canvas.translate(-size.x / 2, -size.y / 2);

    if (showFront) {
      _renderFront(canvas);
    } else {
      _renderBack(canvas);
    }

    canvas.restore();

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(8),
      ),
      borderPaint,
    );
  }

  void _renderBack(Canvas canvas) {
    // Back of tile (face down) - solid color with pattern
    final paint = Paint()..color = const Color(0xFF424242);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(8),
      ),
      paint,
    );

    // Draw simple pattern
    final patternPaint = Paint()
      ..color = const Color(0xFF616161)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final radius = size.x * 0.3;

    canvas.drawCircle(Offset(centerX, centerY), radius, patternPaint);
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.6, patternPaint);
  }

  void _renderFront(Canvas canvas) {
    // Front of tile (face up) - colored based on value
    final color = tileColors[value % tileColors.length];
    final paint = Paint()..color = _isLocked ? color.withOpacity(0.6) : color;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(8),
      ),
      paint,
    );

    // Draw value as text
    final textPainter = TextPainter(
      text: TextSpan(
        text: value.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size.x * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );

    // Draw lock icon if locked
    if (_isLocked) {
      final lockPaint = Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final lockSize = size.x * 0.15;
      final lockX = size.x - lockSize * 2;
      final lockY = lockSize;

      // Lock body
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(lockX, lockY + lockSize * 0.5, lockSize, lockSize),
          const Radius.circular(2),
        ),
        lockPaint..style = PaintingStyle.fill,
      );

      // Lock shackle
      canvas.drawArc(
        Rect.fromLTWH(lockX, lockY, lockSize, lockSize),
        math.pi,
        math.pi,
        false,
        lockPaint..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!_isLocked && !_isFlipped) {
      onTap();
    }
  }

  /// Flip the tile to reveal its face
  Future<void> flipToFront() async {
    if (_isFlipped) return;
    _isFlipped = true;

    final effect = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: AnimationController(
        vsync: game!,
        duration: const Duration(milliseconds: 300),
      )..forward(),
      curve: Curves.easeInOut,
    ));

    effect.addListener(() {
      _flipProgress = effect.value;
    });

    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Flip the tile back to face down
  Future<void> flipToBack() async {
    if (!_isFlipped) return;
    _isFlipped = false;

    final effect = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: AnimationController(
        vsync: game!,
        duration: const Duration(milliseconds: 300),
      )..forward(),
      curve: Curves.easeInOut,
    ));

    effect.addListener(() {
      _flipProgress = effect.value;
    });

    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Shake animation for mismatched tiles
  Future<void> shake() async {
    final originalX = position.x;
    const shakeAmount = 10.0;
    const duration = Duration(milliseconds: 50);

    for (int i = 0; i < 4; i++) {
      position.x = originalX + (i.isEven ? shakeAmount : -shakeAmount);
      await Future.delayed(duration);
    }

    position.x = originalX;
  }

  /// Lock the tile (matched pair)
  void lock() {
    _isLocked = true;
  }

  /// Update flip progress manually (for smoother animation)
  void updateFlipProgress(double progress) {
    _flipProgress = progress.clamp(0.0, 1.0);
  }

  bool get isFlipped => _isFlipped;
  bool get isLocked => _isLocked;
}
