//chunk 1: imports and design tokens

import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:dartchess/dartchess.dart' as chess;
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
  final int? fromFile;
  final int? fromRank;
  final int? to;
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

int? _parseSq(String s) {
  if (s.length != 2) return null;
  final f = s.codeUnitAt(0) - 97;
  final r = int.tryParse(s[1]);
  if (r == null) return null;
  final rankIndex = r - 1;
  if (f < 0 || f > 7 || rankIndex < 0 || rankIndex > 7) return null;
  return rankIndex * 8 + f;
}

String _sqName(int sq) {
  final f = String.fromCharCode(97 + (sq % 8));
  final r = (sq ~/ 8) + 1;
  return '$f$r';
}

//chunk 4: Move parser vocabulary maps((files, ranks, pieces, captures, SAN letters))
//MOVE PARSER (this was ai generated coz i aint gonna write allat manually)
//new update: revamped using GPT to be more rebust, after stress testing the app transcription more, still wanna keep it on-device, rather than using whispr, thus the extensive regex

class MoveParser {
  static const Map<String, String> _fileWords = {
    'a': 'a',
    'ay': 'a',
    'aye': 'a',
    'eh': 'a',
    'hey': 'a',
    'ah': 'a',
    'b': 'b',
    'be': 'b',
    'bee': 'b',
    'bea': 'b',
    'bi': 'b',
    'c': 'c',
    'see': 'c',
    'sea': 'c',
    'cee': 'c',
    'si': 'c',
    'sey': 'c',
    'd': 'd',
    'dee': 'd',
    'de': 'd',
    'di': 'd',
    'the': 'd',
    'e': 'e',
    'ee': 'e',
    'eee': 'e',
    'he': 'e',
    'f': 'f',
    'ef': 'f',
    'eff': 'f',
    'if': 'f',
    'of': 'f',
    'eph': 'f',
    'g': 'g',
    'gee': 'g',
    'jee': 'g',
    'ge': 'g',
    'ji': 'g',
    'h': 'h',
    'aitch': 'h',
    'aich': 'h',
    'ache': 'h',
    'each': 'h',
    'age': 'h',
    'aitchh': 'h',
  };

  static const Map<String, String> _rankWords = {
    'one': '1',
    'won': '1',
    'wun': '1',
    'wan': '1',
    'wone': '1',
    'own': '1',
    'on': '1',
    '1': '1',
    'two': '2',
    'too': '2',
    'to': '2',
    'tu': '2',
    'twu': '2',
    'tou': '2',
    'doo': '2',
    '2': '2',
    'three': '3',
    'tree': '3',
    'thee': '3',
    'free': '3',
    'thre': '3',
    'thri': '3',
    'tri': '3',
    'tre': '3',
    'threee': '3',
    '3': '3',
    'four': '4',
    'for': '4',
    'fore': '4',
    'faux': '4',
    'fo': '4',
    'faw': '4',
    'fawr': '4',
    'fourr': '4',
    '4': '4',
    'five': '5',
    'fife': '5',
    'fyve': '5',
    'faiv': '5',
    'fiv': '5',
    'fivee': '5',
    '5': '5',
    'six': '6',
    'siks': '6',
    'sicks': '6',
    'sik': '6',
    'sixx': '6',
    'sex': '6',
    '6': '6',
    'seven': '7',
    'sevin': '7',
    'sevan': '7',
    'sevn': '7',
    'sevene': '7',
    'sevenn': '7',
    'heaven': '7',
    'heven': '7',
    '7': '7',
    'eight': '8',
    'ate': '8',
    'ait': '8',
    'aight': '8',
    'eit': '8',
    'eigt': '8',
    'eighth': '8',
    'hate': '8',
    '8': '8',
  };

  static const Map<String, chess.Role> _pieceWords = {
    'b': chess.Role.bishop,
    'knight': chess.Role.knight,
    'knights': chess.Role.knight,
    'night': chess.Role.knight,
    'nights': chess.Role.knight,
    'nite': chess.Role.knight,
    'nites': chess.Role.knight,
    'knite': chess.Role.knight,
    'knites': chess.Role.knight,
    'knightt': chess.Role.knight,
    'nigt': chess.Role.knight,
    'k night': chess.Role.knight,
    'kay night': chess.Role.knight,
    'n': chess.Role.knight,
    'bishop': chess.Role.bishop,
    'bishops': chess.Role.bishop,
    'bishup': chess.Role.bishop,
    'biship': chess.Role.bishop,
    'bishap': chess.Role.bishop,
    'bishob': chess.Role.bishop,
    'bisho': chess.Role.bishop,
    'bish': chess.Role.bishop,
    'bishopp': chess.Role.bishop,
    'bishopps': chess.Role.bishop,
    'bishep': chess.Role.bishop,
    'bisshop': chess.Role.bishop,
    'rook': chess.Role.rook,
    'rooks': chess.Role.rook,
    'rock': chess.Role.rook,
    'rocks': chess.Role.rook,
    'ruck': chess.Role.rook,
    'ruk': chess.Role.rook,
    'brook': chess.Role.rook,
    'brooks': chess.Role.rook,
    'root': chess.Role.rook,
    'roots': chess.Role.rook,
    'rooc': chess.Role.rook,
    'ruke': chess.Role.rook,
    'r': chess.Role.rook,
    'are': chess.Role.rook,
    'queen': chess.Role.queen,
    'queens': chess.Role.queen,
    'quinn': chess.Role.queen,
    'quin': chess.Role.queen,
    'qeen': chess.Role.queen,
    'kween': chess.Role.queen,
    'quean': chess.Role.queen,
    'queene': chess.Role.queen,
    'queue': chess.Role.queen,
    'cue': chess.Role.queen,
    'q': chess.Role.queen,
    'king': chess.Role.king,
    'kings': chess.Role.king,
    'kin': chess.Role.king,
    'keng': chess.Role.king,
    'keeng': chess.Role.king,
    'kingg': chess.Role.king,
    'k': chess.Role.king,
    'kay': chess.Role.king,
    'okay': chess.Role.king,
    'ok': chess.Role.king,
    'pawn': chess.Role.pawn,
    'pawns': chess.Role.pawn,
    'pown': chess.Role.pawn,
    'pon': chess.Role.pawn,
    'pwan': chess.Role.pawn,
    'paan': chess.Role.pawn,
    'pan': chess.Role.pawn,
    'palm': chess.Role.pawn,
    'porn': chess.Role.pawn,
    'p': chess.Role.pawn,
    'pee': chess.Role.pawn,
  };

  static const Set<String> _captureWords = {
    'takes',
    'take',
    'taking',
    'taken',
    'captures',
    'capture',
    'capturing',
    'captured',
    'x',
    'ex',
    'eks',
    'times',
    'gets',
    'get',
    'kills',
    'kill',
    'killing',
  };

  static const Map<String, chess.Role> _sanLetters = {
    'n': chess.Role.knight,
    'b': chess.Role.bishop,
    'r': chess.Role.rook,
    'q': chess.Role.queen,
    'k': chess.Role.king,
  };

  static const Set<String> _castleShortWords = {
    'castle',
    'castles',
    'castling',
    'casling',
    'castel',
    'castel e',
    'short castle',
    'short castling',
    'king side castle',
    'king side castling',
    'kingside castle',
    'kingside castling',
    'o o',
    'oh oh',
    'oh-oh',
    'zero zero',
    'zero-zero',
    '0 0',
    '0-0',
    '00',
  };

  static const Set<String> _castleLongWords = {
    'castle queen side',
    'castle queenside',
    'castling queen side',
    'castling queenside',
    'queen side castle',
    'queenside castle',
    'long castle',
    'long castling',
    'big castle',
    'big castling',
    'o o o',
    'oh oh oh',
    'oh-oh-oh',
    'zero zero zero',
    'zero-zero-zero',
    '0 0 0',
    '0-0-0',
    '000',
  };

  static const Set<String> _checkWords = {
    'check',
    'checks',
    'checked',
    'checking',
  };

  static const Set<String> _checkmateWords = {
    'checkmate',
    'check mate',
    'check-mate',
    'mate',
    'mated',
  };

  static const Set<String> _ignoredWords = {
    'and',
    'then',
    'move',
    'moves',
    'moving',
    'play',
    'plays',
    'playing',
    'make',
    'makes',
    'makeing',
    'please',
    'now',
    'the',
    'on',
    'at',
    'onto',
    'square',
    'squared',
    'piece',
    'man',
    'manoeuvre',
    'maneuver',
  };

  static const Set<String> _spokenFileEAliases = {
    'eat',
    'eet',
    'eatt',
    'e eight',
  };

  static final RegExp _squareRe = RegExp(r'^([a-h])([1-8])$');
  static final RegExp _sanRe = RegExp(
    r'^([nbrqk]?)([a-h]?)([1-8]?)(x?)([a-h])([1-8])(?:=([qrbn]))?([+#]?)$',
  );
  static final RegExp _castleShortRe = RegExp(
    r'^(?:o\s*[- ]?o|oh\s*[- ]?oh|zero\s*[- ]?zero|0\s*[- ]?0)$',
  );
  static final RegExp _castleLongRe = RegExp(
    r'^(?:o\s*[- ]?o\s*[- ]?o|oh\s*[- ]?oh\s*[- ]?oh|zero\s*[- ]?zero\s*[- ]?zero|0\s*[- ]?0\s*[- ]?0)$',
  );
  static final RegExp _promotionRe = RegExp(r'^=?([qrbn])$');

  //chunk 5: move parser (.parse()) --- castling detection logic

  static SpokenMove? parse(String raw) {
    if (raw.trim().isEmpty) return null;

    final text = raw
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(RegExp(r'[^a-z0-9+#=\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) return null;

    final collapsed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final compactCastle = collapsed.replaceAll(' - ', '-');

    if (_castleLongWords.contains(collapsed) ||
        _castleLongRe.hasMatch(compactCastle)) {
      return const SpokenMove(queensideCastle: true);
    }
    if (_castleShortWords.contains(collapsed) ||
        _castleShortRe.hasMatch(compactCastle)) {
      if (collapsed == 'castle' ||
          collapsed == 'castles' ||
          collapsed == 'castling' ||
          collapsed == 'casling' ||
          collapsed == 'castel') {
        return const SpokenMove(kingsideCastle: true, queensideCastle: true);
      }
      return const SpokenMove(kingsideCastle: true);
    }

    final hasCastleWord = collapsed.contains('castle') ||
        collapsed.contains('castling') ||
        collapsed.contains('casling') ||
        collapsed.contains('castel');
    final hasShortWord = collapsed.contains('short') ||
        collapsed.contains('king side') ||
        collapsed.contains('kingside');
    final hasLongWord = collapsed.contains('long') ||
        collapsed.contains('big') ||
        collapsed.contains('queen side') ||
        collapsed.contains('queenside');

    if (hasCastleWord ||
        (hasShortWord && collapsed.contains('castle')) ||
        (hasLongWord && collapsed.contains('castle'))) {
      if (hasLongWord && !hasShortWord) {
        return const SpokenMove(queensideCastle: true);
      }
      if (hasShortWord && !hasLongWord) {
        return const SpokenMove(kingsideCastle: true);
      }
      return const SpokenMove(kingsideCastle: true, queensideCastle: true);
    }

    final rawTokens = collapsed
        .replaceAll('-', ' ')
        .split(' ')
        .where((e) => e.isNotEmpty)
        .toList();

    if (rawTokens.isEmpty) return null;

    final tokens = <String>[];
    for (final token in rawTokens) {
      if (token == 'and') {
        continue;
      }
      tokens.add(token);
    }

    if (tokens.length == 2 &&
        _spokenFileEAliases.contains(tokens[0]) &&
        _rankWords.containsKey(tokens[1])) {
      final square = 'e${_rankWords[tokens[1]]!}';
      return SpokenMove(to: _parseSq(square));
    }

    if (tokens.length == 3 &&
        _spokenFileEAliases.contains(tokens[1]) &&
        _rankWords.containsKey(tokens[2])) {
      final prefixPiece = _pieceWords[tokens[0]];
      if (prefixPiece != null) {
        final square = 'e${_rankWords[tokens[2]]!}';
        return SpokenMove(role: prefixPiece, to: _parseSq(square));
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
    bool isCapture = collapsed.contains('en passant') ||
        collapsed.contains('onpassant') ||
        collapsed.contains('enpassant');
    final cleanedText = collapsed
        .replaceAll('en passant', ' ')
        .replaceAll('onpassant', ' ')
        .replaceAll('enpassant', ' ');

    final cleanedTokens = cleanedText
        .replaceAll('-', ' ')
        .split(' ')
        .where((e) => e.isNotEmpty)
        .toList();

    final coordinatePairs = <String>[];
    for (int i = 0; i < cleanedTokens.length; i++) {
      final token = cleanedTokens[i];
      if (_squareRe.hasMatch(token)) {
        coordinatePairs.add(token);
        continue;
      }
      final file = _fileWords[token];
      if (file != null && i + 1 < cleanedTokens.length) {
        final rank = _rankValueForContext(cleanedTokens[i + 1], true);
        if (rank != null) {
          coordinatePairs.add('$file$rank');
          i++;
          continue;
        }
      }
    }

    for (int i = 0; i < cleanedTokens.length; i++) {
      final token = cleanedTokens[i];
      if (token.isEmpty) continue;

      if (_ignoredWords.contains(token)) continue;

      if (_captureWords.contains(token)) {
        isCapture = true;
        continue;
      }

      if (_checkmateWords.contains(token)) {
        continue;
      }

      if (_checkWords.contains(token)) {
        continue;
      }

      if (token == '#') {
        continue;
      }

      if (token == '+') {
        continue;
      }

      final promotionMatch = _promotionRe.firstMatch(token);
      if (promotionMatch != null) {
        final role = _sanLetters[promotionMatch.group(1)!];
        if (role != null) {
          symbols.add(_Sym.piece(role));
          continue;
        }
      }

      final san = _sanRe.firstMatch(token);
      if (san != null && token.length >= 2) {
        final roleText = san.group(1)!;
        final disambFile = san.group(2)!;
        final disambRank = san.group(3)!;
        final captureText = san.group(4)!;
        final destFile = san.group(5)!;
        final destRank = san.group(6)!;
        final promotionText = san.group(7);

        if (roleText.isNotEmpty) {
          symbols.add(_Sym.piece(_sanLetters[roleText]!));
        }
        if (disambFile.isNotEmpty) {
          symbols.add(_Sym.file(disambFile));
        }
        if (disambRank.isNotEmpty) {
          symbols.add(_Sym.rank(disambRank));
        }
        if (captureText.isNotEmpty) {
          isCapture = true;
        }
        symbols.add(_Sym.square('$destFile$destRank'));
        if (promotionText != null && promotionText.isNotEmpty) {
          symbols.add(_Sym.piece(_sanLetters[promotionText]!));
        }
        continue;
      }

      final coordinate = _squareRe.firstMatch(token);
      if (coordinate != null) {
        symbols.add(_Sym.square(token));
        continue;
      }

      if (token == 'b') {
        final next = i + 1 < cleanedTokens.length ? cleanedTokens[i + 1] : null;
        final nextIsSquare = next != null && _squareRe.hasMatch(next);
        final nextIsCapture = next != null && _captureWords.contains(next);
        final nextIsCoordinate = i + 2 < cleanedTokens.length &&
            _fileWords[cleanedTokens[i + 1]] != null &&
            _rankWords.containsKey(cleanedTokens[i + 2]);
        if (nextIsSquare || nextIsCapture || nextIsCoordinate) {
          symbols.add(_Sym.piece(chess.Role.bishop));
        } else {
          symbols.add(_Sym.file('b'));
        }
        continue;
      }

      if (_spokenFileEAliases.contains(token)) {
        if (i + 1 < cleanedTokens.length &&
            _rankWords.containsKey(cleanedTokens[i + 1])) {
          symbols.add(_Sym.file('e'));
          symbols.add(_Sym.rank(_rankWords[cleanedTokens[i + 1]]!));
          i++;
        } else {
          isCapture = true;
        }
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

      final rank = _rankValueForContextFromTokens(cleanedTokens, i);
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

    if (destIndex == -1 && coordinatePairs.isNotEmpty) {
      final square = coordinatePairs.last;
      final to = _parseSq(square);
      if (to == null) return null;
      return SpokenMove(to: to, isCapture: isCapture);
    }

    if (destIndex == -1) return null;

    final to = _parseSq(merged[destIndex].text);
    if (to == null) return null;

    chess.Role? role;
    chess.Role? promotion;
    int? fromFile;
    int? fromRank;

    for (int i = 0; i < merged.length; i++) {
      final s = merged[i];
      if (i < destIndex) {
        switch (s.kind) {
          case _SymKind.piece:
            role ??= s.role;
          case _SymKind.square:
            final origin = _parseSq(s.text);
            if (origin != null && origin != to) {
              fromFile = origin % 8;
              fromRank = origin ~/ 8;
            }
          case _SymKind.file:
            fromFile ??= s.text.codeUnitAt(0) - 97;
          case _SymKind.rank:
            fromRank ??= int.parse(s.text) - 1;
        }
      } else if (i > destIndex && s.kind == _SymKind.piece) {
        promotion ??= s.role;
      }
    }

    if (promotion == chess.Role.king || promotion == chess.Role.pawn) {
      promotion = null;
    }

    if (role == null && fromFile != null && fromRank != null) {
      final origin = fromRank * 8 + fromFile;
      if (origin == to) {
        fromFile = null;
        fromRank = null;
      }
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

  static int? _rankValueForContext(String token, bool afterFile) {
    if (!_rankWords.containsKey(token)) return null;
    if (token == 'to' || token == 'too') {
      return afterFile ? 2 : null;
    }
    if (token == 'for' || token == 'fore') {
      return afterFile ? 4 : null;
    }
    return int.tryParse(_rankWords[token]!);
  }

  static String? _rankValueForContextFromTokens(
    List<String> tokens,
    int index,
  ) {
    final token = tokens[index];
    if (!_rankWords.containsKey(token)) return null;

    final previous = index > 0 ? tokens[index - 1] : null;

    if ((token == 'to' ||
            token == 'too' ||
            token == 'for' ||
            token == 'fore') &&
        (previous == null || _fileWords[previous] == null)) {
      return null;
    }

    if (previous != null && _fileWords[previous] != null) {
      return _rankWords[token];
    }

    if (token == 'one' ||
        token == 'won' ||
        token == 'wun' ||
        token == '1' ||
        token == 'two' ||
        token == 'three' ||
        token == 'tree' ||
        token == 'thee' ||
        token == 'free' ||
        token == '3' ||
        token == 'five' ||
        token == 'fife' ||
        token == '5' ||
        token == 'six' ||
        token == 'sicks' ||
        token == 'sex' ||
        token == '6' ||
        token == 'seven' ||
        token == 'sevin' ||
        token == '7' ||
        token == 'eight' ||
        token == 'ate' ||
        token == 'ait' ||
        token == '8' ||
        token == 'four' ||
        token == 'faux' ||
        token == '4') {
      return _rankWords[token];
    }

    return null;
  }
}

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

//will add more later

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
  bool _showGameOverBanner = false;
  Timer? _gameOverBannerTimer;

  bool _manualPause = false;
  bool _clockStarted =
      false; //NEW FIXXY: now both clocks stay frozen until a panel is tapped
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

  //NEW FIXXY: track time spent manually paused so PGN move-times don't inflate/beinaccurate, like they did before
  DateTime? _pauseStartedAt;
  Duration _pausedDuringMove = Duration.zero;

  //gonna change this later because i dont want the player always having to press confirmation for each move, ill just add a undo button to the sucessmove dialogue after transciption
  // ADDED: Stubs for the variables you are using in the build method below
  String? _lastPlayedSan;
  bool? _lastPlayedByWhite;

  List<String> _positionHistory = [];
  List<_Candidate> _pendingCandidates = [];
  bool get _awaitingConfirmation => _pendingCandidates.isNotEmpty;

  // NEW FIXXY: the undo feature mentioned in the journal
  void _undoLastMove() {
    if (_moveHistory.isEmpty || gameOver) return;

    final last = _moveHistory.removeLast();
    _positionHistory.removeLast();

    chess.Position replay =
        chess.Chess.initial; //FIX: explicit Position type, not var
    for (final record in _moveHistory) {
      final legalMovesMap = replay.legalMoves;
      chess.NormalMove? found;
      for (final entry in legalMovesMap.entries) {
        for (final to in entry.value.squares) {
          for (final promo in <chess.Role?>[
            null,
            chess.Role.queen,
            chess.Role.rook,
            chess.Role.bishop,
            chess.Role.knight,
          ]) {
            final candidate = chess.NormalMove(
              from: entry.key,
              to: to,
              promotion: promo,
            );
            if (!replay.isLegal(candidate)) continue;
            final (_, san) = replay.makeSanUnchecked(candidate);
            if (san == record.san) {
              found = candidate;
              break;
            }
          }
          if (found != null) break;
        }
        if (found != null) break;
      }
      if (found != null) replay = replay.play(found);
    }

    setState(() {
      _position = replay;
      if (last.byWhite) {
        whiteTime -= Duration(seconds: currentControl.incrementSeconds);
        if (whiteTime.isNegative) whiteTime = Duration.zero;
        whiteMoves = whiteMoves > 0 ? whiteMoves - 1 : 0;
      } else {
        blackTime -= Duration(seconds: currentControl.incrementSeconds);
        if (blackTime.isNegative) blackTime = Duration.zero;
        blackMoves = blackMoves > 0 ? blackMoves - 1 : 0;
      }
      whiteToMove = last.byWhite;
      _lastPlayedSan = _moveHistory.isNotEmpty ? _moveHistory.last.san : null;
      _lastPlayedByWhite =
          _moveHistory.isNotEmpty ? _moveHistory.last.byWhite : null;
      _moveStartTime = DateTime.now();
      _pausedDuringMove = Duration.zero;
      gameOver = false;
      winner = null;
      _endReason = null;
    });
    _feedback();
  }

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
    _gameOverBannerTimer?.cancel(); //new fixxy
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
          _hardTimeoutTimer?.cancel(); //NEW FIXXY
          setState(() {
            _isListening = false; //new fixxy: removed the ispaused = false
            _lastMoveError =
                null; //NEW FIXXY- route into recovery instead of that red text error shit
            _recoveryMessage = "Move not detected"; //NEW FIXXY
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
    _armGameOverBanner(); //new fixxy
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (gameOver || isPaused || _manualPause || !_clockStarted) {
        return; //NEW FIXXY: nothing ticks pre start
      }

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
        final promotes = isPawn && ((to ~/ 8) == 0 || (to ~/ 8) == 7);

        final promoRoles = promotes
            ? <chess.Role?>[spoken.promotion ?? chess.Role.queen]
            : <chess.Role?>[null];

        for (final promo in promoRoles) {
          final move = chess.NormalMove(from: from, to: to, promotion: promo);
          final (_, san) = _position.makeSanUnchecked(move);

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
          if (spoken.fromFile != null && (from % 8) != spoken.fromFile) {
            continue;
          }
          if (spoken.fromRank != null && (from ~/ 8) != spoken.fromRank) {
            continue;
          }

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
                _endReason = "Agreement";
              });
              _feedback(heavy: true);
              _armGameOverBanner(); //new fixxy
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
    _armGameOverBanner(); //new fixxy
  }

  void _proposeFromSquares(String fromName, String toName) {
    final from = _parseSq(fromName);
    final to = _parseSq(toName);
    if (from == null || to == null) {
      setState(() {
        _lastMoveError = "Invalid square";
        isPaused = false;
      });
      if (_pauseStartedAt != null) {
        //NEW FIXXY
        _pausedDuringMove += DateTime.now().difference(_pauseStartedAt!);
        _pauseStartedAt = null;
      }
      return;
    }

    final chessSquareFrom = chess.Square.parse(_sqName(from));
    final chessSquareTo = chess.Square.parse(_sqName(to));
    if (chessSquareFrom == null || chessSquareTo == null) return;

    final piece = _position.board.pieceAt(chessSquareFrom);
    final promotes =
        piece?.role == chess.Role.pawn && ((to ~/ 8) == 0 || (to ~/ 8) == 7);

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
      final move = chess.NormalMove(
        from: chessSquareFrom,
        to: chessSquareTo,
        promotion: promo,
      );
      if (!_position.isLegal(move)) continue;
      final (_, san) = _position.makeSanUnchecked(move);
      candidates.add(_Candidate(move, san));
    }

    if (candidates.isEmpty) {
      setState(() {
        _lastMoveError = "Illegal: ${_sqName(from)}${_sqName(to)}";
        isPaused = false;
      });
      if (_pauseStartedAt != null) {
        //NEW FIXXY
        _pausedDuringMove += DateTime.now().difference(_pauseStartedAt!);
        _pauseStartedAt = null;
      }
      return;
    }

    setState(() {
      _pendingCandidates = candidates;
      _lastMoveError = null;
    });
  }

  //chunk 15: _confirmMove, _evaluateGameEnd, _cancelPendingMove

  void _confirmMove(_Candidate chosen) {
    // FIX (vuln #1 and #2): guards against a double-tap on the same
    // candidate button re-playing an already-played move (which
    // dartchess.play() throws on, since the move is no longer legal
    // in the resulting position), and against a Confirm tap that was already in flight landing after Cancel already cleared state
    // Once `chosen` is no longer present in `_pendingCandidates` which happens the instant the first confirm (or a cancel) runs any further call for the same tap is a no-op.

    if (!_pendingCandidates.contains(chosen)) return;

    if (_pauseStartedAt != null) {
      //new fixxy
      _pausedDuringMove += DateTime.now().difference(_pauseStartedAt!);
      _pauseStartedAt = null;
    }

    final now = DateTime.now();
    final timeTaken = now.difference(_moveStartTime) - _pausedDuringMove;
    //NEW FIXXY: subtracted pause time now, idk how it didnt click to me before, stupid
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
      _pausedDuringMove =
          Duration.zero; //NEW FIXXY: now resets fgor the next move
      _pendingCandidates = [];
      isPaused = false;
      _recognizedText = '';
      _lastMoveError = null;
      _recoveryMessage = null;
      _positionHistory.add(_positionKey(_position));
      _lastPlayedSan =
          chosen.san; //NEW FIXXY: adds the move transcribed and undo island
      _lastPlayedByWhite = movedByWhite; //NEW FIXXY
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
    _armGameOverBanner(); //new fixxy
  }

  //NEW FIXXY: fades the winner's banner after 3s
  void _armGameOverBanner() {
    _gameOverBannerTimer?.cancel();
    setState(() => _showGameOverBanner = true);
    _gameOverBannerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showGameOverBanner = false);
    });
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

  //chunk 16: _onHoldDown/_onHoldStart/_onHoldEnd/_processUtterance -press-and-hold voice flow AND NOW ALSO _onPanelTap:

  void _onPanelTap(bool isWhitePanel) {
    if (_clockStarted || gameOver || _awaitingConfirmation) return;
    setState(() {
      _clockStarted = true;
      whiteToMove = !isWhitePanel;
    });
    _feedback();
  }

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
    if (_manualPause) {
      _showPausedNotice();
      return;
    }

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
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 4),
        localeId: 'en_US',
      ),
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
      final dests = entry.value.squares.map((s) => _sqName(s)).toSet();
      if (dests.isEmpty) continue;
      moves[_sqName(from)] = dests;
      roles[_sqName(from)] = piece.role;
    }
    return (legalMoves: moves, pieceRoles: roles);
  }

  void _showManualMoveDialog() {
    if (gameOver) return;
    if (_manualPause) {
      _showPausedNotice();
      return;
    }
    setState(() {
      isPaused = true;
      _recoveryMessage = null;
    });
    _pauseStartedAt ??= DateTime
        .now(); //NEW FIXXY:tracking time spent in the manual picker so it doesn't inflate the move's recorded time pgn

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
            if (_pauseStartedAt != null) {
              //NEW FIXXY: close pause window on cancel
              _pausedDuringMove += DateTime.now().difference(_pauseStartedAt!);
              _pauseStartedAt = null;
            }
          },
        );
      },
    );
  }

  //chunk 18: _resetGame, _confirmReset, _togglePause, _toggleSound

  void _resetGame() {
    _gameOverBannerTimer
        ?.cancel(); //NEW FIXXY: deletes prev. possible 3s banners
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
      _pauseStartedAt = null; //NEW FIXXY
      _pausedDuringMove = Duration.zero; //NEW FIXXY
      _lastPlayedSan = null; //NEW FIXXY
      _lastPlayedByWhite = null; //NEW FIXXY
      _clockStarted = false; //NEW FIXXY: idle state
      _showGameOverBanner = false; //NEW FIXXY
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
    //NEW FIXXY: track paused duration so PGN move time doesnt inflate
    if (_manualPause) {
      _pauseStartedAt = DateTime.now();
    } else if (_pauseStartedAt != null) {
      _pausedDuringMove += DateTime.now().difference(_pauseStartedAt!);
      _pauseStartedAt = null;
    }
  }

  void _showPausedNotice() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kSheetBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Clock is paused",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Resume to continue",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("OK", style: TextStyle(color: kPanelActive)),
          ),
        ],
      ),
    );
  }

  void _toggleSound() {
    setState(() {
      _soundState =
          _soundState == SoundState.on ? SoundState.muted : SoundState.on;
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
                            fontWeight: FontWeight.w700,
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
    final barExpanded = _manualPause || gameOver || !_clockStarted; //NEW FIXXY

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
                        isActive: !whiteToMove && _clockStarted, //new fixxy
                        isPausedGlobally: _manualPause,
                        showTune: barExpanded,
                        isListening: _isListening && !whiteToMove,
                        recognizedText: whiteToMove ? '' : _recognizedText,
                        errorText: whiteToMove ? null : _lastMoveError,
                        onHoldDown: () => _onHoldDown(false),
                        onHoldStart: () => _onHoldStart(false),
                        onHoldEnd: () => _onHoldEnd(false),
                        onTuneTap: !_manualPause
                            ? null
                            : () => _showTimeEditDialog(
                                  false,
                                ), //NEW FIXXY: only opens while paused
                        onManualOverride: _showManualMoveDialog,
                        onTimeTap: () => _showTimeEditDialog(false),
                        onPanelTap: () => _onPanelTap(false), //NEW FIXXY
                        // Island only shows on the side that actually
                        // moved — the other panel's copy stays null.
                        lastPlayedSan:
                            _lastPlayedByWhite == false ? _lastPlayedSan : null,
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
                      isActive: whiteToMove && _clockStarted, //new fixxy
                      isPausedGlobally: _manualPause,
                      showTune: barExpanded,
                      isListening: _isListening && whiteToMove,
                      recognizedText: whiteToMove ? _recognizedText : '',
                      errorText: whiteToMove ? _lastMoveError : null,
                      onHoldDown: () => _onHoldDown(true),
                      onHoldStart: () => _onHoldStart(true),
                      onHoldEnd: () => _onHoldEnd(true),
                      onTuneTap: !_manualPause
                          ? null
                          : () => _showTimeEditDialog(
                                true,
                              ), //NEW FIXXY: white panel edits white's time, only while paused
                      onManualOverride: _showManualMoveDialog,
                      onTimeTap: () => _showTimeEditDialog(true),
                      onPanelTap: () => _onPanelTap(true), //NEW FIXXY
                      lastPlayedSan:
                          _lastPlayedByWhite == true ? _lastPlayedSan : null,
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
                child: AnimatedOpacity(
                  //NEW FIXXY: fades aftr 3s
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  opacity: _showGameOverBanner ? 1.0 : 0.0,
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
//NEW FIXXY: _PgnSheet converted from Stateless to Stateful to get the local "Copied!" feedback below (SnackBar was rendering behind the
//modal bottom sheet's own Overlay entry, so it was invisible when running).
class _PgnSheet extends StatefulWidget {
  final String pgn;
  final List<MoveRecord> moves;
  final String Function(Duration) formatTaken;

  const _PgnSheet({
    required this.pgn,
    required this.moves,
    required this.formatTaken,
  });

  @override
  State<_PgnSheet> createState() => _PgnSheetState();
}

class _PgnSheetState extends State<_PgnSheet> {
  bool _copied = false; //NEW FIXXY

  void _handleCopy() {
    //NEW FIXXY
    Clipboard.setData(ClipboardData(text: widget.pgn));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pairs = <(MoveRecord?, MoveRecord?)>[];
    for (int i = 0; i < widget.moves.length; i += 2) {
      pairs.add((
        widget.moves[i],
        i + 1 < widget.moves.length ? widget.moves[i + 1] : null,
      ));
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
                  TextButton.icon(
                    onPressed: () async {
                      await SharePlus.instance.share(
                        ShareParams(text: widget.pgn, subject: 'VCCN Game'),
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
                    //NEW FIXXY: local state feedback instead of SnackBar
                    onPressed: _handleCopy,
                    icon: Icon(
                      _copied ? Icons.check : Icons.copy,
                      size: 18,
                      color: kPanelActive,
                    ),
                    label: Text(
                      _copied ? "Copied!" : "Copy",
                      style: const TextStyle(
                        color: kPanelActive,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  SizedBox(width: 34, child: Text("#", style: _headStyle)),
                  Expanded(child: Text("WHITE", style: _headStyle)),
                  Expanded(child: Text("BLACK", style: _headStyle)),
                ],
              ),
              const Divider(color: Colors.white24, height: 14),
              Expanded(
                child: widget.moves.isEmpty
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
                                  widget.pgn,
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
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _MoveCell(
                                    record: white,
                                    formatTaken: widget.formatTaken,
                                  ),
                                ),
                                Expanded(
                                  child: _MoveCell(
                                    record: black,
                                    formatTaken: widget.formatTaken,
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
            fontWeight: FontWeight.w700,
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

  const _ControlBar({
    required this.expanded,
    required this.icons,
    required this.manualPause,
    required this.soundState,
    required this.moveCount,
  });

  static const double _slot = 60;
  static const double _baseSize = 32;
  static const double _pauseBaseSize = 36;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kBarHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const double top = (kBarHeight - _slot) / 2;

          final laidOut =
              expanded ? icons : icons.where((i) => !i.collapsible).toList();

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
              final double targetSize = expanded ? base : base * 1.22;

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
                            constraints: const BoxConstraints.tightFor(
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
    final barWidth = size * 0.17;
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

class _HollowPlayIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _HollowPlayIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PlayOutlinePainter(color: color)),
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
// New flow, per spec:
//  - Squares no longer show algebraic text (a1, e4, ...) — only the
//    file letters below and rank numbers to the right of the board, like as a real board.
//  - a row of piece icons (for whichever roles the side to move
//    actually has available) sits above the board. Tapping one highlights every square holding that piece/s or piece type whatever.
//  - Tapping one of the highlighted squares selects it as "from":
//    the square turns green and dots appear on its legal
//    destinations. Every other piece's icon disappears and only the
//    selected piece stays on the board while you choose where it
//    goes.
//  - Tapping a legal destination turns it orange and arms
//    "Play move". Direct square taps (skipping the icon row) still work(hopefully) as a shortcut.
//  - cancel / Play move buttons stay at the bottom regardless — the
//    clock is paused for the whole time this sheet is open, and
//    nothing plays until Play move is tapped.

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
      return '♗';
    case chess.Role.rook:
      return '♖';
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

  Set<String> get _legalDestinations => _fromSquare == null
      ? const {}
      : (widget.legalMoves[_fromSquare] ?? const {});

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
      if (roleHere != null &&
          (_selectedRole == null || roleHere == _selectedRole)) {
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: kSheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(kPanelRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            !_hasAnyLegalMove
                ? "No legal moves available"
                : (_fromSquare == null
                    ? "${widget.whiteToMove ? 'White' : 'Black'} to move - pick a piece"
                    : (_toSquare == null
                        ? "Tap a highlighted square to move there"
                        : "$_fromSquare to $_toSquare")),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_availableRoles.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _availableRoles.map((role) {
                final selected = _selectedRole == role;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _tapRole(role),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 58, //NEW FIXXY: was 42 before
                      height: 58, //NEW FIXXY: was 42 before
                      decoration: BoxDecoration(
                        color:
                            selected ? kPanelActive : const Color(0xFF3A3A38),
                        borderRadius: BorderRadius.circular(
                          14,
                        ), // was 12 before
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _roleGlyph(role),
                        style: TextStyle(
                          fontSize: 32,
                          color: selected ? kOnActive : kBarIcon,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final boardSize = min(
                constraints.maxWidth - 22,
                380.0,
              ); //increased size, old was 300
              final cell = boardSize / 8;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: boardSize,
                          height: boardSize,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 8,
                            ),
                            itemCount: 64,
                            itemBuilder: (context, index) {
                              final file = String.fromCharCode(
                                97 + (index % 8),
                              );
                              final rank = 8 - (index ~/ 8);
                              final square = '$file$rank';
                              final roleHere = widget.pieceRoles[square];

                              final isFrom = square == _fromSquare;
                              final isTo = square == _toSquare;
                              final isLegalDest = _fromSquare != null &&
                                  _legalDestinations.contains(square);
                              final isRoleHighlight = _fromSquare == null &&
                                  _selectedRole != null &&
                                  roleHere == _selectedRole;
                              final light = (index + index ~/ 8) % 2 == 0;

                              final Color bg = isFrom
                                  ? kPanelActive
                                  : isTo
                                      ? kTarget
                                      : isRoleHighlight
                                          ? kPanelActive.withValues(alpha: 0.32)
                                          : (light
                                              ? const Color(0xFF4A4A48)
                                              : const Color(0xFF2E2E2C));

                              final semanticLabel = roleHere != null
                                  ? "$square, ${roleHere.name}"
                                      "${isFrom ? ', selected' : ''}"
                                  : (isLegalDest
                                      ? "$square, legal destination"
                                      : square);

                              return GestureDetector(
                                onTap: () => _tapSquare(square),
                                child: Semantics(
                                  button: true,
                                  label: semanticLabel,
                                  child: Container(
                                    margin: const EdgeInsets.all(1),
                                    color: bg,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (roleHere != null &&
                                            (_fromSquare == null ||
                                                square == _fromSquare))
                                          Text(
                                            _roleGlyph(roleHere),
                                            style: TextStyle(
                                              fontSize: cell * 0.62,
                                              height: 1,
                                              color: widget.whiteToMove
                                                  ? Colors.white
                                                  : const Color(0xFF1A1A18),
                                              shadows: widget.whiteToMove
                                                  ? const [
                                                      Shadow(
                                                        color: Colors.black45,
                                                        blurRadius: 2,
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                          ),
                                        if (isLegalDest &&
                                            !isTo) //NEW FIXXY: centered dot instead of random ahh, which was stypid
                                          Container(
                                            width: cell * 0.28,
                                            height: cell * 0.28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: kTarget.withValues(
                                                alpha: 0.9,
                                              ),
                                              border: Border.all(
                                                color: const Color(0xFF2E2E2C),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: boardSize,
                        child: Row(
                          children: List.generate(8, (i) {
                            return Expanded(
                              child: Text(
                                String.fromCharCode(97 + i),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: boardSize,
                    child: Column(
                      children: List.generate(8, (i) {
                        return Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              (8 - i).toString(),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: widget.onCancel,
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPanelActive,
                    foregroundColor: kOnActive,
                    disabledBackgroundColor: const Color(0xFF3A3A38),
                    disabledForegroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: ready
                      ? () => widget.onSubmit(_fromSquare!, _toSquare!)
                      : null,
                  child: const Text(
                    "Play move",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//Clock Panel

class _ClockPanel extends StatefulWidget {
  final String time;
  final int moves;
  final String timeControl;
  final bool isActive;
  final bool isPausedGlobally;
  final bool showTune;
  final bool isListening;
  final String recognizedText;
  final String? errorText;
  final VoidCallback onHoldDown;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final VoidCallback? onTuneTap; //new fixxy: nullable
  final VoidCallback onTimeTap;
  final VoidCallback onManualOverride;
  final String? lastPlayedSan;
  final VoidCallback onUndo;
  final VoidCallback onPanelTap; //NEW FIXXY

  const _ClockPanel({
    required this.time,
    required this.moves,
    required this.timeControl,
    required this.isActive,
    required this.isPausedGlobally,
    required this.showTune,
    required this.isListening,
    required this.recognizedText,
    required this.errorText,
    required this.onHoldDown,
    required this.onHoldStart,
    required this.onHoldEnd,
    required this.onTuneTap,
    required this.onTimeTap,
    required this.onManualOverride,
    required this.lastPlayedSan,
    required this.onUndo,
    required this.onPanelTap, //NEW FIXXY
  });

  //used claude to remember and paste all this (becuase im not a machine who can remember all ts along with school)

  @override
  State<_ClockPanel> createState() => _ClockPanelState();
}

class _ClockPanelState extends State<_ClockPanel>
    with SingleTickerProviderStateMixin {
  static const Color _glowColor = Color(0xFFFF9F0A);

  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  late final Animation<double> _pulseOuter;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2300,
      ), //NEW FIXXY: maybe this'll make it a bit smoother
    ); //will be changing and iterating on this number to see which one looks best

    _pulse = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine, //NEW FIXXY:symmetric curve now
      reverseCurve: Curves.easeInOutSine,
    );
    _pulseOuter = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
      reverseCurve: Curves.easeInOutSine,
    );

    if (widget.isListening) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _ClockPanel old) {
    super.didUpdateWidget(old);
    if (widget.isListening && !old.isListening) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && old.isListening) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool live = widget.isActive && !widget.isPausedGlobally;
    final Color background = live ? kPanelActive : kPanelIdle;
    final Color foreground = live ? kOnActive : kOnIdle;

    return Semantics(
      button: true,
      label: widget.isListening
          ? "Listening for your move"
          : "${live ? 'Your' : 'Opponent'}'s clocl, ${widget.time} remaining "
              "Press and hold to speak a move",
      child: GestureDetector(
        onTap: widget
            .onPanelTap, //NEW FIXXY (first page interface like chess.com clock, so player start as black or white form either side now)
        onLongPressDown: (_) => widget.onHoldDown(),
        onLongPressStart: (_) => widget.onHoldStart(),
        onLongPressEnd: (_) => widget.onHoldEnd(),
        onLongPressCancel: widget.onHoldEnd,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final t = widget.isListening ? 0.35 + (_pulse.value * 0.65) : 0.0;

            final tOuter =
                widget.isListening ? 0.35 + (_pulseOuter.value * 0.65) : 0.0;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: double.infinity,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(kPanelRadius),
                boxShadow: widget.isListening
                    ? [
                        BoxShadow(
                          color: _glowColor.withValues(alpha: 0.6 + t * 0.4),
                          blurRadius: 0,
                          spreadRadius: 2.5 + t * 1.5,
                        ),
                        BoxShadow(
                          color: _glowColor.withValues(
                            alpha: 0.3 + tOuter * 0.4,
                          ),
                          blurRadius: 0,
                          spreadRadius: 6.0 + tOuter * 3.0,
                        ),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            );
          },
          child: Stack(
            children: [
              Positioned(
                top: 14,
                right: 18,
                child: Text(
                  "MOVES ${widget.moves}",
                  style: TextStyle(
                    fontSize: 12,
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 18,
                child: AnimatedOpacity(
                  duration: const Duration(
                    milliseconds: 400,
                  ), //will adjust later if i dont like it, its kinda fuzzy in my mind rn
                  curve: Curves.easeInOut,
                  opacity: widget.isListening ? 1.0 : 0.0,
                  child: Row(
                    children: [
                      Icon(Icons.mic, size: 15, color: foreground),
                      const SizedBox(width: 4),
                      Text(
                        "LISTENING",
                        style: TextStyle(
                          fontSize: 12,
                          color: foreground,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 44,
                left: 16,
                right: 16,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: widget.lastPlayedSan != null
                      ? GestureDetector(
                          key: ValueKey('island-${widget.lastPlayedSan}'),
                          onTap: widget.onUndo,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Played ${widget.lastPlayedSan}",
                                style: TextStyle(
                                  fontSize: 17,
                                  color: foreground,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Undo",
                                style: TextStyle(
                                  fontSize: 17,
                                  color: foreground,
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.underline,
                                  decorationColor: foreground,
                                ),
                              ), //added underline under undo text for now, maybe ill chnage it to a separate button later (if needed)
                            ],
                          ),
                        )
                      : widget.recognizedText.isNotEmpty
                          ? Text(
                              widget.recognizedText,
                              key: ValueKey(widget.recognizedText),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                color: foreground,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ),
              Positioned(
                top: 76,
                left: 16,
                right: 16,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: widget.errorText != null
                      ? Text(
                          widget.errorText!,
                          key: ValueKey(widget.errorText),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: kDanger,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('error_empty')),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GestureDetector(
                    onTap: widget.isPausedGlobally ? widget.onTimeTap : null,
                    // NEW FIXXY: only editable while paused
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.time,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 100,
                          height: 1,
                          fontFamily: kClockFont,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ), //fuck this syntax
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: AnimatedSlide(
                  duration: kTuneSlide,
                  curve: Curves.easeInOut,
                  offset: widget.showTune ? Offset.zero : const Offset(0, 0.55),
                  child: AnimatedOpacity(
                    duration: kTuneFade,
                    curve: Curves.easeOut,
                    opacity: widget.showTune ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !widget.showTune,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 48,
                              height: 44,
                            ),
                            onPressed: widget.onTuneTap,
                            icon: Icon(Icons.tune, size: 38, color: foreground),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.timeControl,
                            style: TextStyle(
                              fontSize: 20,
                              color: foreground,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//so glad atleast MVP is complete, because dart is fucking annoying sometimes.
//now lets debug and write the final YAML file gng - its done and working
//now time to polish and fix bugs. Will also maybe add a landing page and import lichess engine and analysis pages (ig chunks 25+) (stockfish)
