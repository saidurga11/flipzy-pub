import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'board_component.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late FlipzyGame game;
  late ConfettiController _confettiController;

  int score = 0;
  int combo = 0;
  double timeRemaining = 60.0;
  bool showGameOver = false;
  bool showComplete = false;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    game = FlipzyGame(
      gridSize: 4,
      onScoreUpdate: (newScore, newCombo) {
        setState(() {
          // Trigger confetti on combo increase
          if (newCombo > combo && newCombo > 1) {
            _confettiController.play();
          }
          score = newScore;
          combo = newCombo;
        });
      },
      onTimeUpdate: (time) {
        setState(() {
          timeRemaining = time;
        });
      },
      onGameComplete: () {
        setState(() {
          showComplete = true;
        });
        _confettiController.play();
      },
      onGameOver: () {
        setState(() {
          showGameOver = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _restartGame() {
    setState(() {
      showGameOver = false;
      showComplete = false;
      score = 0;
      combo = 0;
      timeRemaining = 60.0;
    });
    game.restart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Game board
            GameWidget(game: game),

            // UI Overlay
            Column(
              children: [
                // Top bar with stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Timer
                      _buildStatCard(
                        icon: Icons.timer,
                        label: 'Time',
                        value: timeRemaining.toInt().toString(),
                        color: timeRemaining < 10
                            ? Colors.red
                            : Colors.blue,
                      ),

                      // Score
                      _buildStatCard(
                        icon: Icons.stars,
                        label: 'Score',
                        value: score.toString(),
                        color: Colors.amber,
                      ),

                      // Combo
                      _buildStatCard(
                        icon: Icons.local_fire_department,
                        label: 'Combo',
                        value: combo > 0 ? 'x$combo' : '-',
                        color: combo > 0 ? Colors.deepOrange : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Restart button
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _restartGame,
                backgroundColor: Colors.blue,
                child: const Icon(Icons.refresh),
              ),
            ),

            // Back button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),

            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 3.14 / 2, // Down
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.3,
                shouldLoop: false,
                colors: const [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.purple,
                  Colors.orange,
                ],
              ),
            ),

            // Game Over Dialog
            if (showGameOver)
              _buildGameOverDialog(
                title: 'Time\'s Up!',
                message: 'You scored $score points',
                icon: Icons.alarm_off,
                color: Colors.red,
              ),

            // Game Complete Dialog
            if (showComplete)
              _buildGameOverDialog(
                title: 'Congratulations!',
                message: 'You completed the game!\nScore: $score\nTime: ${(60 - timeRemaining).toInt()}s',
                icon: Icons.emoji_events,
                color: Colors.amber,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 64, color: color),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.home),
                      label: const Text('Home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _restartGame,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Play Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
