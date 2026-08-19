# Chess Analysis

## Introduction

Chess is an analytical and ever-learning game. Learning from one's mistakes is essential in life, and the same idea applies to chess. An ambitious chess player learns from their mistakes, reflects on them, and keeps improving.

This project started with a simple idea: make that learning process easier.

## The Spark

While analysing a friendly chess game with a friend, we realised how annoying it was to manually type every move into a platform just to analyse the game later. It was slow, repetitive, and honestly just inefficient.

**And that was that.**

## The Dream

We wanted to build something that made recording and analysing a chess game much more natural.

The idea grew into a platform that could:

- Record a chess game using a chess clock.
- Listen to spoken moves and convert them into chess notation.
- Automatically generate a PGN of the game.
- Record the time taken for every move.
- Let players review the game afterwards.
- Analyse the game using a chess engine.
- Shows inaccuracies, mistakes, blunders, great moves, best moves, book moves, accuracy, and other useful insights.
- Let players explore positions and engine variations instead of simply looking at a final score.
- Eventually (maybe later to add) provide a place where players can store their games and return to them for learning.

The goal is not just to analyse a game, but to make **learning from the game easier (atleast OTB)**.

---

## First Creation

The first version is a Flutter-based mobile application built around a chess clock and voice-controlled move entry.

The prototype currently focuses on the core experience:

- A fully functional chess clock.
- Press-and-hold voice input for moves.
- Automatic transcription and chess-move interpretation.
- Manual move entry as a backup
- Automatic PGN generation.
- Clock time and move-time information stored with the PGN.
- Game history and move navigation.
- A post-game **Save & Analyze** workflow.
- An interactive analysis board using Stockfish.
- Engine evaluations and multiple principal variations.
- Move classifications such as book, best, great, good, inaccuracy, mistake, and blunder.
- Full-game computer analysis with accuracy and other statistics.
- Interactive analysis where positions and engine variations can be explored.

Inspired by lichess and chess.com

The current implementation is still being refined, and ive some planned features are marked with `@` where further research or development is required.

---

## Working

There are two major parts to the project:

### 1. GUI 
It handles:

- The chess clock.
- Voice-input interaction.
- Manual move entry.
- The chess board.
- Move history.
- PGN viewing and sharing.
- The analysis board.
- Engine lines and evaluations.
- Analysis reports and navigation.

The interface is being designed specifically for mobile use, with the aim of keeping the experience simple while still providing the depth expected from modern chess analysis platforms.

### 2. Main Computational System

The computational side of the project performs the actual work behind the interface.

This includes:

- Speech recognition.
- Spoken chess-move interpretation.
- Legal-move validation.
- SAN/PGN generation.
- Position tracking.
- Move-time calculation.
- Stockfish-based analysis.
- Move classification.
- Accuracy and game statistics.
- Engine variation generation.
- Analysis of different positions and variations.

---

## Current Status

The application is currently being developed using Flutter and Dart (latest versions btw.

The project uses:

- **Flutter** for the mobile application.
- **Dart** for the application logic.
- **dartchess** for chess positions, legal moves, SAN and game-state handling.
- **Stockfish** for chess analysis.
- **chessground** for the interactive analysis board.
- **speech_to_text** for cross-platform speech recognition.
- **Apple SpeechAnalyzer / SpeechTranscriber** for the newer iOS speech pipeline on supported devices.
- **SharePlus** for PGN sharing.

The aim is to keep the main chess logic independent of the platform wherever possible, while using platform-specific capabilities where they provide a meaningful advantage.

---

## Work Division

**Vihaan Vasudeva** — Flutter backend and UI/UX of the mobile application

**Aarav Bhatt** — Initial Python regex script and website development

The division may evolve as the project grows, but both creators contribute to the overall direction and development of the project.
especially vihaan coz it seems like hes doing all the fucking work

---

# The Great Race Against Time

The initial goal is to complete the basic version of the platform within **two months** in total.

It is an ambitious target, but the purpose of the deadline is to force us to focus on building the core product first rather than getting stuck trying to perfect everything immediately. We can make it perfect later!

The project will continue to improve after the initial two-month milestone.

---

## Important Questions and Possible Problems

There are still several challenges that need to be solved or researched:

- Speech recognition can sometimes misinterpret chess moves.
- Regex can only be added up to a point, native language models(like people not using English and all) often classify stuff as different
- Different accents, speaking speeds, background noise, and microphones can affect recognition.
- Supporting different speech-recognition systems across platforms adds complexity.
- Stockfish analysis can be computationally demanding on mobile devices.
- Full-game analysis may require careful optimisation to keep the application responsive.
- Server costs may become an issue if cloud storage or cloud-based services are introduced later.
- Designing a good mobile chess-analysis interface requires considerable time and testing.
- Local storage and/or cloud storage will need to be designed if a larger personal game library is added.
- Opening databases and book-move detection need further research if we want comprehensive opening information.
- The project needs extensive testing with real games and different users before the system can be considered reliable.
- The two-month deadline creates a significant time constraint while both creators continue their other commitments.

These problems are not necessarily reasons to stop the project; they are areas we need to solve as development continues.

---

## Future Direction

The long-term idea is larger than a chess clock.

We want to build a system where recording a game, analysing it, understanding what went wrong, and learning from it all happen in one place.

Possible future additions include:

- Local or cloud-based game libraries.
- Games grouped by opponent.
- Searchable game history.
- Opening Explorer.
- More advanced training from mistakes.
- Personal performance trends over multiple games.
- Better time-management analysis using the recorded move times.
- Improved speech recognition and chess-language interpretation.
- More advanced sharing and analysis reports.
- Support for analysing imported games as well as games played using the clock.

Basically a all in one platform for improvement and development of one's OTB chess skill and tracking of mistakes and patterns.

---

## Credits

This project is the result of the work, ideas, and aspirations of both its creators:

**Vihaan Vasudeva and Aarav Bhatt**

**@The app being completely on device for now ill be preferred, we may add more advanced features later which might require cloud and internet services to work, I have a few ideas, regarding software and potential hardware extensions of this project and also for academies (and also individuals). Ill list them down here later in detail**

---

`@` means that a section is still being developed, researched, or finalised.
