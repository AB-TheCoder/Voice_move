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
from pathlib import Path
from typing import Optional

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
    def __init__(self):
        self.sample_rate = 16000
        self.array = None
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
        
        self.array = audio
        return audio
    
    def convert_t_wave(self, audio_array: Optional[numpy.ndarray] = None) -> Path:
        ''' to convert numpy aaray data format to a wave file'''
        try:
            if audio_array is None:
                audio_array = self.array
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
            return output_path
        except Exception as e:
            raise RuntimeError(f'the file could not be converted because: {e}')
    def Playback(self, audio: Optional[numpy.ndarray] = None):
        try:
            if audio_array is None:
                audio_array = self.array
            if audio_array is None:
                raise ValueError('Audio_array is None')
        except Exception as e:
            raise RuntimeError(f'the PLACYBACK function could not run because: {e}')
    @staticmethod
    def run():
        model = audio_record()
        model.record()
        model.convert_t_wave()

if __name__ == "__main__":
    audio_record.run()
