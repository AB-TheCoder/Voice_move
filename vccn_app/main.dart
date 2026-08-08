//chunk 1: imports and design tokens
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:dartchess/dartchess.dart' as chess;
import 'dart:ui' show FontFeature;
import 'package:flutter/services.dart';

//DESIGN TOKENS: (i designed and iterated the UI using claude, asking it to generate the desired UI after providing the existing one, the colors and animations are assisted by claude too)
const String kFont = 'Inter';
const String kClockFont = 'Manrope';

const Color kAppBg = Color(0xFF161512);
const Color kPanelActive = Color(0xFF81B64C);
const Color kPanelIdle = Color(0xFF3E3D3A);
const Color kOnActive = Color(0xFF16240B);
const Color kOnIdle = Color(0xFFA8A7A3);
const Color kBarIcon = Color(0xFFEDEDEB);
const Color kSheetBg = Color(0xFF222220);
const Color kDanger = Color(0xFFE24B4A);
const Color kTarget = Color(0xFFD9A441);

const double kPanelRadius = 24;
const double kPanelGap = 8;
const double kBarHeight = 76;
const double kIconsScale = 1.05;


const Duration kBarFade = Duration(milliseconds: 260);
const Duration kBarMove = Duration(milliseconds: 650);
const Duration kTuneFade = Duration(milliseconds: : 240);
const Duration kTuneSlide = Duration(milliseconds: 300);

//chunk 2: main() and VccnApp root widget

void main() {
  runApp(const VccnApp());
}

//ROOT APP WIDGET

class VccnApp extends StatelessWidget {
  const VccnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VCCN',
        theme: ThemeData(
          fontFamily: kFont,
          scaffoldBackgroundColor: kAppBg,
        ),
        home: const ClockScreen(),
        ); 
    }
}

// chunk 3: spokenmove: this is the parsed move data model:

class SpokenMove {
  final chess.Role? role;
  final chess.File? fromFile;
  final chess.Rank? fromRank;
  final chess.Square? to;
  final chess.Role? promotion;
  final bool isCapture;
  final bool kingsideCastle;
  final bool queensideCastle;

  const SpokenMove({
    this.role,
    this.fromFile,
    this.fromRank,
    this.to,
    this.promotion,
    this.isCapture = false,
    this.kingsideCastle = false,
    this.queensideCastle = false,
  });
  bool get isEmpty => to == null && !kingsideCastle && !queensideCastle;
}

//chunk 4: Move parser vocabulary maps((files, ranks, pieces, captures, SAN letters)) (ive been brainstroming fallicies for this system using claude, and imma just try to solve them here)
//MOVE PARSER


class MoveParser {
  static const Map<String, String> _fileWords = {
    'alpha': 'a', 'alfa': 'a', 'a': 'a', 'ay': 'a', 'eh': 'a', 'hey': 'a',
    'bravo': 'b', 'b': 'b', 'be': 'b', 'bee': 'b', 'bea': 'b',
    'charlie': 'c', 'charley': 'c', 'c': 'c', 'see': 'c', 'sea': 'c', 'si': 'c',
    'delta': 'd', 'd': 'd', 'dee': 'd', 'de': 'd', 'the': 'd',
    'echo': 'e', 'e': 'e', 'ee': 'e', 'eee': 'e',
    'foxtrot': 'f', 'fox': 'f', 'f': 'f', 'ef': 'f', 'eff': 'f',
    'golf': 'g', 'g': 'g', 'gee': 'g', 'jee': 'g', 'ge': 'g',
    'hotel': 'h', 'h': 'h', 'aitch': 'h', 'aich': 'h', 'ache': 'h', 'each': 'h',
  };

  static const Map<String, String> _rankWords = {
    'one': '1', 'won': '1', 'wun': '1', '1': '1',
    'two': '2', 'too': '2', 'tu': '2', '2': '2',
    'three': '3', 'tree': '3', 'free': '3', 'thee': '3', '3': '3',
    'four': '4', 'fore': '4', 'faux': '4', '4': '4',
    'five': '5', 'fife': '5', '5': '5',
    'six': '6', 'sicks': '6', 'sex': '6', '6': '6',
    'seven': '7', 'sevin': '7', '7': '7',
    'eight': '8', 'ate': '8', 'ait': '8', 'hate': '8', '8': '8',
  };

  static const Map<String, chess.Role> _pieceWords = {
    'knight': chess.Role.knight, 'night': chess.Role.knight,
    'nite': chess.Role.knight, 'knights': chess.Role.knight,
    'bishop': chess.Role.bishop, 'bishops': chess.Role.bishop,
    'bishup': chess.Role.bishop,
    'rook': chess.Role.rook, 'rooks': chess.Role.rook, 'rock': chess.Role.rook,
    'brook': chess.Role.rook, 'ruck': chess.Role.rook, 'root': chess.Role.rook,
    'queen': chess.Role.queen, 'queens': chess.Role.queen, 'quinn': chess.Role.queen,
    'king': chess.Role.king, 'kings': chess.Role.king,
    'pawn': chess.Role.pawn, 'pawns': chess.Role.pawn, 'porn': chess.Role.pawn, //twin (sad that iphone native could even transcribe ts into porn)
    'pon': chess.Role.pawn, 'palm': chess.Role.pawn,
  };

  static const Set<String> _captureWords = {
    'takes', 'take', 'taking', 'captures', 'capture', 'x', 'ex', 'times', 'eats',
  };

  static const Map<String, chess.Role> _sanLetters = {
    'n': chess.Role.knight, 'b': chess.Role.bishop, 'r': chess.Role.rook,
    'q': chess.Role.queen, 'k': chess.Role.king,
  };

  static final RegExp _squareRe = RegExp(r'^([a-h])([1-8])$');
  static final RegExp _sanRe = RegExp(r'^([nbrqk])x?([a-h])([1-8])$');
  

//chunk 5: move parser (.parse()) --- castling detection logic

static SpokenMove? parse(String raw) {
  if (raw.trim().isEmpty) return null;

  final text = raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (text.isEmpty) return null;

  //castling---
  // Logic:
    //   - "queenside"/"long"/"big" -> queenside castle
    //   - "kingside"/"short" -> kingside castle
    //   - bare "castle" with no side named -> BOTH flags set, so
    //     _matchMoves returns both legal castling candidates and the
    //     existing confirm-move UI lets the player pick, instead of silently guessing kingside

    final mentionsCastle = text.contains('castle') ||
        text.contains('castles') ||
        text.contains('casling');
    final mentionsShort = text.contains('short');
    final mentionsLong = text..contains('long') || text.contains('big');

    if (mentionsCastle || mentionsShort || mentionsLong) {
      final wantsQueenside = 
        (text.contains('queen') || mentionsLong) && !mentionsShort;
      final wantsKingside = 
          (text.contains('king') || mentionsShort) && !wantsQueenside;

      if (wantsQueenside) {
        return const SpokenMove(queensideCastle: true);
      }
      if (wantsKingside) {
        return const SpokenMove(kingsideCastle: true);
      }
      if (mentionsCastle) {
        return const SpokenMove(kingsideCastle: true, queensideCastle: true);
      }
    }

    //chunk 6: MoveParser.parse()- tokenizing, enpassant, symbol merge, role/dest extraction
    final symbols = <_Sym>[];
    // "en passant" doesn't name a square of its own — it's a spoken
    // qualifier on a normal pawn capture (e.g. "e5 takes d6 en
    // passant"). dartchess already generates the en passant capture
    // as an ordinary legal move to the passed-over square, so no
    // special-case move logic is needed here — this only has to (a)
    // register capture intent, since players often say "en passant"
    // instead of "takes", and (b) strip the phrase before tokenizing
    // so "passant" and "en" don't get treated as unrecognized noise
    // tokens (harmless either way, but cleaner)
    bool isCapture = text.contains('en passant') || text.contains('onpassant');
    final cleanedText =
        text.replaceAll('en passant', ' ').replaceAll('onpassant', ' ');

    for (final token in cleanedText.split(' ')) {
      if (token.isEmpty) continue;

      if (_captureWords.contains(token)) {
        isCapture = true;
        continue;
      }

      final sq = _squareRe.firstMatch(token);
      if (sq != null) {
        symbold.add(_Sym.square(token));
        continue;
      }

      final san = _sanRe.firstMatch(token);
      if (san != null) {
        symbols.add(_Sym.piece(_sanLetters[san.group(1)!]));
        symbols.add(_Sym.square('${san.group(2)}${san.group(3)}'));
        if (token.contains('x')) isCapture = true;
        continue;
      }
      final piece = _pieceWords[token];
      if (piece != null) {
        symbols.add(_Sym.piece(piece));
        continue;
      }

      final file = _fileWords[token];
      if (file != null) {
        symbols.add(_Sym.file(file));
        continue;
      }

      final rank = _rankWords[token];
      if (rank != null) {
        symbols.add(_Sym.rank(rank));
        continue;
      }
    }


    final merged = <_Sym>[];
    for (int i = 0; i < symbols.length; i++) {
      final s = symbols[i];
      if (s.kind == _SymKind.file &&
          i + 1 < symbols.length &&
          symbols[i + 1].kind == _SymKind.rank) {
        merged.add(_Sym.square('${s.text}${symbols[i+1].text}'));
        i++;
      } else {
        merged.add(s);
      }
    }

    int destIndex = -1;
    for (int i = merged.length - 1; i >= 0; i--) {
      if (merged[i].kind == _SymKind.square) {
        destIndex = i;
        break;
      }
    }
    if (destIndex == -1) return null;

    final to = chess.Square.parse(merged[destIndex].text);
    if (to == null) return null;

    chess.Role? role;
    chess.Role? promotion;
    chess.File? fromFile;
    chess.Rank? fromRank;

    for (int i = 0; i < merged.length; i++) {
      final s = merged[i];
      if (i < destIndex) {
        switch (s.kind) {
          case _SymKind.piece:
            role ??= s.role;
          case _SymKind.square:
            final origin = chess.Square.parse(s.text);
            if (origin != null) {
              fromFile = origin.file;
              fromRank = origin.rank;
            }
          case _SymKind.file:
            fromFile ??= chess.File.fromName(s.text);
          case _SymKind.rank:
            fromRank ??= chess.Rank.fromName(s.text);
        }
      } else if (i > destIndex && s.kind == _SymKind.piece) {
        promotion ??= s.role;
      }
    }

    if (promotion == chess.Role.king || promotion == chess.Role.pawn) {
      promotion = null;
    }

    return SpokenMove(
      role: role,
      fromFile: fromFile,
      fromRank: fromRank,
      to: to,
      promotion: promotion,
      isCapture: isCapture,
    );
  }
}
//chunk 7: _SymKind enum and _Sym helper class
enum _SymKind { square, file, rank, piece }

class _Sym {
  final _SymKind kind;
  final String text;
  final chess.Role? role;

  const _Sym._(this.kind, this.text, this.role);

  factory _Sym.square(String t) => _Sym._(_SymKind.square, t, null);
  factory _Sym.file(String t) => _Sym._(_SymKind.file, t, null);
  factory _Sym.rank(String t) => _Sym._(_SymKind.rank, t, null);
  factory _Sym.piece(chess.Role r) => _Sym._(_SymKind.piece, '', r);
}


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
class ParsedMove {
  final String text;
  final String? promotion;
  ParsedMove(this.text, this.promotion);
}


//time control- model all along with minutes and seconds, increment and display label together

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
    _position = _position.play(chosen.move);
    
  })
}

void _cancelPendingMove() {
  setState(() {
    _pendingCandidates = [];
    isPaused = false;
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
    _lastMoveError = null;
  });

  _speech.listen(
    onResult: (result) {
      setState(() => _recognizedText = result.recognizedWords);
    },
  );
}

void _onHoldEnd(bool isWhitePanel) {
  if (gameOver) return;
  if(isWhitePanel != whiteToMove) return;

  _speech.stop();

  if (_recognizedText.isNotEmpty) {
    setState(() => isPaused = false);
    return;
  }
  _proposeMove(_recognizedText);
}

void _showManualMoveDialog() {
  if (gameOver) return;
  setState(() => isPaused = true);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return PieceSquarePicker(
        onSubmit: (moveText, promotion) {
          Navigator.pop(context);
          _proposeMove(moveText);
        },
        onCancel: () {
          Navigator.pop(context);
          setState(() => isPaused = false);
        },
      );
    },
  );
}


//adjust time attempt at chess.com's clock app scrool wheel type selector

void _showAdjustTimeDialog(bool forWhite) {
  final current = forWhite ? whiteTime : blackTime;
  int selectedMinutes = current.inMinutes;
  int selectedSeconds = current.inSeconds % 60;

  showModalBottomSheet(
    context: context,
    backgroundColor: kSheetBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kPanelRadius)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Adjust time",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Time", style: TextStyle(color: Colors.white, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$selectedMinutes:${selectedSeconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: kPanelActive,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: Row(
                    children: [
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          diameterRatio: 1.4,
                          physics: const FixedExtentScrollPhysics(),
                          controller: FixedExtentScrollController(initialItem: selectedMinutes),
                          onSelectedItemChanged: (i) => setSheetState(() => selectedMinutes = i),
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 180,
                            builder: (context, i) => Center(
                              child: Text('$i',
                                  style: TextStyle(
                                    color: i == selectedMinutes ? Colors.white : Colors.white38,
                                    fontSize: i == selectedMinutes ? 22 : 17,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          diameterRatio: 1.4,
                          physics: const FixedExtentScrollPhysics(),
                          controller: FixedExtentScrollController(initialItem: selectedSeconds),
                          onSelectedItemChanged: (i) => setSheetState(() => selectedSeconds = i),
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 60,
                            builder: (context, i) => Center(
                              child: Text(i.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    color: i == selectedSeconds ? Colors.white : Colors.white38,
                                    fontSize: i == selectedSeconds ? 22 : 17,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPanelActive,
                      foregroundColor: kOnActive,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final newDuration = Duration(minutes: selectedMinutes, seconds: selectedSeconds);
                      setState(() {
                        if (forWhite) {
                          whiteTime = newDuration;
                        } else {
                          blackTime = newDuration;
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Save time", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
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
    _manualPause = false;
    _endReason = null;
    _recognizedText = '';
    _lastMoveError = null;
    _position = chess.Chess.initial;
    _moveHistory = [];
    _positionHistory = [];
    _pendingCandidates = [];
    _moveStartTime = DateTime.now()
  });
}

void _confirmReset() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: kSheetBg
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Reset Clock", style: TextStyle(color: Colors.white)),
        content: const Text("This will reset the game and clocks.", style: TextStyle(color: Color.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          TextButtom(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text("Confirm", style: TextStyle(color: Color.redAccent)),
          ),
        ],
      );
    },
  );
}

void _togglePause() {
  if (gameOver) return;
  setState(() => _manualPause = !_manualPause);
}

void _toggleSound() {
  setState(() {
    _soundState = _soundState == SoundState.on ? SoundState.muted : SoundState.on;
  });
}

void _showTimeControlSheet() {
  showModalBottomSheet(
    context: context,
    backgroundColor: kSheetBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kPanelRadius)),
    ),
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text("Select time control",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...presets.map((tc) => ListTile(
                title: Text(tc.label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
            child: const Text("Start", style: TextStyle(color: kPanelActive)),
          ),
        ],
      );
    },
  );
}
//rewrite this to replace with chess.com's scrool wheel to save time instead
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
//build pgn (chunk 18)

  String _buildPgn() {
    final buffer = StringBuffer();
    buffer.writeln('[Event "VCCN Game"]');
    buffer.writeln('[TimeControl "${currentControl.label}"]');
    buffer.writeln();

    for (int i = 0; i < _moveHistory.length; i++) {
      final record = _moveHistory[i];
      if (i % 2 == 0) {
        buffer.write('${(i ~/ 2) + 1}. ');
      }
      buffer.write('${record.san} {[%clk ${_formatClk(record.clockRemaining)}] [%emt ${_formatClk(record.timeTaken)}]} ');
    }

    if (gameOver) {
      if (_endReason == "Stalemate" ||
          _endReason == "Threefold repetition" ||
          _endReason == "Insufficient material") {
        buffer.write("1/2-1/2");
      } else {
        buffer.write(winner == "White" ? "1-0" : "0-1");
      }
    }

    return buffer.toString().trim();
  }

  void _showPgnDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kSheetBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Game PGN", style: TextStyle(color: Colors.white)),
          content: SelectableText(_buildPgn(), style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(color: Colors.white70))),
          ],
        );
      },
    );
  }

//move time review list (also chunk 18 )

void _showMoveTimesDialog() {
  showDialog(
    context: context
    builder: (context) {
      return AlertDialog(
        backgroundColor: kSheetBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Move Times", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            intemCount: _moveHistory.lenth,
            itemBuilder: (context, index) {
              final record = _moveHistory[index];
              final moveNumber = (index ~/ 2) +1;
              final side = index % 2 == 0 ? "White" : "Black";
              return ListTile(
                dense: true,
                title: Text(
                  "$moveNumber. ${record.san} ($side)",
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: Text(
                  "${record.timeTaken.inSeconds}s"
                  style: const TextStyle(color: kPanelActive, fontWeight: FontWeight.w700),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onpressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(color: Colors.white70))),
        ],
      );
    },
  );
}

@override
Widget build(BuildContext context) {
  final barExpanded = _manualPause || gameOver;

  return Scaffold(
    backgroundColor: kAppBg,
    body: SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(kPanelGap),
            child: Column(
              children: [
                Expanded(
                  child: Transform.rotate(
                    angle: pi,
                    child: _ClockPanel(
                      time: _format(blackTime),
                      moves: blackMoves,
                      timeControl: currentControl.label,
                      isActive: !whiteToMove,
                      isPausedGlobally: _manualPause,
                      showTune: barExpanded,
                      recognizedText: _recognizedText,
                      errorText: _lastMoveError,
                      onHoldStart: () => _onHoldStart(false),
                      onHoldEnd: () => _onHoldEnd(false),
                      onTuneTap: _showTimeControlSheet,
                    ),
                  ),
                ),
                      
                
                      //this is the control bar, originally had 6 icons which claude suggested, but im narrowing down to 4 icons.
                      // will be adding a glowing orange when the move is being recorded. maybe inspired by claude voice-mode type. will be using AI to make the animations smooth for everything.
                      // ill be adding a PGN along with the time taken in the PGN button itself. the glowing orange will be showed when the person holds
                      //the clock side, and itll sort of pulse also maybe, and will fade out when move is recorded/when the stop holding. 
                      // ill be adding a small rounded rectangle which will show the recorded move for 5 seconds above the clock font, and if it is not lgal by parse, then itll automatically to record again: 1) retry recording using voice 2) use the keyboard selector/manually
                      // also, we gotta add a check for "Black resigns" or "White resigns" or draw- like "Draw accepted" by either of the player and it would be added to the PGN
                      // further, i also want to add smooth animations everywhere.
                      // gotta figure out the flutter running again. will be using AI to debug
                      // will be using regular Icons.iconname pack for icons on the bar etc.
                      // also gotta design proper UI for PGN- will we adding time taken along with it- was thinking of taking inspiration of lichess analysis board side bar- not sure, will be adding my accents to it

                      //i logged basically no time today, ill be trying to log 10 hrs on saturday and sunday combined. hopefully will complete uptilthe UI and the backend parsing for each page.
                      //thus, AI usage might be a little higher than usual because i need someone to architect the code for me, but itll still be nominal
                      Container(
                        height: 75,
                        color: const Color(0xFF202020),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: _confirmReset,
                              icon: const Icon(Icons.refresh, color: Colors.white, size: 30),
                            ),
                            IconButton(
                              onPressed: _togglePause,
                              icon: Icon(_manualPause ? Icons.play_arrow : Icons.pause, color: Colors.white, size: 32),
                            ),
                            IconButton(
                              onPressed: _showAddTimeDialog,
                              icon: const Icon(Icons.history, color: Colors.white, size: 30),
                            ),
                            IconButton(
                              onPressed: _showManualMoveDialog,
                              icon: const Icon(Icons.keyboard, color: Colors.white, size: 30),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _isMuted = !_isMuted),
                              icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 30),
                            ),
                            IconButton(
                              onPressed: _showPgnDialog,
                              icon: const Icon(Icons.description, color: Colors.white, size: 30),
                            ),
                            IconButton(
                              onPressed: _showMoveTimesDialog,
                              icon: const Icon(Icons.timer, color: Colors.white, size: 30),
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
                          errorText: _lastMoveError,
                          onHoldStart: () => _onHoldStart(true),
                          onHoldEnd: () => _onHoldEnd(true),
                          onTuneTap: _showTimeControlSheet,
                        ),
                      ),
                    ],
                  ), // closes column
                  
                  if (_awaitingConfirmation)
                    Container(
                      color: Colors.black87,
                      width: double.infinity,
                      height: double.infinity,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _pendingCandidates.length > 1 ? "Which move did you mean?" : "Confirm move:",
                              style: const TextStyle(color: Colors.white, fontSize: 20),
                            ),
                            const SizedBox(height: 16),
                            ..._pendingCandidates.map((c) => Padding(
                              padding: const EdgeInserts.symmetric(vertical: 4),
                              child: ElevatedButton(
                                onPressed: () => _confirmMove(c),
                                child: Text(c.san),
                              ),
                            )),
                            
                          
                          ]

                        )
                      )
                    )

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