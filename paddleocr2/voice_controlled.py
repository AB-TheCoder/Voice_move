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

#imports(secondary)
"""pending"""
#--------------------------------------------------------------------------------------------------------------------------------
class 