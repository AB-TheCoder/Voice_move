# Andriod-App for Voice_Move:-
* created by Aarav bhatt
## AIM:-
* create an andriod prototype as soon as possible

## FLOW(USED AI):-

1. Build and test the backend alone first
Wrap your existing OCR (PaddleOCR) and voice (Whisper) scripts with FastAPI. Two endpoints to start: POST /process-image and POST /process-audio. Get these fully working and tested via the auto-generated /docs UI before writing a single line of Android code — debugging OCR/voice logic is much faster in Python directly than through an app UI.

2. Add move validation before touching the app
pip install python-chess. Every move coming out of OCR or voice should pass through a board object that checks legality and builds the PGN. Do this now, while you're still just hitting the API with curl/Postman — much easier to catch validation bugs before an app UI is in the mix.

3. Set up Android Studio and confirm connectivity
Install Android Studio on Windows, create a bare Kotlin project, and get it displaying a hardcoded 'Hello World' response from your local backend (http://YOUR_IP:8000) over Wi-Fi. This proves the connection works before you build any real UI.

4. Build the UI screen by screen
Build one screen at a time: first a simple photo capture screen wired to /process-image, then a voice recording screen wired to /process-audio. Get each one showing raw API output before styling anything — function before polish.

5. Wire up a visual board once moves are validating
Add a board display (even a simple grid) that reflects the validated game state coming back from your backend, so you can see moves land correctly rather than just reading raw text/JSON.

6. Move off local Wi-Fi and test on a real device
Deploy the backend to Railway or Render (free tier is enough for testing) so you're not limited to your home Wi-Fi. Point the Android app at the public URL and test on a real phone — camera/mic behave differently than the emulator.

7. Publish to the Play Store
Once photo→moves and voice→moves both work reliably end-to-end on a real phone, register a $25 Play Store developer account and follow Google's standard listing/review flow.
