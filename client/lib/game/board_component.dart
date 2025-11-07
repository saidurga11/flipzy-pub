import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'board_logic.dart';
import 'tile_component.dart';

/// Main game board component managing all tiles and game state
class FlipzyGame extends FlameGame {
  late BoardLogic logic;
  final List<TileComponent> tileComponents = [];
  final int gridSize;
  final int? seed;

  double timeRemaining = 60.0;
  bool isGameOver = false;
  bool isProcessing = false;

  // Callbacks for UI updates
  Function(int score, int combo)? onScoreUpdate;
  Function(double time)? onTimeUpdate;
  Function()? onGameComplete;
  Function()? onGameOver;

  FlipzyGame({
    this.gridSize = 4,
    this.seed,
    this.onScoreUpdate,
    this.onTimeUpdate,
    this.onGameComplete,
    this.onGameOver,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize game logic
    logic = BoardLogic(gridSize: gridSize, seed: seed);

    // Create tile components
    _createTiles();
  }

  void _createTiles() {
    tileComponents.clear();

    final screenWidth = size.x;
    final screenHeight = size.y * 0.7; // Leave room for UI at top

    // Calculate tile size based on screen size
    final padding = 8.0;
    final availableWidth = screenWidth - (padding * (gridSize + 1));
    final availableHeight = screenHeight - (padding * (gridSize + 1));
    final tileSize =
        (availableWidth / gridSize).clamp(0, availableHeight / gridSize);

    // Calculate starting position to center the grid
    final gridWidth = (tileSize * gridSize) + (padding * (gridSize - 1));
    final gridHeight = (tileSize * gridSize) + (padding * (gridSize - 1));
    final startX = (screenWidth - gridWidth) / 2 + tileSize / 2;
    final startY =
        (size.y * 0.3) + (screenHeight - gridHeight) / 2 + tileSize / 2;

    for (int i = 0; i < logic.tiles.length; i++) {
      final row = i ~/ gridSize;
      final col = i % gridSize;

      final x = startX + (col * (tileSize + padding));
      final y = startY + (row * (tileSize + padding));

      final tile = TileComponent(
        index: i,
        value: logic.tiles[i].value,
        tileSize: tileSize,
        position: Vector2(x, y),
        onTap: () => _onTileTapped(i),
      );

      tileComponents.add(tile);
      add(tile);
    }
  }

  Future<void> _onTileTapped(int index) async {
    if (isProcessing || isGameOver) return;

    final success = logic.flip(index);
    if (!success) return;

    // Play flip animation
    await tileComponents[index].flipToFront();

    // Check if we have two tiles flipped
    if (logic.firstFlippedIndex != null && logic.secondFlippedIndex != null) {
      isProcessing = true;

      // Small delay to let player see both tiles
      await Future.delayed(const Duration(milliseconds: 400));

      final isMatch = logic.processMatch();

      if (isMatch == true) {
        // Match! Lock the tiles
        tileComponents[logic.firstFlippedIndex ?? 0].lock();
        tileComponents[logic.secondFlippedIndex ?? 0].lock();

        // Update score
        onScoreUpdate?.call(logic.score, logic.combo);

        // Check if game is complete
        if (logic.isComplete) {
          isGameOver = true;
          onGameComplete?.call();
        }
      } else if (isMatch == false) {
        // Miss! Shake and flip back
        await Future.wait([
          tileComponents[logic.firstFlippedIndex ?? 0].shake(),
          tileComponents[logic.secondFlippedIndex ?? 0].shake(),
        ]);

        await Future.delayed(const Duration(milliseconds: 200));

        await Future.wait([
          tileComponents[logic.firstFlippedIndex ?? 0].flipToBack(),
          tileComponents[logic.secondFlippedIndex ?? 0].flipToBack(),
        ]);

        logic.hideFlippedTiles();
      }

      isProcessing = false;
    }

    // Update score (even on first flip to show current state)
    onScoreUpdate?.call(logic.score, logic.combo);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isGameOver && timeRemaining > 0) {
      timeRemaining -= dt;
      onTimeUpdate?.call(timeRemaining);

      if (timeRemaining <= 0) {
        timeRemaining = 0;
        isGameOver = true;
        onGameOver?.call();
      }
    }
  }

  void restart({int? newSeed}) {
    // Clear existing tiles
    for (final tile in tileComponents) {
      remove(tile);
    }

    // Reset logic
    logic.reset(newSeed: newSeed);

    // Reset game state
    timeRemaining = 60.0;
    isGameOver = false;
    isProcessing = false;

    // Recreate tiles
    _createTiles();

    // Update UI
    onScoreUpdate?.call(0, 0);
    onTimeUpdate?.call(60.0);
  }
}
