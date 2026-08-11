//chunk 1: imports and design tokens
import 'dart:math';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:dartchess/dartchess.dart' as chess;
import 'dart:ui' show FontFeature;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

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
const Duration kTuneFade = Duration(milliseconds: 240);
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
      theme: ThemeData(fontFamily: kFont, scaffoldBackgroundColor: kAppBg),
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

//chunk 4: Move parser vocabulary maps((files, ranks, pieces, captures, SAN letters))
//MOVE PARSER (this was ai generated coz i aint gonna write allat)

class MoveParser {
  static const Map<String, String> _fileWords = {
    'alpha': 'a',
    'alfa': 'a',
    'a': 'a',
    'ay': 'a',
    'eh': 'a',
    'hey': 'a',
    'bravo': 'b',
    'b': 'b',
    'be': 'b',
    'bee': 'b',
    'bea': 'b',
    'charlie': 'c',
    'charley': 'c',
    'c': 'c',
    'see': 'c',
    'sea': 'c',
    'si': 'c',
    'delta': 'd',
    'd': 'd',
    'dee': 'd',
    'de': 'd',
    'the': 'd',
    'echo': 'e',
    'e': 'e',
    'ee': 'e',
    'eee': 'e',
    'foxtrot': 'f',
    'fox': 'f',
    'f': 'f',
    'ef': 'f',
    'eff': 'f',
    'golf': 'g',
    'g': 'g',
    'gee': 'g',
    'jee': 'g',
    'ge': 'g',
    'hotel': 'h',
    'h': 'h',
    'aitch': 'h',
    'aich': 'h',
    'ache': 'h',
    'each': 'h',
  };

  static const Map<String, String> _rankWords = {
    'one': '1',
    'won': '1',
    'wun': '1',
    '1': '1',
    'two': '2',
    'too': '2',
    'tu': '2',
    '2': '2',
    'three': '3',
    'tree': '3',
    'free': '3',
    'thee': '3',
    '3': '3',
    'four': '4',
    'fore': '4',
    'faux': '4',
    '4': '4',
    'five': '5',
    'fife': '5',
    '5': '5',
    'six': '6',
    'sicks': '6',
    'sex': '6',
    '6': '6',
    'seven': '7',
    'sevin': '7',
    '7': '7',
    'eight': '8',
    'ate': '8',
    'ait': '8',
    'hate': '8',
    '8': '8',
  };

  static const Map<String, chess.Role> _pieceWords = {
    'knight': chess.Role.knight,
    'night': chess.Role.knight,
    'nite': chess.Role.knight,
    'knights': chess.Role.knight,
    'bishop': chess.Role.bishop,
    'bishops': chess.Role.bishop,
    'bishup': chess.Role.bishop,
    'rook': chess.Role.rook,
    'rooks': chess.Role.rook,
    'rock': chess.Role.rook,
    'brook': chess.Role.rook,
    'ruck': chess.Role.rook,
    'root': chess.Role.rook,
    'queen': chess.Role.queen,
    'queens': chess.Role.queen,
    'quinn': chess.Role.queen,
    'king': chess.Role.king,
    'kings': chess.Role.king,
    'pawn': chess.Role.pawn,
    'pawns': chess.Role.pawn,
    'porn': chess.Role.pawn,
    'pon': chess.Role.pawn,
    'palm': chess.Role.pawn,
  };

  static const Set<String> _captureWords = {
    'takes',
    'take',
    'taking',
    'captures',
    'capture',
    'x',
    'ex',
    'times',
    'eats',
  };

  static const Map<String, chess.Role> _sanLetters = {
    'n': chess.Role.knight,
    'b': chess.Role.bishop,
    'r': chess.Role.rook,
    'q': chess.Role.queen,
    'k': chess.Role.king,
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

    final mentionsCastle =
        text.contains('castle') ||
        text.contains('castles') ||
        text.contains('casling');
    final mentionsShort = text.contains('short');
    final mentionsLong = text.contains('long') || text.contains('big');

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
    final cleanedText = text
        .replaceAll('en passant', ' ')
        .replaceAll('onpassant', ' ');

    for (final token in cleanedText.split(' ')) {
      if (token.isEmpty) continue;

      if (_captureWords.contains(token)) {
        isCapture = true;
        continue;
      }

      final sq = _squareRe.firstMatch(token);
      if (sq != null) {
        symbols.add(_Sym.square(token));
        continue;
      }

      final san = _sanRe.firstMatch(token);
      if (san != null) {
        symbols.add(_Sym.piece(_sanLetters[san.group(1)!]!));
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
        merged.add(_Sym.square('${s.text}${symbols[i + 1].text}'));
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

//chunk 8: Timecontrol model, presets, _candidate, moverecord, soundstate

//TIME CONTROL MODEL

class TimeControl {
  final String label;
  final int minutes;
  final int incrementSeconds;
  const TimeControl(this.label, this.minutes, this.incrementSeconds);
}

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

class _Candidate {
  final chess.Move move;
  final String san;
  _Candidate(this.move, this.san);
}

class MoveRecord {
  final String san;
  final Duration timeTaken;
  final Duration clockRemaining;
  final bool byWhite;
  const MoveRecord(this.san, this.timeTaken, this.clockRemaining, this.byWhite);
}

enum SoundState { on, muted }

//chunk 9: ClockScreen widget shell + _clockscreenstate feilds

//MAIN CLOCK SCREEN
class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> with WidgetsBindingObserver {
  TimeControl currentControl = presets[7]; //setting default to 15|10
  late Duration whiteTime = Duration(minutes: currentControl.minutes);
  late Duration blackTime = Duration(minutes: currentControl.minutes);
  int whiteMoves = 0;
  // FIX (vuln #5): was initialized to 1, so the panel showed "MOVES 1"
  // for black before black had made any move, and stayed permanently
  // one ahead of the true count thereafter. Nothing else in the UI
  // frames this as a fullmove number, so this was a plain display bug.
  int blackMoves = 0;
  bool whiteToMove = true;
  bool gameOver = false;
  bool isPaused = false;
  String? winner;
  Timer? _timer;

  bool _manualPause = false;
  String? _endReason;
  SoundState _soundState = SoundState.on;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _processUtterance = false;
  String _recognizedText = '';
  String? _lastMoveError;
  // NEW: drives the full-screen "Move not detected" recovery overlay
  // with Try Again / Enter Manually buttons. Non-null = overlay shown.
  String? _recoveryMessage;
  Timer? _finalResultTimer;
  Timer? _recognizedTextTimer;
  // Hard stop for the mic if `_speech.listen` never delivers a final
  // result within its own listenFor window (device/OS speech engine
  // hang) — without this, releasing the hold does nothing and the
  // panel is stuck showing LISTENING/paused indefinitely.
  Timer? _hardTimeoutTimer;

  chess.Position _position = chess.Chess.initial;

  //move history with move record
  List<MoveRecord> _moveHistory = [];
  DateTime _moveStartTime = DateTime.now();

  //gonna change this later because i dont want the player always having to press confirmation for each move, ill just add a undo button to the sucessmove dialogue after transciption

  List<String> _positionHistory = [];
  List<_Candidate> _pendingCandidates = [];
  bool get _awaitingConfirmation => _pendingCandidates.isNotEmpty;

  @override
  //chunk 10: initState/dispose/didChangeAppLifecycleState and _initSpeech
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _positionHistory.add(_positionKey(_position));
    _startTimer();
    _initSpeech();
    _moveStartTime = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel(); //always cancelling to avoid leaks
    _finalResultTimer?.cancel();
    _recognizedTextTimer?.cancel();
    _hardTimeoutTimer?.cancel();
    _speech.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //thats a mouthful
    if (state != AppLifecycleState.resumed && _isListening) {
      _speech.stop();
      _finalResultTimer?.cancel();
      _hardTimeoutTimer?.cancel();
      setState(() {
        _isListening = false;
        isPaused = false;
        _recognizedText = '';
        _processUtterance = false; // FIX: reset on interrupted lifecycle
      });
    }
  }

  Future<void> _initSpeech() async {
    final enabled = await _speech.initialize(
      onError: (error) {
        debugPrint('Speech error: ${error.errorMsg}');
        if (mounted && _isListening) {
          setState(() {
            _isListening = false;
            isPaused = false;
            _lastMoveError = "Mic error - use the keyboard";
            _processUtterance = false; //FIX: reset on error
          });
        }
      },
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
    if (!mounted) return;
    setState(() => _speechEnabled = enabled);
  }

  //chunk 11: Starttimer, _flagfall, _feedback, formatting helpers

  void _feedback({bool heavy = false}) {
    if (_soundState == SoundState.muted) return;
    SystemSound.play(SystemSoundType.click);
    if (heavy) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _flagFall(String winnerSide) {
    gameOver = true;
    winner = winnerSide;
    _endReason = "Time";
    _feedback(heavy: true);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (gameOver || isPaused || _manualPause) return;

      setState(() {
        if (whiteToMove) {
          whiteTime -= const Duration(seconds: 1);
          if (whiteTime <= Duration.zero) {
            whiteTime = Duration.zero;
            _flagFall("Black");
          }
        } else {
          blackTime -= const Duration(seconds: 1);
          if (blackTime <= Duration.zero) {
            blackTime = Duration.zero;
            _flagFall("White");
          }
        }
      });
    });
  }

  String _format(Duration d) {
    final hours = d.inHours;
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  //formats duration as H:MM:SS for pgn (inspiration from lichess analysis board)
  String _formatClk(Duration d) {
    final hours = d.inHours;
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatTaken(Duration d) {
    if (d.inMinutes >= 1) {
      return '${d.inMinutes}m ${(d.inSeconds % 60)}s';
    }
    return '${d.inSeconds}.${(d.inMilliseconds % 1000) ~/ 100}s';
  }

  String _positionKey(chess.Position p) {
    // Defensive: dartchess's `fen` getter shouldn't throw for a
    // Position reached via legal play, but this guards threefold
    // detection from crashing the whole game loop if it ever does —
    // repetition just won't be detected for that one comparison rather than the app going down mid-game.

    try {
      final parts = p.fen.split(' ');
      return parts.length >= 4 ? parts.sublist(0, 4).join(' ') : p.fen;
    } catch (e) {
      debugPrint('_positionKey: failed to read FEN ($e)');
      return 'unknown-${identityHashCode(p)}';
    }
  }

  // chunk 12: _matchMoves- the move-matching engine-

  List<_Candidate> _matchMoves(SpokenMove spoken) {
    final withRole = <_Candidate>[];
    final pawnOnly = <_Candidate>[];
    final anyRole = <_Candidate>[];
    final seenSan = <String>{};

    for (final entry in _position.legalMoves.entries) {
      final from = entry.key;
      final piece = _position.board.pieceAt(from);
      if (piece == null) continue;

      for (final to in entry.value.squares) {
        final isPawn = piece.role == chess.Role.pawn;
        final promotes =
            isPawn &&
            (to.rank == chess.Rank.first || to.rank == chess.Rank.eighth);

        final promoRoles = promotes
            ? <chess.Role?>[spoken.promotion ?? chess.Role.queen]
            : <chess.Role?>[null];

        for (final promo in promoRoles) {
          final move = chess.NormalMove(from: from, to: to, promotion: promo);
          final (san, _) = _position.makeSanUnchecked(move);

          final isShort = san.startsWith('O-O') && !san.startsWith('O-O-O');
          final isLong = san.startsWith('O-O-O');

          if (spoken.kingsideCastle || spoken.queensideCastle) {
            // Bare "castle" sets both flags — match either side so both legal candidates surface for the confirm-move UI. (gonna change this later)
            final matchesShort = spoken.kingsideCastle && isShort;
            final matchesLong = spoken.queensideCastle && isLong;
            if (!matchesShort && !matchesLong) continue;
            if (seenSan.add(san)) anyRole.add(_Candidate(move, san));
            continue;
          }

          if (isShort || isLong) continue;
          if (to != spoken.to) continue;
          if (spoken.fromFile != null && from.file != spoken.fromFile) continue;
          if (spoken.fromRank != null && from.rank != spoken.fromRank) continue;

          final candidate = _Candidate(move, san);
          if (spoken.role != null) {
            if (piece.role != spoken.role) continue;
            if (seenSan.add(san)) withRole.add(candidate);
          } else {
            if (!seenSan.contains(san)) {
              seenSan.add(san);
              if (isPawn) {
                pawnOnly.add(candidate);
              } else {
                anyRole.add(candidate);
              }
            }
          }
        }
      }
    }

    List<_Candidate> result;
    if (spoken.role != null) {
      result = withRole;
    } else if (spoken.isCapture) {
      // FIX: capture intent now decides pool choice up front instead
      // of only filtering within whichever pool (pawnOnly vs anyRole)
      // got picked by other rules. Previously "takes e5" with both a
      // legal non-capturing pawn push AND a legal capturing piece
      // move to e5 would silently return the pawn push, because
      // pawnOnly was chosen before isCapture was ever consulted.

      final combined = [...pawnOnly, ...anyRole];
      final captures = combined.where((c) => c.san.contains('x')).toList();
      if (captures.isNotEmpty) {
        result = captures;
      } else if (pawnOnly.isNotEmpty) {
        result = pawnOnly;
      } else {
        result = anyRole;
      }
    } else if (pawnOnly.isNotEmpty) {
      result = pawnOnly;
    } else {
      result = anyRole;
    }

    // Role was named explicitly (e.g. "knight takes e5"); narrow within that already-role-filtered pool the same way as before.

    if (spoken.isCapture && spoken.role != null && result.length > 1) {
      final captures = result.where((c) => c.san.contains('x')).toList();
      if (captures.isNotEmpty) result = captures;
    }

    return result;
  }

  //chunk 13: _offerDraw and _proposeSpoken (resign/draw/parse dispatch) (got feedback from aarav to add this feature too)
  void _offerDraw() {
    setState(() {
      isPaused = false;
      _recognizedText = '';
      _lastMoveError = null;
    });
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kSheetBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Draw offered",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Does the other player accept the draw?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Decline",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                gameOver = true;
                winner = null;
                _endReason = "Draw agreed";
              });
              _feedback(heavy: true);
            },
            child: const Text("Accept", style: TextStyle(color: kPanelActive)),
          ),
        ],
      ),
    );
  }

  // FIX: every exit path of this method now resets _processingUtterance,
  // and _armRecognizedTextTimer no longer leaves the flag stuck.
  void _proposeSpoken(String rawText) {
    final lower = rawText.toLowerCase();
    if (lower.contains('resign')) {
      final saysWhite = lower.contains('white');
      final saysBlack = lower.contains('black');
      final whiteResigns = saysWhite && !saysBlack
          ? true
          : saysBlack && !saysWhite
          ? false
          : whiteToMove;
      _resign(whiteResigns);
      _processUtterance = false;
      return;
    }

    if (lower.contains('draw')) {
      _offerDraw();
      _processUtterance = false;
      return;
    }

    final spoken = MoveParser.parse(rawText);

    // FIX: both failure branches now show the Try Again / Enter
    // Manually recovery overlay instead of a fading inline hint, and
    // deliberately leave isPaused=true so the clock stays frozen until the user resolves it via one of the two buttons
    if (spoken == null || spoken.isEmpty) {
      setState(() {
        _lastMoveError = null;
        _recoveryMessage = "Move not detected";
      });
      _processUtterance = false;
      return;
    }

    final candidates = _matchMoves(spoken);

    if (candidates.isEmpty) {
      setState(() {
        _lastMoveError = null;
        _recoveryMessage = "Move not detected";
      });
      _processUtterance = false;
      return;
    }

    setState(() {
      _pendingCandidates = candidates;
      _lastMoveError = null;
      _recoveryMessage = null;
    });
    _processUtterance = false;
  }

  //chunk 14: resign and _proposeFromSquares (manual move picker legality path)
  void _resign(bool whiteResigns) {
    setState(() {
      gameOver = true;
      winner = whiteResigns ? "Black" : "White";
      _endReason = "Resignation";
      isPaused = false;
      _recognizedText = '';
      _lastMoveError = null;
    });
    _feedback(heavy: true);
  }

  void _proposeFromSquares(String fromName, String toName) {
    final from = chess.Square.parse(fromName);
    final to = chess.Square.parse(toName);
    if (from == null || to == null) {
      setState(() {
        _lastMoveError = "Invalid square";
        isPaused = false;
      });
      return;
    }

    final piece = _position.board.pieceAt(from);
    final promotes =
        piece?.role == chess.Role.pawn &&
        (to.rank == chess.Rank.first || to.rank == chess.Rank.eighth);

    final roles = promotes
        ? <chess.Role?>[
            chess.Role.queen,
            chess.Role.rook,
            chess.Role.bishop,
            chess.Role.knight,
          ]
        : <chess.Role?>[null];

    final candidates = <_Candidate>[];
    for (final promo in roles) {
      final move = chess.NormalMove(from: from, to: to, promotion: promo);
      if (!_position.isLegal(move)) continue;
      final (san, _) = _position.makeSanUnchecked(move);
      candidates.add(_Candidate(move, san));
    }

    if (candidates.isEmpty) {
      setState(() {
        _lastMoveError = "Illegal: ${from.name}${to.name}";
        isPaused = false;
      });
      return;
    }

    setState(() {
      _pendingCandidates = candidates;
      _lastMoveError = null;
    });
  }

  //chunk 15: _confirmMove, _evaluateGameEnd, _cancelPendingMove

  void _confirmMove(_Candidate chosen) {
    // FIX (vuln #1 + #2): guards against a double-tap on the same
    // candidate button re-playing an already-played move (which
    // dartchess.play() throws on, since the move is no longer legal
    // in the resulting position), and against a Confirm tap that was already in flight landing after Cancel already cleared state
    // Once `chosen` is no longer present in `_pendingCandidates` which happens the instant the first confirm (or a cancel) runs any further call for the same tap is a no-op.

    if (!_pendingCandidates.contains(chosen)) return;

    final now = DateTime.now();
    final timeTaken = now.difference(_moveStartTime);
    final movedByWhite = whiteToMove;

    setState(() {
      _position = _position.play(chosen.move);

      if (movedByWhite) {
        whiteTime += Duration(seconds: currentControl.incrementSeconds);
        whiteMoves++;
      } else {
        blackTime += Duration(seconds: currentControl.incrementSeconds);
        blackMoves++;
      }

      _moveHistory.add(
        MoveRecord(
          chosen.san,
          timeTaken,
          movedByWhite ? whiteTime : blackTime,
          movedByWhite,
        ),
      );

      whiteToMove = !whiteToMove;
      _moveStartTime = now;
      _pendingCandidates = [];
      isPaused = false;
      _recognizedText = '';
      _lastMoveError = null;
      _recoveryMessage = null;
      _positionHistory.add(_positionKey(_position));
    });

    _recognizedTextTimer?.cancel();
    _processUtterance = false; // FIX: guarantee reset once a move lands
    _feedback();
    _evaluateGameEnd();
  }

  void _evaluateGameEnd() {
    String? reason;
    String? winnerSide;

    if (_position.isCheckmate) {
      reason = "Checkmate";
      winnerSide = _position.turn == chess.Side.white ? "Black" : "White";
    } else if (_position.isStalemate) {
      reason = "Stalemate";
    } else if (_position.isInsufficientMaterial) {
      reason = "Insufficient material";
    } else if (_position.halfmoves >= 100) {
      reason = "50-move rule";
    } else {
      final key = _positionKey(_position);
      if (_positionHistory.where((p) => p == key).length >= 3) {
        reason = "Threefold repitition";
      }
    }

    if (reason == null) return;

    setState(() {
      gameOver = true;
      winner = winnerSide;
      _endReason = reason;
    });
    _feedback(heavy: true);
  }

  void _cancelPendingMove() {
    _recognizedTextTimer?.cancel();
    setState(() {
      _pendingCandidates = [];
      _recognizedText = '';
      _recoveryMessage = null;
      isPaused = false;
    });
    _processUtterance = false; // FIX: reset on cancel too
  }
  // FIX (vuln #4): the clock previously only paused inside
  // _onHoldStart, which is wired to onLongPressStart — Flutter's
  // default long-press recognizer waits ~500ms of holding before that
  // fires. That's a real, silent gap where the clock keeps ticking
  // after the player has already started their hold, on every single voice move
  // onLongPressDown fires the instant the finger touches
  // down, before the hold duration is even evaluated, so pausing here
  // closes that gap. This does NOT start listening — only _onHoldStart
  // (after the real long-press threshold) engages the mic, same as before

  //chunk 16: _onHoldDown/_onHoldStart/_onHoldEnd/_processUtterance -press-and-hold voice flow;

  void _onHoldDown(bool isWhitePanel) {
    if (gameOver || _awaitingConfirmation) return;
    if (isWhitePanel != whiteToMove) return;

    if (_manualPause) return;
    if (isPaused) return;
    setState(() => isPaused = true);
  }

  // Shared by the real long-press path and the undo-triggered
  // re-listen (_undoLastMove above), so both stay in sync with the
  // same guards, timers, and speech.listen() setup rather than two
  // divergent copies of this logic.

  void _startListeningFor(bool isWhitePanel) {
    if (gameOver || _awaitingConfirmation) return;
    if (isWhitePanel != whiteToMove) return;
    if (_isListening) return; // FIX: ignore a stray double hold-start
    // FIX (vuln #3): previously never checked _manualPause, so
    // tapping Pause didn't actually stop a player from holding to
    // speak, getting a move recognized, and confirming it while the
    // app visually showed "paused".
    if (_manualPause) return;

    if (!_speechEnabled) {
      setState(() => _lastMoveError = "Mic unavailable — use the keyboard");
      return;
    }

    _finalResultTimer?.cancel();
    _recognizedTextTimer?.cancel();
    _hardTimeoutTimer?.cancel();
    setState(() {
      isPaused = true;
      _isListening = true;
      _processUtterance = false;
      _recognizedText = '';
      _lastMoveError = null;
      _recoveryMessage = null;
    });

    _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _recognizedText = result.recognizedWords);
        if (result.finalResult && !_isListening) {
          _finalResultTimer?.cancel();
          _processUtteranceMethod();
        }
      },
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 4),
      localeId: 'en_US',
    );

    // FIX: hard fallback — if the engine never calls onResult with a
    // final result and the hold is never released, force a stop and
    // process whatever's been heard (or show recovery) after a beat
    // past the engine's own 12s window, instead of hanging forever.
    _hardTimeoutTimer = Timer(const Duration(seconds: 13), () {
      if (mounted && _isListening) {
        _onHoldEnd(isWhitePanel);
      }
    });
  }

  void _onHoldStart(bool isWhitePanel) => _startListeningFor(isWhitePanel);

  void _onHoldEnd(bool isWhitePanel) {
    if (isWhitePanel != whiteToMove) return;

    if (_isListening) {
      _hardTimeoutTimer?.cancel();
      setState(() => _isListening = false);
      _speech.stop();

      _finalResultTimer?.cancel();
      _finalResultTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) _processUtteranceMethod();
      });
    } else if (isPaused) {
      // FIX (vuln #4, companion): the hold was released (or cancelled)
      // before the long-press threshold ever engaged the mic — e.g. a
      // quick tap, or _startListeningFor's own guards (gameOver,
      // _manualPause, _awaitingConfirmation) blocked it. _onHoldDown
      // already paused the clock on touch-down, so it must be
      // un-paused here too, or a short accidental tap would leave the
      // clock frozen with no listening session to ever resolve it.
      setState(() => isPaused = false);
    }
  }

  void _processUtteranceMethod() {
    if (_processUtterance) return;
    _processUtterance = true;

    final heard = _recognizedText.trim();
    if (heard.isEmpty) {
      setState(() {
        _lastMoveError = null;
        _recoveryMessage = "Move not detected";
      });
      _processUtterance = false;
      return;
    }
    _proposeSpoken(heard);
  }

  //NEW: 'try again' to be dismissed and start listening right away, without needing to hold the panel

  //chunk 17: _retryVoice, _switchToManual, _legalMoveData, _showManualMoveDialog

  void _retryVoice() {
    setState(() => _recoveryMessage = null);
    _startListeningFor(whiteToMove);
  }

  // NEW: "Enter Manually" — dismiss the overlay and jump straight to the keyboard square picker

  void _switchToManual() {
    setState(() => _recoveryMessage = null);
    _showManualMoveDialog();
  }

  // FIX: builds a from-square -> legal-destination-squares map from the
  // live position, used to power the reworked keyboard picker so it can
  // only ever offer legal moves instead of letting the user tap blind.
  // Builds both the from -> legal-destinations map and a from -> piece
  // role map, so the picker can show a piece-type selector row and
  // highlight-by-role before drilling into a specific square.
  ({Map<String, Set<String>> legalMoves, Map<String, chess.Role> pieceRoles})
  _legalMoveData() {
    final moves = <String, Set<String>>{};
    final roles = <String, chess.Role>{};
    for (final entry in _position.legalMoves.entries) {
      final from = entry.key;
      final piece = _position.board.pieceAt(from);
      if (piece == null) continue;
      final dests = entry.value.squares.map((s) => s.name).toSet();
      if (dests.isEmpty) continue;
      moves[from.name] = dests;
      roles[from.name] = piece.role;
    }
    return (legalMoves: moves, pieceRoles: roles);
  }

  void _showManualMoveDialog() {
    if (gameOver) return;
    setState(() {
      isPaused = true;
      _recoveryMessage = null;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final data = _legalMoveData();
        return PieceSquarePicker(
          legalMoves: data.legalMoves,
          pieceRoles: data.pieceRoles,
          whiteToMove: whiteToMove,
          onSubmit: (fromSquare, toSquare) {
            Navigator.pop(sheetContext);
            _proposeFromSquares(fromSquare, toSquare);
          },
          onCancel: () {
            Navigator.pop(sheetContext);
            setState(() => isPaused = false);
          },
        );
      },
    );
  }

  //chunk 18: _resetGame, _confirmReset, _togglePause, _toggleSound

  void _resetGame() {
    setState(() {
      whiteTime = Duration(minutes: currentControl.minutes);
      blackTime = Duration(minutes: currentControl.minutes);
      whiteMoves = 0;
      blackMoves = 0;
      whiteToMove = true;
      gameOver = false;
      winner = null;
      isPaused = false;
      _manualPause = false;
      _endReason = null;
      _recognizedText = '';
      _lastMoveError = null;
      _recoveryMessage = null;
      _position = chess.Chess.initial;
      _moveHistory = [];
      _positionHistory = [_positionKey(chess.Chess.initial)];
      _pendingCandidates = [];
      _moveStartTime = DateTime.now();
    });
    _processUtterance = false; // FIX: also clear on reset
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kSheetBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Reset clock",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "This will reset the game and clocks.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _resetGame();
              },
              child: const Text("Confirm", style: TextStyle(color: kDanger)),
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
      _soundState = _soundState == SoundState.on
          ? SoundState.muted
          : SoundState.on;
    });
    if (_soundState == SoundState.on) _feedback();
  }

  //chunk 19: _showTimeEditDialog and scroll wheel time adjuster (like chess.com app)

  //adjust time attempt at chess.com's clock app scrool wheel type selector

  void _showTimeEditDialog(bool forWhite) {
    final currentDuration = forWhite ? whiteTime : blackTime;

    showModalBottomSheet(
      context: context,
      backgroundColor: kSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kPanelRadius)),
      ),
      builder: (sheetContext) {
        return _TimeScrollWheelSheet(
          forWhite: forWhite,
          initialDuration: currentDuration,
          onSave: (newDuration) {
            if (newDuration == Duration.zero) {
              showDialog(
                context: context,
                builder: (confirmContext) => AlertDialog(
                  backgroundColor: kSheetBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    "Set time to 0:00?",
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    "${forWhite ? 'White' : 'Black'} will flag on the next tick.",

                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(confirmContext),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(confirmContext);
                        setState(() {
                          if (forWhite) {
                            whiteTime = newDuration;
                          } else {
                            blackTime = newDuration;
                          }
                        });
                      },
                      child: const Text(
                        "Confirm",
                        style: TextStyle(color: kDanger),
                      ),
                    ),
                  ],
                ),
              );
              return;
            }

            setState(() {
              if (forWhite) {
                whiteTime = newDuration;
              } else {
                blackTime = newDuration;
              }
            });
          },
        );
      },
    );
  }

  //chunk 20: _showTimeControlSheet and _showCustomDialog

  void _showTimeControlSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kPanelRadius)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                "Select time control",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...presets.map(
                      (tc) => ListTile(
                        title: Text(
                          tc.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: tc.label == currentControl.label
                            ? const Icon(Icons.check, color: kPanelActive)
                            : null,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          setState(() {
                            currentControl = tc;
                            _resetGame();
                          });
                        },
                      ),
                    ),
                    const Divider(color: Colors.white24),
                    ListTile(
                      title: const Text(
                        "Custom...",
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showCustomDialog();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
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
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kSheetBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Custom time control",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Minutes",
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              TextField(
                controller: incrementController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Increment (seconds)",
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                final mins = int.tryParse(minutesController.text) ?? 10;
                final inc = int.tryParse(incrementController.text) ?? 0;
                Navigator.pop(dialogContext);
                setState(() {
                  // FIX: label now uses the SAME clamped values that are
                  // actually applied to the TimeControl. Previously the
                  // label showed the raw, unclamped `$mins | $inc` while
                  // the real minutes/incrementSeconds were clamped to
                  // (1..180) / (0..60) — so an out-of-range entry (e.g.
                  // "300" minutes) could show "300 | 0" as the label but
                  // silently start a 180-minute game, which is confusing.
                  currentControl = TimeControl(
                    "${mins.clamp(1, 180)} | ${inc.clamp(0, 60)}",
                    mins.clamp(1, 180),
                    inc.clamp(0, 60),
                  );
                  _resetGame();
                });
              },
              child: const Text("Start", style: TextStyle(color: kPanelActive)),
            ),
          ],
        );
      },
    ).then((_) {
      minutesController.dispose();
      incrementController.dispose();
    });
  }

  //chunk 21: _buildPgn, _showPgnSheet, and the main build() layout

  String _buildPgn() {
    final buffer = StringBuffer();
    buffer.writeln('[Event "VCCN Game"]');
    buffer.writeln(
      '[Date "${DateTime.now().toIso8601String().split('T').first}"]',
    );
    buffer.writeln(
      '[TimeControl "${currentControl.minutes * 60}'
      '${currentControl.incrementSeconds > 0 ? '+${currentControl.incrementSeconds}' : ''}"]',
    );

    buffer.writeln();

    for (int i = 0; i < _moveHistory.length; i++) {
      final record = _moveHistory[i];
      if (i % 2 == 0) buffer.write('${(i ~/ 2) + 1}. ');
      buffer.write(
        '${record.san} '
        '{[%clk ${_formatClk(record.clockRemaining)}] '
        '[%emt ${_formatClk(record.timeTaken)}]} ',
      );
    }

    if (gameOver) {
      if (winner == null) {
        buffer.write("1/2-1/2");
      } else {
        buffer.write(winner == "White" ? "1-0" : "0-1");
      }
    } else {
      buffer.write("*");
    }

    return buffer.toString().trim();
  }

  void _showPgnSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kPanelRadius)),
      ),
      builder: (sheetContext) {
        return _PgnSheet(
          pgn: _buildPgn(),
          moves: _moveHistory,
          formatTaken: _formatTaken,
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
                        isListening: _isListening && !whiteToMove,
                        recognizedText: whiteToMove ? '' : _recognizedText,
                        errorText: whiteToMove ? null : _lastMoveError,
                        onHoldDown: () => _onHoldDown(false),
                        onHoldStart: () => _onHoldStart(false),
                        onHoldEnd: () => _onHoldEnd(false),
                        onTuneTap: _showTimeControlSheet,
                        onManualOverride: _showManualMoveDialog,
                        onTimeTap: () => _showTimeEditDialog(false),
                        // Island only shows on the side that actually
                        // moved — the other panel's copy stays null.
                        lastPlayedSan: _lastPlayedByWhite == false
                            ? _lastPlayedSan
                            : null,
                        onUndo: _undoLastMove,
                      ),
                    ),
                  ),
                  _ControlBar(
                    expanded: barExpanded,
                    manualPause: _manualPause,
                    soundState: _soundState,
                    moveCount: _moveHistory.length,
                    icons: [
                      _BarIcon(
                        kind: _BarIconKind.refresh,
                        onPressed: _confirmReset,
                      ),
                      _BarIcon(
                        kind: _BarIconKind.playPause,
                        onPressed: _togglePause,
                      ),
                      _BarIcon(
                        kind: _BarIconKind.keyboard,
                        onPressed: _showManualMoveDialog,
                      ),
                      _BarIcon(
                        kind: _BarIconKind.timeControl,
                        collapsible: true,
                        onPressed: _showTimeControlSheet,
                      ),
                      _BarIcon(
                        kind: _BarIconKind.sound,
                        onPressed: _toggleSound,
                      ),
                      _BarIcon(
                        kind: _BarIconKind.description,
                        collapsible: true,
                        onPressed: _showPgnSheet,
                      ),
                    ],
                  ),
                  Expanded(
                    child: _ClockPanel(
                      time: _format(whiteTime),
                      moves: whiteMoves,
                      timeControl: currentControl.label,
                      isActive: whiteToMove,
                      isPausedGlobally: _manualPause,
                      showTune: barExpanded,
                      isListening: _isListening && whiteToMove,
                      recognizedText: whiteToMove ? _recognizedText : '',
                      errorText: whiteToMove ? _lastMoveError : null,
                      onHoldDown: () => _onHoldDown(true),
                      onHoldStart: () => _onHoldStart(true),
                      onHoldEnd: () => _onHoldEnd(true),
                      onTuneTap: _showTimeControlSheet,
                      onManualOverride: _showManualMoveDialog,
                      onTimeTap: () => _showTimeEditDialog(true),
                      lastPlayedSan: _lastPlayedByWhite == true
                          ? _lastPlayedSan
                          : null,

                      onUndo: _undoLastMove,
                    ),
                  ),
                ],
              ),
            ),

            if (_awaitingConfirmation)
              Container(
                color: kAppBg.withValues(alpha: 0.94),
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _pendingCandidates.length > 1
                            ? "Which move did you mean?"
                            : "Confirm move",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_recognizedText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '"$_recognizedText"',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: _pendingCandidates
                            .map(
                              (c) => ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPanelActive,
                                  foregroundColor: kOnActive,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 26,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => _confirmMove(c),
                                child: Text(
                                  c.san,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: _cancelPendingMove,
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // NEW: "Move not detected" recovery overlay - shown whenever voice input fails to produce a legal move. Clock stays frozen (isPaused remains true) until the user picks one of the two actions below.
            if (_recoveryMessage != null)
              Container(
                color: kAppBg.withValues(alpha: 0.94),
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _recoveryMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _RecoveryButton(
                              icon: Icons.mic,
                              label: "Try Again",
                              filled: false,
                              onPressed: _retryVoice,
                            ),
                            const SizedBox(width: 12),
                            _RecoveryButton(
                              icon: Icons.keyboard,
                              label: "Enter Manually",
                              filled: true,
                              onPressed: _switchToManual,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (gameOver)
              IgnorePointer(
                child: Container(
                  color: kAppBg.withValues(alpha: 0.88),
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          winner != null ? "$winner wins" : "Draw",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "by $_endReason",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

//chunk 22: _RecoveryButton and _TimeScrollWheelSheet/State

//Recovery overlay button (try agaib/ enter manually)
class _RecoveryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onPressed;

  const _RecoveryButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = filled ? kPanelActive : kPanelIdle;
    final Color fg = filled ? kOnActive : Colors.white;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: fg, size: 26),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//Apple style time scroll wheel sheet (hrs, mins, secs)

class _TimeScrollWheelSheet extends StatefulWidget {
  final bool forWhite;
  final Duration initialDuration;
  final ValueChanged<Duration> onSave;

  const _TimeScrollWheelSheet({
    required this.forWhite,
    required this.initialDuration,
    required this.onSave,
  });

  @override
  State<_TimeScrollWheelSheet> createState() => _TimeScrollWheelSheetState();
}

class _TimeScrollWheelSheetState extends State<_TimeScrollWheelSheet> {
  late int _hours;
  late int _minutes;
  late int _seconds;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minController;
  late FixedExtentScrollController _secController;

  @override
  void initState() {
    super.initState();
    _hours = widget.initialDuration.inHours;
    _minutes = widget.initialDuration.inMinutes % 60;
    _seconds = widget.initialDuration.inSeconds % 60;

    _hourController = FixedExtentScrollController(initialItem: _hours);
    _minController = FixedExtentScrollController(initialItem: _minutes);
    _secController = FixedExtentScrollController(initialItem: _seconds);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minController.dispose();
    _secController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Edit ${widget.forWhite ? 'White' : 'Black'} Time",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Expanded(
                  child: Text(
                    "HOURS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kPanelActive,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "MINUTES",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kPanelActive,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "SECONDS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kPanelActive,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.symmetric(
                          horizontal: BorderSide(
                            color: kPanelActive.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: _hourController,
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.5,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) =>
                              setState(() => _hours = index),
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index > 12) return null;
                              return Center(
                                child: Text(
                                  index.toString(),
                                  style: TextStyle(
                                    fontFamily: kClockFont,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: _hours == index
                                        ? Colors.white
                                        : Colors.white38,
                                  ),
                                ),
                              );
                            },
                            childCount: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: _minController,
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.5,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) =>
                              setState(() => _minutes = index),
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index > 59) return null;
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontFamily: kClockFont,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: _minutes == index
                                        ? Colors.white
                                        : Colors.white38,
                                  ),
                                ),
                              );
                            },
                            childCount: 60,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: _secController,
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.5,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) =>
                              setState(() => _seconds = index),
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index > 59) return null;
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontFamily: kClockFont,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: _seconds == index
                                        ? Colors.white
                                        : Colors.white38,
                                  ),
                                ),
                              );
                            },
                            childCount: 60,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPanelActive,
                      foregroundColor: kOnActive,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final duration = Duration(
                        hours: _hours,
                        minutes: _minutes,
                        seconds: _seconds,
                      );
                      Navigator.pop(context);
                      widget.onSave(duration);
                    },
                    child: const Text(
                      "Save",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//chunk 23: _PgnSheet, _MoveCell, _headStyle

//PGN sheet (compiling this at the end idk why, it was as part of the plan (chunk wise))

class _PgnSheet extends StatelessWidget {
  final String pgn;
  final List<MoveRecord> moves;
  final String Function(Duration) formatTaken;

  const _PgnSheet({
    required this.pgn,
    required this.moves,
    required this.formatTaken,
  });

  @override
  Widget build(BuildContext context) {
    final pairs = <(MoveRecord?, MoveRecord?)>[];
    for (int i = 0; i < moves.length; i += 2) {
      pairs.add((moves[i], i + 1 < moves.length ? moves[i + 1] : null));
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Game PGN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  // NEW: share-sheet export. Goes straight to
                  // Lichess/chess.com import, Messages, Mail, AirDrop,
                  // etc. — copy-to-clipboard stays as a fallback next
                  // to it rather than being replaced.
                  TextButton.icon(
                    onPressed: () async {
                      await SharePlus.instance.share(
                        ShareParams(text: pgn, subject: 'VCCN Game'),
                      );
                    },
                    icon: const Icon(
                      Icons.ios_share,
                      size: 18,
                      color: kPanelActive,
                    ),
                    label: const Text(
                      "Share",
                      style: TextStyle(
                        color: kPanelActive,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: pgn));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("PGN copied"),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18, color: kPanelActive),
                    label: const Text(
                      "Copy",
                      style: TextStyle(
                        color: kPanelActive,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: const [
                  SizedBox(width: 34, child: Text("#", style: _headStyle)),
                  Expanded(child: Text("WHITE", style: _headStyle)),
                  Expanded(child: Text("BLACK", style: _headStyle)),
                ],
              ),
              const Divider(color: Colors.white24, height: 14),
              Expanded(
                child: moves.isEmpty
                    ? const Center(
                        child: Text(
                          "No moves yet",
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: pairs.length + 1,
                        itemBuilder: (context, index) {
                          if (index == pairs.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SelectableText(
                                  pgn,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            );
                          }

                          final (white, black) = pairs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 34,
                                  child: Text(
                                    "${index + 1}.",
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _MoveCell(
                                    record: white,
                                    formatTaken: formatTaken,
                                  ),
                                ),
                                Expanded(
                                  child: _MoveCell(
                                    record: black,
                                    formatTaken: formatTaken,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const TextStyle _headStyle = TextStyle(
  color: Colors.white38,
  fontSize: 11,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.8,
);

class _MoveCell extends StatelessWidget {
  final MoveRecord? record;
  final String Function(Duration) formatTaken;

  const _MoveCell({required this.record, required this.formatTaken});

  @override
  Widget build(BuildContext context) {
    if (record == null) return const SizedBox.shrink();
    return Row(
      children: [
        Text(
          record!.san,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          formatTaken(record!.timeTaken),
          style: const TextStyle(
            color: kPanelActive,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

//chunk 24: control bar system - _BarIcon, _ControlBar, hollow icons, painter

//Control Bar

enum _BarIconKind {
  refresh,
  playPause,
  keyboard,
  timeControl,
  sound,
  description,
}

class _BarIcon {
  final _BarIconKind kind;
  final VoidCallback onPressed;
  final bool collapsible;

  const _BarIcon({
    required this.kind,
    required this.onPressed,
    this.collapsible = false,
  });
}

class _ControlBar extends StatelessWidget {
  final bool expanded;
  final List<_BarIcon> icons;
  final bool manualPause;
  final SoundState soundState;
  // FIX: this was passed at the call site (`moveCount: _moveHistory.length`)
  // but never declared here — a real compile error (undefined named
  // parameter), not something cosmetic. Now declared and actually used: drives a small badge on the PGN icon showing the move count.

  final int moveCount;
  final double height;
  final double growth;

  const _ControlBar({
    required this.expanded,
    required this.icons,
    required this.manualPause,
    required this.soundState,
    required this.moveCount,
    this.height = kBarHeight,
    this.growth = 1.22,
  });

  static const double _slot = 60;
  static const double _baseSize = 32;
  static const double _pauseBaseSize = 34;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final top = (height - _slot) / 2;

          final laidOut = expanded
              ? icons
              : icons.where((i) => !i.collapsible).toList();

          double centreOf(int index, int count) =>
              width * (index + 1) / (count + 1);

          return Stack(
            children: List.generate(icons.length, (i) {
              final item = icons[i];
              final slotIndex = laidOut.indexOf(item);
              final double centre = slotIndex >= 0
                  ? centreOf(slotIndex, laidOut.length)
                  : centreOf(i, icons.length);

              final bool visible = item.collapsible ? expanded : true;
              final bool isPauseKind = item.kind == _BarIconKind.playPause;
              final double base =
                  (isPauseKind ? _pauseBaseSize : _baseSize) * kIconsScale;
              final double targetSize = expanded ? base : base * growth;

              return AnimatedPositioned(
                duration: kBarMove,
                curve: const Cubic(0.16, 1, 0.3, 1),
                left: centre - _slot / 2,
                top: top,
                width: _slot,
                height: _slot,
                child: AnimatedOpacity(
                  duration: kBarFade,
                  curve: Curves.easeInOut,
                  opacity: visible ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !visible,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: targetSize),
                      duration: kBarMove,
                      curve: const Cubic(0.16, 1, 0.3, 1),
                      builder: (context, size, _) {
                        return SizedBox(
                          width: _slot,
                          height: _slot,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints.tightFor(
                              width: _slot,
                              height: _slot,
                            ),
                            onPressed: item.onPressed,
                            icon: Center(child: _resolveIcon(item.kind, size)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _resolveIcon(_BarIconKind kind, double size) {
    switch (kind) {
      case _BarIconKind.refresh:
        return Icon(Icons.refresh, color: kBarIcon, size: size);
      case _BarIconKind.playPause:
        return manualPause
            ? _HollowPlayIcon(size: size, color: kPanelActive)
            : _HollowPauseIcon(size: size, color: kBarIcon);
      case _BarIconKind.keyboard:
        return Icon(Icons.keyboard, color: kBarIcon, size: size);
      case _BarIconKind.timeControl:
        return Icon(Icons.timer_outlined, color: kBarIcon, size: size);
      case _BarIconKind.sound:
        return Icon(
          soundState == SoundState.on ? Icons.volume_up : Icons.volume_off,

          color: kBarIcon,
          size: size,
        );
      case _BarIconKind.description:
        // NEW: small badge showing the move count on the PGN icon,
        // driven by the `moveCount` field above (only shown once at least one move has been played).
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.description, color: kBarIcon, size: size),
            if (moveCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    color: kPanelActive,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$moveCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kOnActive,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
    }
  }
}

class _HollowPauseIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _HollowPauseIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    final barWidth = size * 0.16;
    final barHeight = size * 0.6;
    return SizedBox(
      width: size,
      height: size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: barWidth,
            height: barHeight,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: barWidth * 0.6),
          Container(
            width: barWidth,
            height: barHeight,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayOutlinePainter extends CustomPainter {
  final Color color;
  _PlayOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.18)
      ..lineTo(size.width * 0.28, size.height * 0.82)
      ..lineTo(size.width * 0.88, size.height * 0.5)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PlayOutlinePainter old) => old.color != color;
}

//chunk 25: PieceSquarePicker + _ClockPanel/_ClockPanelState (clock face and glow animation)

//Manual move picker (with icons of the pieces as first layer of selection)

class PieceSquarePicker extends StatefulWidget {
  final Map<String, Set<String>> legalMoves;
  final Map<String, chess.Role> pieceRoles;
  final bool whiteToMove;
  final void Function(String fromSquare, String toSquare) onSubmit;
  final VoidCallback onCancel;

  const PieceSquarePicker({
    super.key,
    required this.legalMoves,
    required this.pieceRoles,
    required this.whiteToMove,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<PieceSquarePicker> createState() => _PieceSquarePickerState();
}

const List<chess.Role> _roleOrder = [
  chess.Role.pawn,
  chess.Role.knight,
  chess.Role.bishop,
  chess.Role.rook,
  chess.Role.queen,
  chess.Role.king,
];

String _roleGlyph(chess.Role role) {
  switch (role) {
    case chess.Role.pawn:
      return '♙';
    case chess.Role.knight:
      return '♘';
    case chess.Role.bishop:
      return '♗'
    case chess.Role.rook:
      return '♖'
    case chess.Role.queen:
      return '♕';
    case chess.Role.king:
      return '♔';
  }
}

class _PieceSquarePickerState extends State<PieceSquarePicker> {
  chess.Role? _selectedRole;
  String? _fromSquare;
  String? _toSquare;
 
  Set<String> get _legalDestinations =>
      _fromSquare == null ? const {} : (widget.legalMoves[_fromSquare] ?? const {});
 
  bool get _hasAnyLegalMove => widget.legalMoves.isNotEmpty;
 
  List<chess.Role> get _availableRoles {
    final present = widget.pieceRoles.values.toSet();
    return _roleOrder.where(present.contains).toList();
  }
 
  void _tapRole(chess.Role role) {
    setState(() {
      _selectedRole = _selectedRole == role ? null : role;
      _fromSquare = null;
      _toSquare = null;
    });
    HapticFeedback.selectionClick();
  }

  void _tapSquare(String square) {
    final roleHere = widget.pieceRoles[square];
 
    if (_fromSquare != null) {
      if (square == _fromSquare) {
        setState(() => _fromSquare = null);
        return;
      }
      if (_legalDestinations.contains(square)) {
        setState(() => _toSquare = square);
        HapticFeedback.selectionClick();
        return;
      }
      if (roleHere != null && (_selectedRole == null || roleHere == _selectedRole)) {
        setState(() {
          _fromSquare = square;
          _toSquare = null;
        });
        HapticFeedback.selectionClick();
        return;
      }
      HapticFeedback.lightImpact();
      return;
    }
 
    if (roleHere == null) {
      HapticFeedback.lightImpact();
      return;
    }
    if (_selectedRole != null && roleHere != _selectedRole) {
      HapticFeedback.lightImpact();
      return;
    }
    setState(() {
      _selectedRole = roleHere;
      _fromSquare = square;
      _toSquare = null;
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _fromSquare != null && _toSquare != null;

    return Container(
      

    )
  }