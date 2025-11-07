import 'package:flutter_test/flutter_test.dart';
import 'package:flipzy_client/game/board_logic.dart';

void main() {
  group('BoardLogic - Deterministic Generation', () {
    test('Same seed produces identical board layout', () {
      const seed = 12345;
      final board1 = BoardLogic(gridSize: 4, seed: seed);
      final board2 = BoardLogic(gridSize: 4, seed: seed);

      expect(board1.tiles.length, board2.tiles.length);

      for (int i = 0; i < board1.tiles.length; i++) {
        expect(board1.tiles[i].value, board2.tiles[i].value,
            reason: 'Tile $i should have same value');
        expect(board1.tiles[i].index, board2.tiles[i].index);
      }
    });

    test('Different seeds produce different layouts', () {
      final board1 = BoardLogic(gridSize: 4, seed: 11111);
      final board2 = BoardLogic(gridSize: 4, seed: 22222);

      bool hasDifference = false;
      for (int i = 0; i < board1.tiles.length; i++) {
        if (board1.tiles[i].value != board2.tiles[i].value) {
          hasDifference = true;
          break;
        }
      }

      expect(hasDifference, true,
          reason: 'Different seeds should produce different layouts');
    });

    test('Board has correct number of pairs', () {
      final board = BoardLogic(gridSize: 4, seed: 100);
      final valueCounts = <int, int>{};

      for (final tile in board.tiles) {
        valueCounts[tile.value] = (valueCounts[tile.value] ?? 0) + 1;
      }

      // Each value should appear exactly twice (pairs)
      for (final count in valueCounts.values) {
        expect(count, 2, reason: 'Each tile value should appear exactly twice');
      }
    });

    test('Board initializes with correct size', () {
      final board3x3 = BoardLogic(gridSize: 3, seed: 100);
      expect(board3x3.tiles.length, 9);

      final board4x4 = BoardLogic(gridSize: 4, seed: 100);
      expect(board4x4.tiles.length, 16);

      final board6x6 = BoardLogic(gridSize: 6, seed: 100);
      expect(board6x6.tiles.length, 36);
    });
  });

  group('BoardLogic - Tile Flipping', () {
    test('Can flip a face-down tile', () {
      final board = BoardLogic(gridSize: 4, seed: 100);
      final result = board.flip(0);

      expect(result, true);
      expect(board.tiles[0].isRevealed, true);
      expect(board.flips, 1);
    });

    test('Cannot flip already revealed tile', () {
      final board = BoardLogic(gridSize: 4, seed: 100);
      board.flip(0);

      final result = board.flip(0);
      expect(result, false);
      expect(board.flips, 1); // Should not increment
    });

    test('Cannot flip locked tile', () {
      final board = BoardLogic(gridSize: 4, seed: 100);
      board.tiles[0] = board.tiles[0].copyWith(isLocked: true);

      final result = board.flip(0);
      expect(result, false);
    });

    test('Cannot flip more than 2 tiles at once', () {
      final board = BoardLogic(gridSize: 4, seed: 100);
      board.flip(0);
      board.flip(1);

      final result = board.flip(2);
      expect(result, false);
      expect(board.flips, 2);
    });

    test('Tracks first and second flipped indices', () {
      final board = BoardLogic(gridSize: 4, seed: 100);
      board.flip(0);

      expect(board.firstFlippedIndex, 0);
      expect(board.secondFlippedIndex, null);

      board.flip(1);
      expect(board.firstFlippedIndex, 0);
      expect(board.secondFlippedIndex, 1);
    });
  });

  group('BoardLogic - Match Detection', () {
    test('isMatch correctly identifies matching tiles', () {
      final board = BoardLogic(gridSize: 4, seed: 100);

      // Find two tiles with same value
      int? firstIndex;
      int? secondIndex;

      for (int i = 0; i < board.tiles.length; i++) {
        if (firstIndex == null) {
          firstIndex = i;
        } else if (board.tiles[i].value == board.tiles[firstIndex].value) {
          secondIndex = i;
          break;
        }
      }

      expect(firstIndex, isNotNull);
      expect(secondIndex, isNotNull);
      expect(board.isMatch(firstIndex!, secondIndex!), true);
    });

    test('isMatch correctly identifies non-matching tiles', () {
      final board = BoardLogic(gridSize: 4, seed: 100);

      // Find two tiles with different values
      int? firstIndex;
      int? secondIndex;

      for (int i = 0; i < board.tiles.length; i++) {
        if (firstIndex == null) {
          firstIndex = i;
        } else if (board.tiles[i].value != board.tiles[firstIndex].value) {
          secondIndex = i;
          break;
        }
      }

      expect(firstIndex, isNotNull);
      expect(secondIndex, isNotNull);
      expect(board.isMatch(firstIndex!, secondIndex!), false);
    });
  });

  group('BoardLogic - Scoring and Combos', () {
    test('Score increases on match', () {
      final board = BoardLogic(gridSize: 4, seed: 100);

      // Find a matching pair
      int? first;
      int? second;
      for (int i = 0; i < board.tiles.length; i++) {
        if (first == null) {
          first = i;
        } else if (board.tiles[i].value == board.tiles[first].value) {
          second = i;
          break;
        }
      }

      board.flip(first!);
      board.flip(second!);

      final initialScore = board.score;
      board.processMatch();

      expect(board.score, greaterThan(initialScore));
    });

    test('Combo multiplier increases on consecutive matches', () {
      final board = BoardLogic(gridSize: 4, seed: 12345);

      // Find first matching pair
      int? pair1First;
      int? pair1Second;
      for (int i = 0; i < board.tiles.length; i++) {
        if (pair1First == null) {
          pair1First = i;
        } else if (board.tiles[i].value == board.tiles[pair1First].value) {
          pair1Second = i;
          break;
        }
      }

      board.flip(pair1First!);
      board.flip(pair1Second!);
      board.processMatch();

      expect(board.combo, 1);

      // Find second matching pair
      int? pair2First;
      int? pair2Second;
      for (int i = 0; i < board.tiles.length; i++) {
        if (board.tiles[i].isLocked) continue;
        if (pair2First == null) {
          pair2First = i;
        } else if (board.tiles[i].value == board.tiles[pair2First].value) {
          pair2Second = i;
          break;
        }
      }

      if (pair2First != null && pair2Second != null) {
        board.flip(pair2First);
        board.flip(pair2Second);
        board.processMatch();

        expect(board.combo, 2);
      }
    });

    test('Combo resets on miss', () {
      final board = BoardLogic(gridSize: 4, seed: 12345);

      // Make a match first
      int? pair1First;
      int? pair1Second;
      for (int i = 0; i < board.tiles.length; i++) {
        if (pair1First == null) {
          pair1First = i;
        } else if (board.tiles[i].value == board.tiles[pair1First].value) {
          pair1Second = i;
          break;
        }
      }

      board.flip(pair1First!);
      board.flip(pair1Second!);
      board.processMatch();
      expect(board.combo, 1);

      // Make a miss
      int? missFirst;
      int? missSecond;
      for (int i = 0; i < board.tiles.length; i++) {
        if (board.tiles[i].isLocked) continue;
        if (missFirst == null) {
          missFirst = i;
        } else if (board.tiles[i].value != board.tiles[missFirst].value) {
          missSecond = i;
          break;
        }
      }

      if (missFirst != null && missSecond != null) {
        board.flip(missFirst);
        board.flip(missSecond);
        board.processMatch();
        board.hideFlippedTiles();

        expect(board.combo, 0);
      }
    });

    test('Score calculation uses combo multiplier', () {
      final board = BoardLogic(gridSize: 4, seed: 12345);

      // First match: 10 * 1 = 10
      int? p1First;
      int? p1Second;
      for (int i = 0; i < board.tiles.length; i++) {
        if (p1First == null) {
          p1First = i;
        } else if (board.tiles[i].value == board.tiles[p1First].value) {
          p1Second = i;
          break;
        }
      }

      board.flip(p1First!);
      board.flip(p1Second!);
      board.processMatch();

      expect(board.score, 10);

      // Second match: 10 * 2 = 20, total = 30
      int? p2First;
      int? p2Second;
      for (int i = 0; i < board.tiles.length; i++) {
        if (board.tiles[i].isLocked) continue;
        if (p2First == null) {
          p2First = i;
        } else if (board.tiles[i].value == board.tiles[p2First].value) {
          p2Second = i;
          break;
        }
      }

      if (p2First != null && p2Second != null) {
        board.flip(p2First);
        board.flip(p2Second);
        board.processMatch();

        expect(board.score, 30);
      }
    });
  });

  group('BoardLogic - Game State', () {
    test('lockedTiles returns correct indices', () {
      final board = BoardLogic(gridSize: 4, seed: 100);

      board.tiles[0] = board.tiles[0].copyWith(isLocked: true);
      board.tiles[5] = board.tiles[5].copyWith(isLocked: true);

      final locked = board.lockedTiles();
      expect(locked, contains(0));
      expect(locked, contains(5));
      expect(locked.length, 2);
    });

    test('isComplete returns true when all tiles locked', () {
      final board = BoardLogic(gridSize: 2, seed: 100); // Smaller board

      expect(board.isComplete, false);

      // Lock all tiles
      for (int i = 0; i < board.tiles.length; i++) {
        board.tiles[i] = board.tiles[i].copyWith(isLocked: true);
      }

      expect(board.isComplete, true);
    });

    test('reset clears game state', () {
      final board = BoardLogic(gridSize: 4, seed: 100);

      // Play some moves
      board.flip(0);
      board.flip(1);

      board.reset();

      expect(board.score, 0);
      expect(board.combo, 0);
      expect(board.flips, 0);
      expect(board.firstFlippedIndex, null);
      expect(board.secondFlippedIndex, null);
      expect(board.tiles.every((t) => !t.isRevealed && !t.isLocked), true);
    });
  });
}
