import 'dart:math';

/// Represents the state of a single tile on the board
class TileState {
  final int index;
  final int value; // Matching pair ID (0-7 for 4x4 grid)
  bool isRevealed;
  bool isLocked;

  TileState({
    required this.index,
    required this.value,
    this.isRevealed = false,
    this.isLocked = false,
  });

  TileState copyWith({
    bool? isRevealed,
    bool? isLocked,
  }) {
    return TileState(
      index: index,
      value: value,
      isRevealed: isRevealed ?? this.isRevealed,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

/// Pure Dart game logic for the Flipzy board
class BoardLogic {
  final int gridSize;
  final int seed;
  late List<TileState> tiles;

  int _score = 0;
  int _combo = 0;
  int _flips = 0;
  int? _firstFlippedIndex;
  int? _secondFlippedIndex;

  BoardLogic({
    this.gridSize = 4,
    int? seed,
  }) : seed = seed ?? DateTime.now().millisecondsSinceEpoch {
    _initializeBoard();
  }

  /// Get current score
  int get score => _score;

  /// Get current combo multiplier
  int get combo => _combo;

  /// Get total flips made
  int get flips => _flips;

  /// Get first flipped tile index (if any)
  int? get firstFlippedIndex => _firstFlippedIndex;

  /// Get second flipped tile index (if any)
  int? get secondFlippedIndex => _secondFlippedIndex;

  /// Check if game is complete (all tiles locked)
  bool get isComplete => tiles.every((tile) => tile.isLocked);

  /// Get list of locked tile indices
  List<int> lockedTiles() {
    return tiles
        .where((tile) => tile.isLocked)
        .map((tile) => tile.index)
        .toList();
  }

  /// Get list of revealed tile indices
  List<int> revealedTiles() {
    return tiles
        .where((tile) => tile.isRevealed && !tile.isLocked)
        .map((tile) => tile.index)
        .toList();
  }

  /// Initialize board with deterministic shuffle based on seed
  void _initializeBoard() {
    final totalTiles = gridSize * gridSize;
    final pairCount = totalTiles ~/ 2;

    // Generate pairs: [0, 0, 1, 1, 2, 2, ...]
    final values = <int>[];
    for (int i = 0; i < pairCount; i++) {
      values.add(i);
      values.add(i);
    }

    // Deterministic shuffle using seeded Random
    final random = Random(seed);
    for (int i = values.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = values[i];
      values[i] = values[j];
      values[j] = temp;
    }

    // Create tile states
    tiles = List.generate(
      totalTiles,
      (index) => TileState(
        index: index,
        value: values[index],
      ),
    );
  }

  /// Flip a tile at the given index
  /// Returns true if flip was successful, false otherwise
  bool flip(int index) {
    if (index < 0 || index >= tiles.length) return false;

    final tile = tiles[index];

    // Can't flip if already locked or revealed
    if (tile.isLocked || tile.isRevealed) return false;

    // Can't flip if already have 2 tiles revealed
    if (_firstFlippedIndex != null && _secondFlippedIndex != null) {
      return false;
    }

    // Flip the tile
    tiles[index] = tile.copyWith(isRevealed: true);
    _flips++;

    // Track which flip this is
    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
    } else if (_secondFlippedIndex == null) {
      _secondFlippedIndex = index;
    }

    return true;
  }

  /// Check if two tiles match
  bool isMatch(int indexA, int indexB) {
    if (indexA < 0 || indexA >= tiles.length) return false;
    if (indexB < 0 || indexB >= tiles.length) return false;
    return tiles[indexA].value == tiles[indexB].value;
  }

  /// Process match for the two currently flipped tiles
  /// Returns true if it was a match, false otherwise
  bool? processMatch() {
    if (_firstFlippedIndex == null || _secondFlippedIndex == null) {
      return null;
    }

    final isMatchResult = isMatch(_firstFlippedIndex!, _secondFlippedIndex!);

    if (isMatchResult) {
      // Lock both tiles
      tiles[_firstFlippedIndex!] =
          tiles[_firstFlippedIndex!].copyWith(isLocked: true);
      tiles[_secondFlippedIndex!] =
          tiles[_secondFlippedIndex!].copyWith(isLocked: true);

      // Increment combo and score
      _combo++;
      _score += 10 * _combo; // Base score 10, multiplied by combo

      // Reset flipped indices
      _firstFlippedIndex = null;
      _secondFlippedIndex = null;

      return true;
    } else {
      // Not a match - combo resets on next hide
      return false;
    }
  }

  /// Hide the two currently flipped tiles (called after a miss)
  void hideFlippedTiles() {
    if (_firstFlippedIndex != null) {
      tiles[_firstFlippedIndex!] =
          tiles[_firstFlippedIndex!].copyWith(isRevealed: false);
    }
    if (_secondFlippedIndex != null) {
      tiles[_secondFlippedIndex!] =
          tiles[_secondFlippedIndex!].copyWith(isRevealed: false);
    }

    // Reset combo on miss
    _combo = 0;

    _firstFlippedIndex = null;
    _secondFlippedIndex = null;
  }

  /// Reset the game with a new seed
  void reset({int? newSeed}) {
    if (newSeed != null) {
      final logic = BoardLogic(gridSize: gridSize, seed: newSeed);
      tiles = logic.tiles;
    } else {
      _initializeBoard();
    }
    _score = 0;
    _combo = 0;
    _flips = 0;
    _firstFlippedIndex = null;
    _secondFlippedIndex = null;
  }

  /// Get tile at index
  TileState getTile(int index) {
    return tiles[index];
  }
}
