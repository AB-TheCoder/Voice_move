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
    a simple timer would be created using time module and basic python syntax.furthur work would be done on frontend and analysis engine and other features will be imported and used.
    
#### Gui:
**@research required**
 

### Setting Up Flutter and Dart (for anyone demoing the app, including the reviewer):

Before running the app for the first time, Flutter (which includes Dart) needs to be installed. Steps:

**1. Download the Flutter SDK:**

Go to https://docs.flutter.dev/get-started/install and pick your OS (Windows, macOS, or Linux). This downloads the SDK, which includes the Dart SDK as well — no separate Dart install is needed.

**2. Add Flutter to your PATH:**

macOS/Linux example (after extracting the SDK to a folder, e.g. `~/development/flutter`):
```
export PATH="$PATH:$HOME/development/flutter/bin"
```
Add that line to your `~/.zshrc` or `~/.bashrc` so it persists across terminal sessions.

Windows: add the full path to the `flutter\bin` folder to your System Environment Variables under "Path".

**3. Verify the install:**
```
flutter doctor
```
This checks your setup and tells you if anything else is missing (like Android Studio, Xcode, or a connected device/emulator).

**4. Clone the repo and get dependencies:**
```
git clone <the repo URL>
cd flutter_projects/vccn_app
flutter pub get
```

**5. Run the app:**
```
flutter run
```
This will prompt you to pick a connected device, emulator, or simulator if more than one is available. See the "Running and Demoing the macOS Build" section below for the macOS-specific run/build commands, or the Android APK release for a version that doesn't require installing Flutter at all.

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

Note: features relying on the microphone (voice_recog) require a usage description key in `macos/Runner/Info.plist` and the audio-input entitlement to be enabled in the Runner entitlements files, or the permission prompt will not appear and speech recognition will fail.


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
