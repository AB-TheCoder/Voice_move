import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const VccnApp());
}

class VccnApp extends StatelessWidget {
  const VccnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VCCN',
        home: const ClockScreen(),
        );
    }
}

class TimeControl {
    final String label;
    final int minutes;
    final int incrementSeconds;

    const TimeControl(this.label, this.minutes, this.incrementSeconds);
}

void _resetGame() {
  setState(() {
    whiteTime = Duration(minutes: currentControl.minutes);
    blackTime = Duration(minutes: currentControl.minutes);
    whiteMoves = 0;
    blackMoves = 1;
    whiteToMove = true;
  });
}

void _showAddTimeDialog() {
  showDialog
}

const List<TimeControl> presets = [
    TimeControl("1 min", 1, 0),
    TimeControl("2 | 1", 2, 1),
    TimeControl("3 min", 3, 0),
    TimeControl("5 min", 5, 0),
    TimeControl("5 | 3", 5, 3),
    TimeControl("10 min", 10, 0),
    TimeControl("15 | 10", 15, 10),
    TimeControl("30 min", 30, 0),
];


class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  TimeControl currentControl = presets[7]; //setting default to 15|10
  late Duration whiteTime = Duration(minutes: currentControl.minutes);
  late Duration blackTime = Duration(minutes: currentControl.minutes);
  int whiteMoves = 0;
  int blackMoves = 1;
  bool whiteToMove = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
            if (whiteToMove) {
                whiteTime -= const Duration(seconds: 1);
            } else {
                blackTime -= const Duration(seconds: 1);
            }
        });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

   String _format(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showTimeControlSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF202020),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              "Select time control",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...presets.map((tc) => ListTile(
                  title: Text(tc.label, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    setState(() {
                      currentControl = tc;
                      whiteTime = Duration(minutes: tc.minutes);
                      blackTime = Duration(minutes: tc.minutes);
                    });
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
            child: Column(
                children: [
                    
                Expanded(
                    child: Transform.rotate(
                        angle: pi,
                        child: _ClockPanel(
                            time: _format(blackTime),
                            moves: blackMoves,
                            timeControl: currentControl.label,
                            onTap: () {},
                            onTuneTap: _showTimeControlSheet,
                        ),
                    ),
                ),
                
                //m writing the code again for black and white
                //this is the control bar
                Container(
                    height: 75,
                    color: const Color(0xFF202020),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                            IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.refresh, color: Colors.white, size: 34),
                            ),
                            IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                            ),
                            IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.history, color: Colors.white, size: 34),
                            ),
                            IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.volume_up, color: Colors.white, size: 34),
                            ),
                        ],
                    ),

                ),
                
                //white
                Expanded(
              child: _ClockPanel(
                time: _format(whiteTime),
                moves: whiteMoves,
                timeControl: currentControl.label,
                onTap: () {},
                onTuneTap: _showTimeControlSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClockPanel extends StatelessWidget {
    final String time;
    final int moves;
    final String timeControl;
    final VoidCallback onTap;
    final VoidCallback onTuneTap;

    const _ClockPanel({
        required this.time,
        required this.moves,
        required this.timeControl,
        required this.onTap,
        required this.onTuneTap,
    });

    @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: const Color(0xFF8B8B8B),
        child: Stack(
          children: [
            Positioned(
              top: 20,
              right: 20,
              child: Text(
                "Moves: $moves",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Center(
              child: Text(
                time,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 100,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  IconButton(
                    onPressed: onTuneTap,
                    icon: const Icon(Icons.tune, size: 32, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeControl,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}