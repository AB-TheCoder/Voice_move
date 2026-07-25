
'''
this is the main file for the voice controlled chess notation(VCCN)
this feature is a revolutionary way to record chess moves replacing the orthodox written method
main Authors@- Aarav Bhatt and @Vihaan
'''
"""this is another main feature for our application ,and probably more selling than the other one.
 the user will press the clock and then hold it to speak his/her move to register it onthe on app scoresheet.
 open-ai whisper will be used."""
 
"""
pipline for audical_scoresheet:
1. recording the data
2. recognising text
3. post proccessing of text
5. validification of text
6. updatation of text on the online scoresheet
"""
# imports(primary)
from pathlib import Path
from typing import Optional
import re
import numpy
import chess
import chess.pgn
 
try:
    import sounddevice as sd
except ModuleNotFoundError as error:  # pragma: no cover
    sd = None  # type: ignore[assignment]
    _SOUNDDEVICE_IMPORT_ERROR = error
else:
    _SOUNDDEVICE_IMPORT_ERROR = None
 
try:
    from scipy.io.wavfile import write
    from scipy.io import wavfile
except ModuleNotFoundError as error:  # pragma: no cover
    write = None  # type: ignore[assignment]
    _SCIPY_IMPORT_ERROR = error
else:
    _SCIPY_IMPORT_ERROR = None
 
# Optional: whisper is not used yet, so keep the import non-fatal.
try:
    import whisper  # type: ignore[import-not-found]
except ModuleNotFoundError:  # pragma: no cover
    whisper = None  # type: ignore[assignment]
 
 
#--------------------------------------------------------------------------------------------------------------------------------
# chess move validation wrapper (uses python-chess)
class ChessMoveValidator:
    """Wraps python-chess to validate SAN moves against actual board state."""
 
    def __init__(self, board: Optional[chess.Board] = None):
        self.board = board if board is not None else chess.Board()
 
    def _variants(self, san: str) -> list:
        """Generates plausible rewrites of a regex-produced SAN string to handle
        mismatches with what python-chess's parse_san() strictly expects
        (e.g. disambiguation formatting, redundant origin squares)."""
        variants = [san]
 
        m = re.match(r"^([NBRQK])([a-h])([1-8])(x?)([a-h][1-8])(=[QRBN])?([+#])?$", san)
        if m:
            piece, ffile, frank, cap, dest, promo, suffix = m.groups()
            promo = promo or ""
            suffix = suffix or ""
            variants.append(f"{piece}{ffile}{cap}{dest}{promo}{suffix}")   # file-only
            variants.append(f"{piece}{frank}{cap}{dest}{promo}{suffix}")   # rank-only
            variants.append(f"{piece}{cap}{dest}{promo}{suffix}")          # no disambiguation
 
        return variants
 
    def validate(self, move: str) -> Optional[str]:
        """Tries to parse and push a SAN move onto the board.
        Returns the canonical SAN string if legal, or None if no variant works."""
        for candidate in self._variants(move):
            try:
                parsed = self.board.parse_san(candidate)
                canonical_san = self.board.san(parsed)
                self.board.push(parsed)
                return canonical_san
            except (chess.IllegalMoveError, chess.InvalidMoveError, chess.AmbiguousMoveError, ValueError):
                continue
        return None
 
    def validate_list(self, moves: list) -> Optional[str]:
        """Given several candidate SAN strings for the same spoken move
        (from post_processing's regex output), returns the first one that's legal."""
        for m in moves:
            result = self.validate(m)
            if result is not None:
                return result
        return None
 
 
#--------------------------------------------------------------------------------------------------------------------------------
# part1: recording the move(this must happen via the front hand or backend i am at doubt)
class audio_record:
    def __init__(self, audio_file: Optional[str] = None, sample_rate=16000):
        self.sample_rate = sample_rate
        self.array = None
        self.audio_file = audio_file
        if sd is not None:
            sd.default.samplerate = self.sample_rate
 
    def record(self, duration: int = 10) -> numpy.ndarray:
        """this function is to record the move spoken by the user when,the user presses his clock after playing on hi move"""
        if sd is None:
            raise ModuleNotFoundError(
                "sounddevice is not installed; cannot record audio"
            ) from _SOUNDDEVICE_IMPORT_ERROR
 
        print('recording ')
        audio = sd.rec(
                int(duration * self.sample_rate),
                samplerate=self.sample_rate,
                channels=1
            )
        sd.wait()
 
        print("recorded")
 
        self.recorded_array = audio
        return audio
 
    def convert_t_wave(self, audio_array: Optional[numpy.ndarray] = None) -> Path:
        ''' to convert numpy aaray data format to a wave file'''
        try:
            if audio_array is None:
                audio_array = self.recorded_array
            if audio_array is None:
                raise ValueError('Audio_array is None')
 
            if write is None:
                raise ModuleNotFoundError(
                    "scipy is not installed; cannot write WAV files"
                ) from _SCIPY_IMPORT_ERROR
 
            print("converting")
 
            output_path = Path("App") / "temp_data" / "images" / "audio_files" / "recording.wav"
            output_path.parent.mkdir(parents=True, exist_ok=True)
            write(str(output_path), self.sample_rate, audio_array)
            print('saved')
            self.recorded_audio_file = str(output_path)
            return output_path
        except Exception as e:
            raise RuntimeError(f'the file could not be converted because: {e}')
 
    def convert_t_array(self, audio_file: Optional[str] = None) -> numpy.array:
        try:
            if audio_file is None:
                audio_file = self.audio_file
            if audio_file is None:
                raise ValueError("No valid file provided")
 
            sample_rate, audio_data = wavfile.read(audio_file)
 
            self.file_sample_rate = sample_rate
            self.file_audio_data = audio_data
            return audio_data
        except Exception as e:
            raise RuntimeError(f'the PLACYBACK function could not run because: {e}')
 
    def Playback(self, audio_data: Optional[numpy.array] = None, sample_rate: Optional[int] = None, recorded: bool = False) -> None:
        try:
            if recorded is False:
                if audio_data is None:
                    if hasattr(self, "file_audio_data"):
                        audio_data = self.file_audio_data
                    else:
                        self.convert_t_array()
                        audio_data = self.file_audio_data
                if audio_data is None:
                    raise ValueError('no File provided')
                if sample_rate is None:
                    sample_rate = self.file_sample_rate
            else:
                if audio_data is None:
                    if hasattr(self, "recorded_array"):
                        audio_data = self.recorded_array
                    else:
                        self.record()
                        audio_data = self.recorded_array
 
                if audio_data is None:
                    raise ValueError('no valid file is provided')
 
                if sample_rate is None:
                    sample_rate = self.sample_rate
 
            print('playing the audio file')
            sd.play(audio_data, sample_rate)
            sd.wait()
            print('playback complete')
 
            return None
        except Exception as e:
            raise RuntimeError(f'the PLACYBACK function could not run because: {e}')
 
    @staticmethod
    def run() -> None:
        model = audio_record()
        model.record()
        model.convert_t_wave()
        model.Playback(recorded=True)
 
 
class nlp(audio_record):
    """this is the main voice_recognition class
         i will be using whisper by chatgpt to procces audio_files
         the class is inherited from audio file hence if the audio had been recorded i will be easier"""
 
    def __init__(self, audio_file, model: str = 'turbo'):
        super().__init__(audio_file=audio_file)
        self.model_initialize(model)
        self.audio_file = audio_file
        self.Move = None
 
    def model_initialize(self, model: str):
        try:
            print(f"Loading Whisper model '{model}'... this may take some time")
            self.model = whisper.load_model(model)
            print("Model Loaded")
        except Exception as e:
            raise RuntimeError(f'the program could not run because : {e}')
 
    def playback(self, audio_file: Optional[str] = None) -> None:
        try:
            if audio_file is None:
                if hasattr(self, "audio_file"):
                    audio_file = self.audio_file
                else:
                    raise ValueError("No file provided")
 
            audio_data = self.convert_t_array(audio_file)
            super().Playback(audio_data=audio_data, recorded=False)
 
            return None
        except Exception as e:
            raise RuntimeError(f'the playback function could not run because : {e}')
 
    def recognizing(self, audio_file: Optional[str] = None) -> str:
        try:
            if audio_file is None:
                if hasattr(self, "audio_file"):
                    audio_file = self.audio_file
                else:
                    raise ValueError("No file provided")
 
            self.transcribed = self.model.transcribe(audio_file)['text']
            return self.transcribed
        except Exception as e:
            raise RuntimeError(f'the recognise function could not work because {e}')
 
#-------------------------------------------------------------------------------------------------------------
    # regex patterns, aarav made ts (i dont even know how tf he wrote all this syntax without killing himself)
    PIECE_MAP = {
        r"\b(?:knight|night|nite)\b": "N",
        r"\b(?:bishop|boshop)\b": "B",
        r"\b(?:rook|brook|book)\b": "R",
        r"\b(?:queen|queens)\b": "Q",
        r"\b(?:king|kings)\b": "K",
        r"\b(?:pawn|porn|pone)\b": "",  # pawn has no letter in SAN
    }
    FILE_MAP = {
        r"\b(?:a|ay|eh)\b": "a",
        r"\b(?:b|bee|be)\b": "b",
        r"\b(?:c|see|sea|si)\b": "c",
        r"\b(?:d|dee|the)\b": "d",
        r"\b(?:e|ee)\b": "e",
        r"\b(?:f|ef|eff)\b": "f",
        r"\b(?:g|gee|ji)\b": "g",
        r"\b(?:h|aitch|age|etch)\b": "h",
    }
    RANK_MAP = {
        r"\b(?:one|1)\b": "1",
        # note: do not map bare "to" → 2; "to" is usually a preposition ("knight to f3")
        r"\b(?:two|too|2)\b": "2",
        r"\b(?:three|3)\b": "3",
        r"\b(?:four|for|4)\b": "4",
        r"\b(?:five|5)\b": "5",
        r"\b(?:six|6)\b": "6",
        r"\b(?:seven|7)\b": "7",
        r"\b(?:eight|ate|it|8)\b": "8",
    }
#---------------------------------------------------------------------------------------------------------------
    def post_processing(self, raw: Optional[str] = None) -> list:
        ''' this function recieves the raw transcribed text and peforms regex over it. the nlp often misunderstand notation for other phrases
        regex cleans up the data and then converts the text in to useable chess natation'''
 
        try:
            if not raw:
                raw = self.transcribed
 
            if not raw or not raw.strip():
                return []
            text = raw.lower().strip()
            text = re.sub(r"[^\w\s\-]", " ", text)  # drop punctuation
            text = re.sub(r"\s+", " ", text)
            # Castling first (common Whisper variants)
            if re.search(r"\b(castle|castles|castling)\b.*\b(queen|queenside|long)\b", text):
                return ["O-O-O"]
            if re.search(r"\b(castle|castles|castling)\b.*\b(king|kingside|short)\b", text):
                return ["O-O"]
            if re.search(r"\b(castle|castles|castling)\b", text):
                return ["O-O"]  # default kingside
            # Capture / check / mate markers (use raw before filler stripping)
            capture = bool(re.search(r"\bx\b|takes|take|captures|capture", raw.lower()))
            checkmate = bool(re.search(r"\b(check\s*mate|checkmate|check\s*me|check\s*ma)\b", raw.lower()))
            check = bool(re.search(r"\bcheck\b", raw.lower())) and not checkmate
 
            # Strip prepositions early so "to" is not later treated as rank 2
            text = re.sub(
                r"\b(to|takes|take|captures|capture|on|move|moves|plays|play)\b",
                " ",
                text,
            )
            text = re.sub(r"\s+", " ", text).strip()
 
            # Normalize spoken tokens → letters/numbers
            for pattern, repl in nlp.PIECE_MAP.items():
                text = re.sub(pattern, repl, text)
            for pattern, repl in nlp.FILE_MAP.items():
                text = re.sub(pattern, repl, text)
            for pattern, repl in nlp.RANK_MAP.items():
                text = re.sub(pattern, repl, text)
 
            # "a rook ..." / "a1 rook ..." → "rook a ..." so origin sits after the piece
            text = re.sub(r"\b([a-h])\s*([1-8])?\s*([NBRQK])\b", r"\3 \1\2", text)
            text = re.sub(r"\b([1-8])\s*([NBRQK])\b", r"\2 \1", text)
 
            # Keep "from a1" origin even after "from" is removed
            from_hint = re.search(r"\bfrom\s+([a-h])\s*([1-8])?\b", text)
            origin_file = from_hint.group(1) if from_hint else ""
            origin_rank = from_hint.group(2) if from_hint and from_hint.group(2) else ""
            text = re.sub(r"\bfrom\b", " ", text)
            text = re.sub(r"\s+", " ", text).strip()
 
            # Examples after cleanup: "N f 3", "R a e 5", "R a 1 e 5", "e x d 5"
            tokens = text.replace(" ", "")
            # piece + optional origin file/rank + optional x + destination (+ promo)
            move_re = re.compile(
                r"(?P<piece>[NBRQK])?"
                r"(?P<from_file>[a-h])?"
                r"(?P<from_rank>[1-8])?"
                r"(?P<cap>x)?"
                r"(?P<to_file>[a-h])"
                r"(?P<to_rank>[1-8])"
                r"(?P<promo>[NBRQ])?"
            )
            matches = list(move_re.finditer(tokens))
            moves = []
            for m in matches:
                piece = m.group("piece") or ""
                from_file = m.group("from_file") or origin_file
                from_rank = m.group("from_rank") or origin_rank
                to_file = m.group("to_file")
                to_rank = m.group("to_rank")
                promo = m.group("promo") or ""
                cap = "x" if (m.group("cap") or capture) else ""
 
                # Pawn moves: "e4", "exd5" (from-file required on capture)
                if not piece:
                    if cap:
                        notation = f"{from_file}{cap}{to_file}{to_rank}"
                    else:
                        notation = f"{to_file}{to_rank}"
                else:
                    # Keep spoken origin for disambiguation:
                    # "rook a takes e5" → Raxe5, "rook a1 to e5" → Ra1e5
                    notation = f"{piece}{from_file}{from_rank}{cap}{to_file}{to_rank}"
 
                if promo:
                    notation += f"={promo}"
                if checkmate:
                    notation += "#"
                elif check:
                    notation += "+"
                moves.append(notation)
            # Fallback: already looks like SAN in the raw transcript
            if not moves:
                san_like = re.findall(
                    r"\b(?:O-O-O|O-O|[KQRBN]?[a-h]?[1-8]?x?[a-h][1-8](?:=[QRBN])?[+#]?)\b",
                    raw,
                    flags=re.IGNORECASE,
                )
                moves = [m.upper().replace("O-O", "O-O") for m in san_like]  # keep castling case
                # Fix piece letters only
                fixed = []
                for m in san_like:
                    if m.upper() in ("O-O", "O-O-O"):
                        fixed.append(m.upper().replace("0", "O"))
                    else:
                        fixed.append(m[0].upper() + m[1:] if m[0].isalpha() else m)
                moves = fixed
            self.Move = moves
            return moves
        except Exception as e:
            raise RuntimeError(f'the program could not run because : {e}')
 
    def validification(self, move: Optional[list] = None) -> Optional[str]:
        """Validates candidate SAN move(s) against the current board state.
        Returns the canonical SAN string if legal, or None if no candidate was legal."""
        try:
            if move is None:
                move = self.Move
            if not move:
                raise ValueError('No move candidates to validate')
 
            if not hasattr(self, "validator"):
                self.validator = ChessMoveValidator()
 
            result = self.validator.validate_list(move)
            return result
        except Exception as e:
            raise RuntimeError(f'the program could not run because : {e}')
 
    def updating(self, san: Optional[str] = None) -> None:
        """Appends a validated SAN move to the in-memory scoresheet and PGN string"""
        try:
            if san is None:
                raise ValueError("No Validated move provided to update scoresheet")
 
            if not hasattr(self, "scoresheet"):
                self.scoresheet = []
 
            self.scoresheet.append(san)
            print(f"Scoresheet updated: {' '.join(self.scoresheet)}")
            return None
        except Exception as e:
            raise RuntimeError(f"The program could not run because :{e}")
 
    @staticmethod
    def run(audio_file: Optional[str] = None) -> None:
        try:
            if audio_file is None:
                audio_file = "test_audio/test9.wav"
            model = nlp(audio_file, model='base.en')
            model.recognizing()
            print("Transcribed:", model.transcribed)
            model.post_processing()
            print("Candidates:", model.Move)
            result = model.validification()
            print("Validated SAN:", result)
            if result is not None:
                model.updating(result)
            return None
        except Exception as e:
            raise RuntimeError(f'the program could not run because : {e}')

    def save_pgn(self, filepath: Optional[str] = None) ->None:
        """Writes the current PGN game tree to a .pgn file"""
        try:
            if not hasattr(self, "pgn_game"):
                print("No moves to save")
                return None
 
            if filepath is None:
                filepath = "game.pgn"
 
            with open(filepath, "w") as f:
                print(self.pgn_game, file=f, end="\n\n")
 
            print(f"PGN saved to {filepath}")
            return None
        except Exception as e:
            raise RuntimeError(f"The program could not be run because : {e}")
 
    def move_loop(self) -> None:
        """Repeatedly records, transcribes, validates and logs moves until the user types 'stop' or 'quit'."""
        try:
            if not hasattr(self, "validator"):
                self.validator = ChessMoveValidator()
 
            if not hasattr(self, "pgn_game"):
                self.pgn_game = chess.pgn.Game()
                self.pgn_node = self.pgn_game
            print("Move logger started. Press Enter to record a move, or type 'stop' to end")
 
            while True:
                turn = "White" if self.validator.board.turn else "Black"
                move_num = self.validator.board.fullmove_number
                user_input = input(f"\nMove {move_num} ({turn}) - [Enter] to record or 'stop': ").strip().lower()
 
                if user_input in ("stop", "quit", "exit"):
                    self.save_pgn()
                    print("Session Ended")
                    break
 
                self.record(duration=6)
                self.convert_t_wave()
                self.recognizing(self.recorded_audio_file)
                print("Transcribed:", self.transcribed)
 
                self.post_processing()
                print("Candidates:", self.Move)
 
                result = None
                if self.Move:
                    result = self.validification()
                    print("Validated SAN:", result)
 
                if result is None:
                    result = self._manual_correction()
 
                if result is not None:
                    self.updating(result)
                    self.pgn_node = self.pgn_node.add_variation(self.validator.board.peek())
                    print(self.validator.board)
 
        except Exception as e:
            raise RuntimeError(f"the move loop could not run because : {e}")
 
    def _manual_correction(self) -> Optional[str]:
        """Fallback prompt when speech validation fails; lets the user type the SAN move
        directly instead of guessing from a bad transcription."""
        while True:
            typed = input("Speech move failed. Type SAN move manually or 'skip' to retry recording: ").strip()
            if typed.lower() == "skip":
                return None
 
            result = self.validator.validate(typed)
            if result is not None:
                print("Validated SAN:", result)
                return result
            else:
                print(f"'{typed}' is not a legal move - try again")
 
 
#-------------------------------------------------------------------------------------------------------------------------------------
if __name__ == "__main__":
    model = nlp(audio_file=None, model='base.en')
    model.move_loop()
 
