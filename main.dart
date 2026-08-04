import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:dartchess/dartchess.dart' as chess;

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
//chunk 11 and 16, m adding real analysis for moves jus like the py file did
class ParsedMove {
  final String text;
  final String? promotion;
  ParsedMove(this.text, this.promotion);
}

class MoveParser {
  static const Map<String, String> _pieceWords = {
    'knight': 'N', 'night': 'N', 'bishop': 'B', 'rook': 'R', 'queen': 'Q', 'king': 'K',
  };

  static const Map<String, String> _numberWords = {
    'one': '1', 'two': '2', 'three': '3', 'four': '4', 'five': '5', 'six': '6', 'seven': '7', 'eight': '8',
  };

  static ParsedMove? parse(String raw) {
    if (raw.trim().isEmpty) return null;
    String text = raw.toLowerCase().trim();

    if (text.contains('castle') && text.contains('king')) return ParsedMove('O-O', null);
    if (text.contains('castle') && text.contains('queen')) return ParsedMove('O-O-O', null);

    _numberWords.forEach((word, digit) => text = text.replaceAll(word, digit));

    final isCapture = text.contains('takes') || text.contains('captures');

    String pieceLetter = '';

    String pieceLetter = '';
    for (final entry in _pieceWords.entries) {
      if (text.startsWith(entry.key)) {
        pieceLetter = entry.value;
        break;
      }
    }

    final squarePattern = RegExp(r'[a-h][1-8]');
    final matches = squarePattern.allMatches(text).toList();
    if (matches.isEmpty) return null;

    final destinationMatch = matches.last;
    final destination = destinationMatch.group(0)!;

    String? promotionPiece;
    final afterSquareText = text.substring(destinationMatch.end);
    for (final entry in _pieceWords.entries) {
      if (afterSquareText.contains(entry.key)) {
        promotionPiece = entry.value;
        break;
      }

    }
    final baseText = pieceLetter.isEmpty
        ? (isCapture ? 'x$destination' : destination)
        : (isCapture ? '${pieceLetter}x$destination' : '$pieceLetter$destination');

    return ParsedMove(baseText, promotionPiece);

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

//candidate move (chunk 16) SAN + underlying move 
class _CandidateMove {
  final chess.Move move;
  final String san;
  _CandidateMove(this.move, this.san);
}

//chunk 18: move record
class MoveRecord {
  final String san;
  final Duration timeTaken;
  final Duration clockRemaining;
  MoveRecord(this.san, this.timeTaken, this.clockRemaining);
}

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

  bool _manualPause = false;
  String? _endReason;
  bool _isMuted = false; //mute toggle

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  String _recognizedText = '';
  String? _lastMoveError;

  chess.Position _position = chess.Chess.initial;

  //move history with move record
  List<MoveRecord> _moveHistory = [];
  DateTime _moveStartTime = DateTime.now();

  List<String> _positionHistory = [];
  List<_CandidateMove> _pendingCandidates = [];
  bool get _awaitingConfirmation => _pendingCandidates.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initSpeech();
    _moveStartTime = DateTime.now();
  }

  //speech state
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  String _recognizedText = '';

  
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
          _endReason = "Time";
        }
      } else {
        blackTime -= const Duration(seconds: 1);
        if (blackTime <= Duration.zero) {
          blackTime = Duration.zero;
          gameOver = true;
          winner = "White";
          _endReason = "Time";
        }
      }
    });
  });
}

@override
void dispose() {
  _timer?.cancel(); //always cancelling to avoid leaks
  super.dispose();
}

String _format(Duration d) {
  final minutes = d.inMinutes.toString().padLeft(2, '0');
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

//formats duration as H:MM:SS for pgn (inspiration from lichess analysis board)
String _formatClk(Duration d) {
  final hours = d.inHours;
  final minutes = (d.inminutes % 60).toString().padLeft(2, '0');
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
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
    _moveStartTime = DateTime.now(); //restarting per move stopwatch for time notation
  });
  _checkGameEndConditions();
  if (!gameOver) _checkGameEndConditions();
}
void _checkGameEndConditions() {
  if (_position.isCheckmate) {
    setState(() {
      gameOver = true;
      winner = whiteToMove ? "Black" : "White";
      _endReason = "Checkmate";
    });
  } else if (_position.isStalemate) {
    setState(() {
      gameOver = true;
      winner = null;
      _endReason = "Stalemate";
    });
  }
}

void _checkDrawConditions() {
  final fenParts = _position.fen.split(' ');
  final positionKey = fenParts.length >= 4 ? fenParts.sublist(0, 4).join(' ') : _position.fen;

  _positionHistory.add(positionKey);
  final occurrences = _positionHistory.where((p) => p == positionKey).length;

  if (occurrences >= 3) {
    setState(() {
      gameOver = true;
      winner = null;
      _endReason = "Threefold repitition";
    });
    return;
  }

  if (_isInsufficientMaterial()) {
    setState(() {
      gameOver = true;
      winner = null;
      _endReason = "Insufficient material";
    });
  }
}

bool _isInsufficientMaterial() {
  final all pieces = _position.board.pieces.values.toList();
  final nonKingPieces = allPieces.where((p) => p.role != chess.Role.king).toList();

  if (nonKingPieces.isEmpty) return true;
  if (nonKingPieces.length == 1) {
    final role = nonKingPieces.first.role;
    if (role == chess.Role.bishop || role == chess.Role.knight) return true;
  }
  return false;
}

List<_CandidateMove> _findCandidateMoves(ParsedMove parsed) {
  final results = <_CandidateMove>[];
  final legalMoves = _position.legalMoves;

  for (final entry in legalMoves.entries) {
    final fromSquare = entry.key;
    final destinations = entry.value;
    final movingPiece = _position.board.pieceAt(fromSquare);
    final isPawn = movingPiece?.role == chess.Role.pawn;

    for (final toSquare in chess.SquareSet(destinations).squares) {
      final isPromotionSquare = isPawn && (toSquare.rank == 0 || toSquare.rank == 7);

      if (isPromotionSquare) {
        final wanted = parsed.promotion ?? 'Q';
        const roleMap = {
          'Q': chess.Role.queen, 'R': chess.Role.rook, 'B': chess.Role.bishop, 'N': chess.Role.knight, };
          final role = roleMap[wanted]!;
          final move = chess.NormalMove(from: fromSquare, to: toSquare, promotion: role);
          final sanResult = _position.makeSanUnchecked(move);
          final san = sanResult?.$2 ?? '';
          final sanWithoutPromotion = san.replaceAll(RegExp(r'=[QRBN]'), '');
          if (_looselyMatches(parsed.text, sanWithoutPromotion)) {
            results.add(_CandidateMove(move, san));
          }
        } else {
          final move = chess.NormalMove(from: fromSquare, to: toSquare);
          final sanResult = _position.makeSanUnchecked(move);
          final san = sanResult?.$2 ?? '';
          if (_looselyMatches(parsed.text, san)) {
            results.add(_CandidateMove(move, san));
          }
        }
      }
    }
    return results;
  }

  bool _looselyMatches(String guess, String realSan) {
    String clean(String s) => s.replaceAll(RegExp(r'[+#]'), '').to toLowerCase();
    final g = clean(guess);
    final r = clean(realSan);
    return r == g || r.replaceAll('x', '') == g.replaceAll('x', '');
  }
  void _proposeMove(String rawText) {
    final parsed = MoveParser.parse(rawText);

    if (parsed == null) {
      setState(() {
        _lastMoveError = "Couldn't understand - Try the move picker";
        isPaused = false;
      });
      return;
    }
  }
  final candidates = _findCandidateMoves(parsed);

  if (candidates.isEmpty) {
    setState(() {
      _lastMoveError = "Illegal move: ${parsed.text}";
      isPaused = false;
    });
    return;
  }

  setState(() {
    _pendingCandidates = candidates;
    _lastMoveError = null;
  });
}

//chunk 18: confirming a move now records how long it took and what the mover's clock read right after- before turn switch

void _confirmMove(_CandidateMove chosen) {
  final timeTaken = DateTime.now().difference(_moveStartTime);
  final clockAfter = whiteToMove ? whiteTime : blackTime;

  setState(() {
    _position = 
  })
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
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Minutes", labelStyle: TextStyle(color: Colors.white70)),
            ),
            TextField(
              controller: incrementController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Increment (seconds)", labelStyle: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final mins = int.tryParse(minutesController.text) ?? 10;
              final inc = int.tryParse(incrementController.text) ?? 0;
              setState(() {
                currentControl = TimeControl("$mins | $inc", mins, inc);
                whiteTime = Duration(minutes: mins);
                blackTime = Duration(minutes: mins);
              });
              Navigator.pop(context);
            },
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
    },
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
                      isActive: whiteToMove,
                      recognizedText: _recognizedText,
                      onHoldStart: () => _onHoldStart(true),
                      onHoldEnd: () => _onHoldEnd(true),
                      onTuneTap: _showTimeControlSheet,
                    ),
                  ),
                ],
              ), // closes column

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
            ], // closes stack
          ),
        ),
      );
    }
  }

//Clock panel (reuse for both white and black)
class _ClockPanel extends StatelessWidget {
  final String time;
  final int moves;
  final String timeControl;
  final bool is Active; //true = this player's turn,  if false, then  dimmed
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

@override
Widget build(BuildContext context) {
    return GestureDetector(
      // onLongPressStart/End pass a details object we don't need — the `_` discards it
      onLongPressStart: (_) => onHoldStart(),
      onLongPressEnd: (_) => onHoldEnd(),
      child: Container(
        width: double.infinity,
        // Lighter grey when active (your turn), darker when inactive — matches chess.com clock (inspiration for this project if u didnt know)
        color: isActive ? const Color(0xFF8B8B8B) : const Color(0xFF5A5A5A),
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

            
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    recognizedText,
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
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


//what is the end to this gng. honestly would people even prefer to type their move if the model gets it wrong?. i believe i should try the in built iphone
//model first and if it aint good enough even after adding biases, then we will just switch to model.en, which is 100mb whispr model.