# This is the main source code file for the app-(name not finalised)


# packages and modules
import google.genai as genai
import os




# gemini (image recognistion)


# def analyis_image():
#     pass
# # Configure with your API key
# gemini=genai.Client(api_key="AIzaSyA_ENCdLto3XHB3fLHTGKF51DsjpSdBFuw")

# # Initialize the model

# model=gemini.models.generate_content(

#     model="gemini-2.5-flash",
#     contents='pass'
    
# )
# print(model.text)


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
#-----------------------------------------------------------------------------------------------------------------------------
# Timer
import time 
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
        return self.time[1] <= 0 or self.time[2] <= 0

    def get_winner(self):
        if self.time[1] <= 0:
            return 2
        if self.time[2] <= 0:
            return 1
        return None

timer=ChessClock(150,10)
timer.start()
Running=True
# while Running:
# while timer.is_flagged









#------------------------------------------------------------------------------------------------------------------------
# Stock Fish Analyis----















#---------------------------------------------------------------------------------------------------------------------
