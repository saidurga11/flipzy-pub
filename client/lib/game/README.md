# Flipzy Game Implementation

This directory contains the single-player Flipzy card matching game implementation using the Flame game engine.

## Architecture

### Core Components

1. **board_logic.dart** - Pure Dart game logic (fully testable)
   - `BoardLogic` class manages game state
   - Deterministic board generation using seeds
   - Match detection and scoring
   - Combo multiplier system

2. **tile_component.dart** - Individual tile rendering and animation
   - `TileComponent` extends Flame's `PositionComponent`
   - 180° Y-axis flip animation
   - Tap handling
   - Shake animation on mismatch
   - Lock state for matched pairs

3. **board_component.dart** - Main game board
   - `FlipzyGame` extends `FlameGame`
   - Manages all tile components
   - Coordinates game flow
   - Timer countdown (60 seconds)
   - Callbacks for UI updates

4. **game_screen.dart** - Flutter UI wrapper
   - Integrates Flame game with Flutter widgets
   - UI overlay with stats (timer, score, combo)
   - Confetti effects on matches
   - Game over/complete dialogs
   - Restart functionality

## Game Rules

### Board Setup
- 4x4 grid (16 tiles, 8 pairs)
- Deterministic shuffle based on seed
- All tiles start face-down

### Gameplay
1. Tap a tile to flip it face-up
2. Tap a second tile to reveal it
3. **Match**:
   - Both tiles stay face-up and lock
   - Score increases by `10 × combo`
   - Combo increments
   - Confetti appears
   - Player gets another turn
4. **Miss**:
   - Both tiles shake
   - After 400ms delay, both flip face-down
   - Combo resets to 0
   - Turn ends

### Scoring
- Base score per match: 10 points
- Multiplied by current combo streak
- Example: 3 consecutive matches = 10 + 20 + 30 = 60 points

### Win/Lose Conditions
- **Win**: Match all pairs before timer runs out
- **Lose**: Timer reaches 0 before all pairs matched

## Testing

### Unit Tests (`test/board_logic_test.dart`)

Run tests:
```bash
cd client
flutter test test/board_logic_test.dart
```

Test coverage:
- ✅ Deterministic generation (same seed → same board)
- ✅ Pair validation (all tiles have exactly one match)
- ✅ Match detection
- ✅ Scoring calculation
- ✅ Combo multiplier
- ✅ Flip validation
- ✅ Game completion detection

## Implementation Details

### Deterministic Board Generation

```dart
final random = Random(seed);  // Seeded random for reproducibility
// Shuffle algorithm ensures same seed → same layout
```

This allows:
- Sharing specific puzzles via seed
- Replay challenges with same layout
- Server-side puzzle generation

### Tile Values and Colors

Tiles are assigned:
- Values 0-7 (for 4x4 grid)
- Each value appears exactly twice
- Colors map to values: Red, Blue, Green, Yellow, Purple, Deep Orange, Teal, Orange

### Animation System

**Flip Animation** (300ms):
```dart
// Simulates 3D Y-axis rotation
scaleX = (1.0 - flipProgress * 2).abs();
// At 50% progress, tile is edge-on (invisible)
// < 50%: Show back, > 50%: Show front
```

**Shake Animation** (200ms):
```dart
// 4 oscillations at ±10 pixels
```

### Performance Considerations

- Tile rendering uses Canvas drawing (no image assets yet)
- Animations use Flutter's standard animation controllers
- Game loop runs at 60 FPS
- Minimal state updates to avoid unnecessary rebuilds

## Future Enhancements

1. **Multiplayer Mode**
   - Use seed from server
   - Track turn-based gameplay
   - Leaderboards

2. **Difficulty Levels**
   - 3x3 (Easy): 9 tiles
   - 4x4 (Medium): 16 tiles
   - 6x6 (Hard): 36 tiles

3. **Power-ups**
   - Hint: Reveal a pair briefly
   - Time freeze: Pause timer for 10s
   - Shuffle: Re-arrange unmatched tiles

4. **Custom Assets**
   - Replace colored squares with themed images
   - Animated tile faces
   - Custom back design

5. **Achievements**
   - Perfect game (no misses)
   - Speed run (complete under 30s)
   - Combo master (10+ combo streak)

## File Structure

```
lib/game/
├── README.md               # This file
├── board_logic.dart        # Pure Dart game logic
├── board_component.dart    # Flame game board
├── tile_component.dart     # Individual tile component
└── game_screen.dart        # Flutter UI wrapper

test/
└── board_logic_test.dart   # Unit tests

assets/
└── README.md               # Asset guidelines
```

## Usage

From anywhere in the app:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const GameScreen(),
  ),
);
```

Or with specific seed:

```dart
FlipzyGame(
  gridSize: 4,
  seed: 12345, // Specific puzzle
  onScoreUpdate: (score, combo) { /* ... */ },
  // ...
)
```
