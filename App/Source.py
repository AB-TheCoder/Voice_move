# This is the main source code file for the app-(name not finalised)


# packages and modules
import google.genai as genai

import sys
import Clock
import fastapi as api 




#----------------------------------------------------------------------------------------------------------------------------
#image Capturing/uploading
# capturing
# import cv2 as cv2
# class picture():
#     @staticmethod
#     def click():
        

# # Open webcam (0 = default camera)
#         cap = cv2.VideoCapture(0)

#         while True:
#             ret, frame = cap.read()

#             if not ret:
#                 break

#             # Show the frame
#             cv2.imshow("Camera", frame)

#          # Press 's' to save image
#             if cv2.waitKey(1) & 0xFF == ord('s'):
#                 cv2.imwrite("captured.jpg", frame)
#                 print("Image saved!")

#         # Press 'q' to quit
#             if cv2.waitKey(1) & 0xFF == ord('q'):
#                 break

#         cap.release()
#         cv2.destroyAllWindows()

#     def upload(self):
#         pass

# picture.click()
import paddleocr as ocr
#-----------------------------------------------------------------------------------------------------------------------------
# Timer
# Timer
import time 
from pynput import keyboard
import sys
class ChessClock:
    def __init__(self, initial_time=300, increment=0):
        self.time = {
            1: float(initial_time),
            2: float(initial_time)
        }
        self.increment = increment
        self.current_player = 1
        self.running = False
        self.last_time = None

    def start(self):
        if not self.running:
            self.running = True
            self.last_time = time.time()

    def pause(self):
        if self.running:
            self._update_time()
            self.running = False
    def unpause(self):
        if not self.running:
            self._update_time
            self.running=True

    def switch(self):
        if not self.running:
            return

        self._update_time()

        # Add increment to player who just moved
        self.time[self.current_player] += self.increment

        # Switch player
        self.current_player = 2 if self.current_player == 1 else 1
        self.last_time = time.time()

    def _update_time(self):
        if not self.running:
            return

        now = time.time()
        elapsed = now - self.last_time
        self.time[self.current_player] -= elapsed
        self.last_time = now

    def get_times(self):
        self._update_time()
        return {
            "player1": max(0, int(self.time[1])),
            "player2": max(0, int(self.time[2]))
        }

    def is_flagged(self):
        if self.time[self.current_player]<0:
            return True
        else:
            return False

    def get_winner(self):
        if self.time[1] <= 0:
            return 2
        if self.time[2] <= 0:
            return 1
        return None

    
def start_clock(timer,increment):
    global Running
    timer=ChessClock(timer,increment)
    timer.start()
    Running=True
    def on_press(key):
        global Running
        try:
            if key == keyboard.Key.space:
                timer.switch()

            elif key.char == "p":
                print('\ntimer paused')
                timer.pause()

            elif key.char == "r":
                print('\ntimer resumed')
                timer.unpause()

        except AttributeError:
            pass

        if key == keyboard.Key.esc:
            Running=False
            return False
            
            
            


    listener = keyboard.Listener(on_press=on_press)
    listener.start()


    while Running:
        times=timer.get_times()
        print(f"\rplayer1:{times['player1']}| Player2:{times['player2']}",end="")
        
        flag = timer.is_flagged()
        if flag:
            Running=False
            print(f"\r player {timer.get_winner()} has lost") 
        time.sleep(0.1) 
    else:
        sys.exit()
        quit()



start_clock(120,10)


#------------------------------------------------------------------------------------------------------------------------
# Stock Fish Analyis----
import stockfish
 















#---------------------------------------------------------------------------------------------------------------------
