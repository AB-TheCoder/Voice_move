'''
this is the main file for the voice controlled chess notation(VCCN)
this feature is a revolutionary way to record chess moves replacing the orthodox written method
main Authors@- Aarav Bhatt
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
from ctypes import ArgumentError
from pathlib import Path
from typing import Optional
import re
import numpy

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
# part1: recording the move(this must happen via the front hand or backend i am at doubt)
class audio_record:
    def __init__(self,audio_file :Optional[str] = None,sample_rate = 16000):
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
    def convert_t_array(self,audio_file:Optional[str] = None) -> numpy.array:
        try:
            if audio_file is None:
                audio_file = self.audio_file
            if audio_file is None:
                raise ValueError("No valid file provided")

            sample_rate,audio_data = wavfile.read(audio_file)

            self.file_sample_rate = sample_rate
            self.file_audio_data = audio_data
            return audio_data
        except Exception as e:
            raise RuntimeError(f'the PLACYBACK function could not run because: {e}')
    def Playback(self, audio_data:Optional[numpy.array] = None,sample_rate :Optional[int] = None,recorded:bool = False) -> None:
        try:
            if recorded is False:
                if audio_data is None:
                    if hasattr(self,"file_audio_data"):
                        audio_data = self.file_audio_data
                    else:
                        self.convert_t_array()
                        audio_data = self.file_audio_data
                if audio_data  is None:
                    raise ValueError('no File provided')
                if sample_rate is None:
                    sample_rate = self.file_sample_rate
            else:
                if audio_data is None:
                    if hasattr(self,"recorded_array"):
                        audio_data = self.recorded_array
                    else:
                        self.record()
                        audio_data = self.recorded_array
                    
                if audio_data is None:
                    raise ValueError('no valid file is provided')


                if sample_rate is None:
                    sample_rate = self.sample_rate

            print('playing the audio file')
            sd.play(audio_data,sample_rate)
            sd.wait()
            print('playback complete')

            return None
        except Exception as e:
            raise RuntimeError(f'the PLACYBACK function could not run because: {e}')

    @staticmethod
    def run():
        model = audio_record()
        model.record()
        model.convert_t_wave()
        model.Playback(recorded=True)


class nlp(audio_record):
    """this is the main voice_recognition class
         i will be using whisper by chatgpt to procces audio_files
         the class is inherited from audio file hence if the audio had been recorded i will be easier"""
        
    def __init__(self,audio_file,model:str='turbo'):
        self.model_initialize(model)
        self.audio_file = audio_file
    @classmethod
    def model_initialize(self,model:str):
        try:
            self.model = whisper.load_model(model)
        except Exception as e:
            raise RuntimeError(f'the program could not run because : {e}')
    def playback(self,audio_file:Optional[str] = None)->None:
        try:
            if audio_file is None:
                if  hasattr(self,"audio_file"):
                    audio_file == self.audio_file
                else:
                    raise ArgumentError("No file provided")
            
            super().Playback(audio_file)
            
            return None  
        except Exception as e:
            raise RuntimeError(f'the playback function could not run because : {e}')
    def recognizing(self,audio_file:Optional[str] = None) -> str:
        try:
            if audio_file is None:
                if  hasattr(self,"audio_file"):
                    audio_file = self.audio_file
                else:
                    raise ArgumentError("No file provided")
            

            self.transcribed = self.model.transcribe(audio_file)['text']
            return self.transcribed
        except Exception as e:
            raise RuntimeError(f'the recognise function could not work because {e}')
#-------------------------------------------------------------------------------------------------------------
# regex patterns
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
        r"\b(?:two|to|too|2)\b": "2",
        r"\b(?:three|3)\b": "3",
        r"\b(?:four|for|4)\b": "4",
        r"\b(?:five|5)\b": "5",
        r"\b(?:six|6)\b": "6",
        r"\b(?:seven|7)\b": "7",
        r"\b(?:eight|ate|it|8)\b": "8",
    }
#---------------------------------------------------------------------------------------------------------------
    def post_processing(self,raw:Optional[str]=None)->list:
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
            # Normalize spoken tokens → letters/numbers
            for pattern, repl in nlp.PIECE_MAP.items():
                text = re.sub(pattern, repl, text)
            for pattern, repl in nlp.FILE_MAP.items():
                text = re.sub(pattern, repl, text)
            for pattern, repl in nlp.RANK_MAP.items():
                text = re.sub(pattern, repl, text)
            # Common filler words Whisper inserts
            text = re.sub(
                r"\b(to|takes|take|captures|capture|on|move|moves|plays|play)\b",
                " ",
                text,
            )
            text = re.sub(r"\s+", " ", text).strip()
            # Capture / check / mate markers still spoken
            capture = bool(re.search(r"\bx\b|takes|capture", raw.lower()))
            checkmate = bool(re.search(r"\b(check\s*mate|checkmate|check\s*me|check\s*ma)\b", raw.lower()))
            check = bool(re.search(r"\bcheck\b", raw.lower())) and not checkmate
            # Pull piece + squares from cleaned text
            # Examples after cleanup: "N f 3", "e 4", "N c 3", "e x d 5"
            tokens = text.replace(" ", "")
            # Pattern: optional piece, optional from-file/rank, optional x, destination square
            move_re = re.compile(
                r"(?P<piece>[NBRQK])?"          # piece
                r"(?P<from_file>[a-h])?"        # disambiguation file
                r"(?P<from_rank>[1-8])?"        # disambiguation rank
                r"(?P<cap>x)?"                  # capture
                r"(?P<to_file>[a-h])"
                r"(?P<to_rank>[1-8])"
                r"(?P<promo>[NBRQ])?"           # promotion piece if spoken
            )
            matches = list(move_re.finditer(tokens))
            moves = []
            for m in matches:
                piece = m.group("piece") or ""
                from_file = m.group("from_file") or ""
                from_rank = m.group("from_rank") or ""
                to_file = m.group("to_file")
                to_rank = m.group("to_rank")
                promo = m.group("promo") or ""
                # Prefer spoken capture if regex missed "x"
                cap = "x" if (m.group("cap") or capture) else ""
                # Pawn capture needs from-file: "e takes d5" → exd5
                if not piece and cap and from_file:
                    notation = f"{from_file}{cap}{to_file}{to_rank}"
                elif not piece and cap and not from_file:
                    # ambiguous pawn capture; keep destination only as fallback
                    notation = f"x{to_file}{to_rank}"
                else:
                    # Avoid treating destination file as disambiguation when no piece
                    # e.g. "e4" should not become "e4" with from_file=e wrongly split.
                    # If only one file+rank exist, treat as destination.
                    if not piece and from_file and from_rank and not to_file:
                        notation = f"{from_file}{from_rank}"
                    else:
                        # If piece + two squares spoken poorly, keep piece + destination
                        if piece and from_file and from_rank and to_file and to_rank:
                            # likely "knight c3" mis-split; prefer piece + last square
                            notation = f"{piece}{cap}{to_file}{to_rank}"
                        else:
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
            self.processed = moves
            return moves
        except Exception as e:
            raise RuntimeError(f'the program could not run because : {e}')
    def validification(self)-> list:
        try:
            pass
        except Exception as e:
            raise RuntimeError(f'the program could not run because : {e}')
    
    def Finale_proccesing(self):
        try:
            pass
        except Exception as e:
            raise RuntimeError(f'the program could not run because : {e}')
    @staticmethod
    def run()->None:
        try:
            model = nlp(r'App\Data\audio_files\test9.wav',model='base.en')
            model.playback()
            model.recognizing()
            print(model.transcribed)
            model.post_processing()
            print(model.processed)
            return None
        except Exception as e:
            raise RuntimeError(f'the program could not run because : {e}')
if __name__ == "__main__":
    # audio_record.run()
    nlp.run()

