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

            print('playing')
            sd.play(audio_data,sample_rate)
            sd.wait()
            print('complete')
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
        super().__init__(audio_file)
        self.model_initialize(model)
    @classmethod
    def model_initialize(self,model:str):
        try:
            self.model = whisper.load_model(model)
        except Exception as e:
            raise RuntimeError(f'the program could not run because : {e}')
            
    def recognizing(self,audio_file:Optional[str] = None) -> str:
        try:
            if audio_file is None:
                if  hasattr(super(),"audio_file"):
                    audio_file == super().audio_file
                else:
                    if hasattr(super(),"recorded_audio_file"):
                        audio_file == super().recorded_audio_file
                    else:
                        raise ArgumentError("No file provided")
            

            self.transcribed = self.model.transcribe(audio_file)
            return self.transcribed
        except Exception as e:
            raise RuntimeError(f'the recognise function could not work because {e}')
    @property
    def seperating():
        pass
    def post_processing(self):
        try:
            pass
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
    def run():
        model = nlp(r'App\Data\audio_files\test1.wav')
        model.transcribe()
        print(model.transcribed)
if __name__ == "__main__":
    # audio_record.run()
    nlp.run()

