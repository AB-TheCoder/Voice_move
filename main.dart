import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const VccnApp());
}

//Root app widget

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
//time control model. all along with minutes, increment and display label together

class TimeControl {
    final String label;
    final int minutes;
    final int incrementSeconds;

    const TimeControl(this.label, this.minutes, this.incrementSeconds);
}
//preset time controls(will add more later)
const List<TimeControl> presets = [
    TimeControl("1 min", 1, 0),
    TimeControl("2 | 1", 2, 1),
    TimeControl("3 min", 3, 0),
    TimeControl("3 | 2", 3, 2),
    TimeControl("5 min", 5, 0),
    TimeControl("5 | 3", 5, 3),
    TimeControl("10 min", 10, 0),
    TimeControl("15 | 10", 15, 10),
    TimeControl("30 min", 30, 0),
];

//main clock screen
class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}
//game state
class _ClockScreenState extends State<ClockScreen> {
  TimeControl currentControl = presets[7]; //setting default to 15|10
  late Duration whiteTime = Duration(minutes: currentControl.minutes);
  late Duration blackTime = Duration(minutes: currentControl.minutes);
  int whiteMoves = 0;
  int blackMoves = 1;
  bool whiteToMove = true;
  bool gameOver = false;
  bool isPaused = false;
  String? winner;
  Timer? _timer;

  //speech state
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  Sring _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initSpeech();
  }
  
  void _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
    setState(() {});
  }
//Freezes if the game is over OR a hold-to-speak is in progress.

  void _startTimer() {
  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (gameOver || isPaused) return;

    setState(() {
      if (whiteToMove) {
        whiteTime -= const Duration(seconds: 1);
        if (whiteTime <= Duration.zero) {
          whiteTime = Duration.zero;
          gameOver = true;
          winner = "Black";
        }
      } else {
        blackTime -= const Duration(seconds: 1);
        if (blackTime <= Duration.zero) {
          blackTime = Duration.zero;
          gameOver = true;
          winner = "White";
        }
      }
    });
  });
}

@override
void dispose() {
  _timer?.cancel() //always cancelling to avoid leaks
  super.dispose();
}

String _format(Duration d) {
  final minutes = d.inMinutes.toString().padLeft(2, '0');
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

void _switchTurn() {
  if (gameOver) return;
  setState(() {
    if (whiteToMove) {
      whiteTime += Duration(seconds: currentControl.incrementSeconds);
      whiteMoves++;
    } else {
      blackTime += Duration(seconds: currentControl.incrementSeconds);
      blackMoves++;
    }
    whiteToMove = !whiteToMove;
  });
}

//press and hold + voice (chunk 9 and 10)
//called when a player presses down on their own clock panel.
  // Pauses BOTH clocks and starts listening for their move.

void _onHoldStart(bool isWhitePanel) {
  if (gameOver) return;
  if (isWhitePanel !=whiteToMove) return; //if the wrong player pressed, ignores
  if (!_speechEnabled) return;

  setState(() {
    isPaused = true;
    _recognizedText = '';
  });

  _speech.listen(
    onResult: (result) {
      setState(() {
        _recognizedText = result.recognizedWords;
      });
    },
  );
}

void _onHoldEnd(bool isWhitePanel) {
  if (gameOver) return;
  if(isWhitePanel != whiteToMove) return;

  _speech.stop();
  setState(() => isPaused = false);

  if (_recognizedText.isNotEmpty) {
    debugPrint('Heard: $_recognizedText');
    _switchTurn(); //placeholder- will become "validate the switch"
  }
}
//reset

void _resetGame() {
  setState(() {
    whiteTime = Duration(minutes: currentControl.minutes);
    blackTime = Duration(minutes: currentControl.minutes);
    whiteMoves = 0;
    blackMoves = 1;
    whiteToMove = true;
    gameOver = false;
    winner = null;
    isPaused = false;
    _recognizedText = '';
  });
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
          const Divider(color: Colors.white24),
          ListTile(
            title: const Text("Custom...", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showCustomDialog();
            },
          ),
          const SizedBox(height: 16),
        ],
      );
    },
  );
}
//Custom time control

void _showCustomDialog() {
  final minutesController = TextEditingController();
  final incrementController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: const Text("Custom time control", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisAlignment: MainAxisSize.min,
          children: [
            TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Increment (seconds)", labelStyle: TextStyle(color: Colors.white70)),

            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              //falls back to 10+0 if the file is empty or invalid
              final mins = int.tryParse(minutesController.text) ?? 10;
              final inc = int.tryParse(incrementController.text) ?? 0;
              setState(() {
                currentControl = TimeControl("$mins | $inc", mins, inc);
                whiteTime = Duration(minutes: mins);
                blackTime = Duration(minutes: mins);

              });
              Navigator.pop("Start"),

            }
            child: const Text("Start"),
          ),
        ],
      );
    },
  );
}

void _showAddTimeDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: const Text("Add time", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("+1 min to White", style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => whiteTime += const Duration(minutes: 1));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("+15 sec to White", style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => whiteTime += const Duration(seconds: 15));
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              title: const Text("+1 min to Black", style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => blackTime += const Duration(minutes: 1));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("+15 sec to Black", style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => blackTime += const Duration(seconds: 15));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    };
  );
}

//build

@override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
            child: Stack(
              children: [
                Column(
                    children: [
                        
                      Expanded(
                          child: Transform.rotate(
                              angle: pi,
                              child: _ClockPanel(
                                  time: _format(blackTime),
                                  moves: blackMoves,
                                  timeControl: currentControl.label,
                                  isActive: !whiteToMove, //dims when its not black's turn
                                  recognizedText: _recognizedText,
                                  onHoldStart: () => _onHoldStart(false),
                                  onHoldEnd: () => _onHoldEnd(false),
                                  onTuneTap: _showAddTimeDialog,
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
                      isActive: whiteToMove,
                      recognizedText: _recognizedText,
                      onHoldStart: () => _onHoldStart(true),
                      onHoldEnd: () => _onHoldEnd(true),
                      onTuneTap: _showTimeControlSheet,
                    ),
                  ),
                ],
              ), // closes Column

              if (gameOver)
                Container(
                  color: Colors.black87,
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: Text(
                      "$winner wins on time",
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ], // closes Stack
          ),
        ),
      );
    }
  }

//Clock panel (reuse for both white and black)
class _ClockPanel extends StatelessWidget {
  final String time;
  final int moves;
  final String is Active; //true = this player's turn, false dimmed
  final String recognizedText;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final VoidCallback onTuneTap;

  const _ClockPanel({
    required this.time,
    required this.moves,
    required this.timeControl,
    required this.isActive,
    required this.recognizedText,
    required this.onHoldStart,
    required this.onHoldEnd,
    required this.onTuneTap,
  });
}





  @override
  void initState() {
    super.initState();
    _startTimer();
  }

bool gameOver = false;
String? winner;





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