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
from whisper import Whisper
import sounddevice as sd
#imports(secondary)
"""pending"""
import numpy
from scipy.io.wavfile import write
#--------------------------------------------------------------------------------------------------------------------------------
# part1: recording the move(this must happen via the front hand or backend i am at doubt)
class recorder:
    def __init__(self):
        self.sample_rate = 16000
        sd.default.samplerate =self.sample_rate
        
    def record(self,duration = 10 ):
        """this function is to record the move spoken by the user when,the user presses his clock after playing on hi move"""
        print('recording ')
        audio = sd.rec(
                int(duration * self.sample_rate),
                samplerate=self.sample_rate,
                channels=1
            )
        sd.wait()
        write(r"App\temp_data\images\audio_files\recording.wav", self.sample_rate, audio)
        print("Saved!")

rec = recorder
rec.record()