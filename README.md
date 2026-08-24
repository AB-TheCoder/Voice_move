# Chess Analysis

 
### Introduction: 

Chess is a very analytical and ever-learning game. Learning from one's mistakes is essential regarding our personal ethics, and the same values also applies when playing chess. An ambitious chess player always learns from their mistakes and keeps the cycle of growth going. To learn from one's mistakes in life, one needs to reflect upon the  mistakes, and similarly, in chess, one needs to look back. 

 

### The Great Spark: 

When analysing a friendly chess game with my friend, W realised how it sucked to type all the moves on the platform and how irritating and inefficient it was. 

**And that was that**

 

### The DREAM: 

We realised we needed to put this way into the bin and come up with a new platform for a next-level learning experience and an extremely efficient and user-friendly platform. 

 

 

 

#### @ means that it is not yet final. 
*******************************************************************************************************************************************************************
### First Creation(what we dream it looks like and the functions it will have):
*@research required*
 
 #### We will first create a prototype Android app which won't have all the components, but a few basic components, such as :

* A sophisticated image-capturing interface and an interface to get an image by clicking one or uploading one

* Image analysing AI, which will take a PNG image of the score sheet and figure out the notation.

* A Chess engine that will analyse the game and provide outputs

* a GUI to show the output
 
* An Android application for it
    

### Working(Protoype): 
@
So there are mainly 2 major components: the GUI (graphical user interface) and the main computational algorithm.
The GUI is mainly a medium through which user interaction can happen, and the generated output can be shown.The algorithm is the main code that  performs all the actions

#### Algorithm:
**@research required**
clock:
    a simple timer would be created using time module and basic python syntax.furthur work would be done on frontend

Image_recog:
    the image will be taken by the user (or uploaded) then to improve the results it will be enhanced through open cv python module.then a OCR ai will be used to recognise the moves .the output will be ran through a chess ai which will verify the accuracy of the interpreted moves and make changes accordingly.then another chess based module will be used to create a pgn for further workings.
voice_recog:
    this is another main feature for our application ,and probably more selling than the other one. the user will press the clock and then hold it to speak his/her move to register it onthe on app scoresheet.open-ai whisper will be used. 

#### Gui:
**@research required**
 

### Running and Demoing the macOS Build:

For local testing and for showing the reviewer the app actually working, the Flutter prototype can be run as a native desktop app on macOS instead of only on Android or iOS. Steps:

**1. Enable macOS as a build target (one-time setup):**
```
flutter config --enable-macos-desktop
```

**2. Add macOS platform files if they don't already exist:**
```
flutter create --platforms=macos .
```

**3. Run the app directly:**
```
flutter run -d macos
```

**4. Or build it once and open the compiled app bundle directly, without going through flutter run each time:**
```
flutter build macos --debug
open build/macos/Build/Products/Debug/vccn_app.app
```

Note: features relying on the microphone (voice_recog) require a usage description key in `macos/Runner/Info.plist` and the audio-input entitlement to be enabled in the Runner entitlements files, or the permission prompt will not appear and speech recognition will silently fail.

### Other Ways to Show the Reviewer the App Working:

**Android APK release:** build a release APK (`flutter build apk --release`) and attach it to a GitHub Release. This is the most accessible option, since anyone with an Android phone can download and sideload it directly, no dev account or extra setup needed.

**Screen recording:** record a short video of the app running on the simulator, emulator, or a real device, showing the core flow end to end. Upload it as a GitHub Release asset or to the free CDN, and link it as the demo. This works regardless of platform and needs no installation from the reviewer at all.

**TestFlight (iOS):** if a paid Apple Developer account is available, a public TestFlight link lets a reviewer install and use the actual iOS build on their own device. More setup and cost than the other options, so only worth it if the account already exists.

**Web build:** if the app doesn't rely too heavily on native-only plugins, `flutter build web` compiles it into a live site that opens directly in a browser, no install needed by the reviewer at all.

### Work Division:

Bachand Python coding, for the prototype - Aarav 

GUI for an Android app, which will take the Python code as an api - Vihaan 



### Team Rules and pacts for collaboration:  

Any disputes between the producers greatly affect the product; so, for this enterprise not to be jeopardised by any disputes between the creators, certain team rules and pacts must be followed. 

************************************************************************* 

### Team Rules and pacts for collaboration:  

Any disputes between the producers greatly affect the product; so, for this enterprise not to be jeopardised by any disputes between the creators, certain team rules and pacts must be followed. 

* The project will be a collective enterprise 

* Any decision will be taken collectively 

* Money matters will also be equal or, in certain cases, under the agreement of both 

* Never edit someone else's code without telling them  

* Pull the latest code before starting work  

* Test before pushing  

* Write clear commit messages (not "fixed stuff") 

* The work will be divided to prevent chaos. 

* All things must be discussed 

* Task must be completed within the time limit 

* To prevent chaos and conflicts, there must be one owner of a project on GitHub; he can only change the main file, others can request or change the file at their end only. But this owner can only exercise his powers upon discussion and agreement. 

* The project must matter rather than one's personal ego; the rules must be followed  


### THE Great Race against the Great "TIME":  

This project is being created with a challenging time goal of a basic completion of the platform within 2months. Day and night will be sacrificed for the doing of so. 

 
## Important Questions and Possible Problems: 

* High cost for server maintenance  

* Inaccurate detection from the scoresheet 
* costs for creating

* High time investment in design and UI 

* GPT model will need to be PRO subscription to handle such a high number of image requests 
* requirements of servers 

* Gemini Model can only analyse images uploaded on the internet.

 

Credits:  

This project will be the outcome of the hard work, dreams and aspirations of both its creators- Vihaan Vasudeva and Aarav Bhatt 
 

 
@ means that it is not final
