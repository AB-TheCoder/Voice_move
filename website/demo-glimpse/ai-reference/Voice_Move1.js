/* ============================================================
   VoiceMove — Demo (clock + manual move + voice + scoresheet)
   ============================================================ */


/* ---------- Elements ---------- */

const clockTop = document.getElementById("clock-top");
const clockBottom = document.getElementById("clock-bottom");
const clockTopLabel = document.getElementById("clock-top-label");
const clockBottomLabel = document.getElementById("clock-bottom-label");
const clockTopTime = document.getElementById("clock-top-time");
const clockBottomTime = document.getElementById("clock-bottom-time");

const resetLink = document.getElementById("reset-link");
const pauseToggle = document.getElementById("pause-toggle");
const pauseIcon = document.getElementById("pause-icon");
const pauseLabel = document.getElementById("pause-label");

const openTimeSettings = document.getElementById("open-time-settings");
const openManualMove = document.getElementById("open-manual-move");
const openVoiceScoresheet = document.getElementById("open-voice-scoresheet");
const openMovesPgn = document.getElementById("open-moves-pgn");

const timeModal = document.getElementById("time-modal");
const moveModal = document.getElementById("move-modal");
const voiceModal = document.getElementById("voice-modal");
const pgnModal = document.getElementById("pgn-modal");

const minutesInput = document.getElementById("minutes-input");
const incrementInput = document.getElementById("increment-input");
const applyTimeBtn = document.getElementById("apply-time");
const timeModalNote = document.getElementById("time-modal-note");

const miniBoard = document.getElementById("mini-board");
const movePreviewText = document.getElementById("move-preview-text");
const clearMoveBtn = document.getElementById("clear-move");
const confirmMoveBtn = document.getElementById("confirm-move");

const moveListEl = document.getElementById("move-list");
const pgnOutput = document.getElementById("pgn-output");
const copyPgnBtn = document.getElementById("copy-pgn");

const tabVoiceBtn = document.getElementById("tab-voice-btn");
const tabSheetBtn = document.getElementById("tab-sheet-btn");
const tabVoice = document.getElementById("tab-voice");
const tabSheet = document.getElementById("tab-sheet");
const micBtn = document.getElementById("mic-btn");
const voiceStatus = document.getElementById("voice-status");
const voiceTranscriptText = document.getElementById("voice-transcript-text");
const voiceMoveText = document.getElementById("voice-move-text");
const addVoiceMoveBtn = document.getElementById("add-voice-move");
const sheetInput = document.getElementById("sheet-input");
const sheetPreview = document.getElementById("sheet-preview");
const sheetNote = document.getElementById("sheet-note");


/* ---------- Clock state ---------- */

let secondsPerSide = 300;
let incrementSeconds = 0;
let topSeconds = 300;
let bottomSeconds = 300;
let topColor = null;
let bottomColor = null;
let activeSide = null;
let isRunning = false;
let intervalId = null;
let gameStarted = false;

let moveNumber = 1;
let moves = []; // { number, player, notation }

let selectedFrom = null;
let selectedTo = null;
let lastParsedVoiceMove = null;


/* ---------- Helpers ---------- */

function formatTime(totalSeconds) {
  const m = Math.floor(totalSeconds / 60);
  const s = totalSeconds % 60;
  return String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0");
}

function capitalize(word) {
  return word.charAt(0).toUpperCase() + word.slice(1);
}

function updateDisplay() {
  clockTopTime.textContent = formatTime(topSeconds);
  clockBottomTime.textContent = formatTime(bottomSeconds);

  clockTop.classList.toggle("is-active", activeSide === "top");
  clockBottom.classList.toggle("is-active", activeSide === "bottom");
  clockTop.classList.toggle("is-low-time", topSeconds <= 30);
  clockBottom.classList.toggle("is-low-time", bottomSeconds <= 30);

  clockTopLabel.textContent = topColor ? capitalize(topColor) : "Tap to begin";
  clockBottomLabel.textContent = bottomColor ? capitalize(bottomColor) : "Tap to begin";
}


/* ---------- Ticking ---------- */

function tick() {
  if (!isRunning || activeSide === null) return;

  if (activeSide === "top") {
    topSeconds--;
    if (topSeconds <= 0) { topSeconds = 0; stopClock(); alert(capitalize(topColor) + " is out of time!"); }
  } else {
    bottomSeconds--;
    if (bottomSeconds <= 0) { bottomSeconds = 0; stopClock(); alert(capitalize(bottomColor) + " is out of time!"); }
  }
  updateDisplay();
}

function stopClock() {
  isRunning = false;
  clearInterval(intervalId);
}


/* ---------- Clock taps ---------- */

function handleClockTap(side) {
  if (!gameStarted) {
    gameStarted = true;
    if (side === "top") { topColor = "white"; bottomColor = "black"; }
    else { topColor = "black"; bottomColor = "white"; }

    recordMove(side === "top" ? topColor : bottomColor);
    activeSide = side === "top" ? "bottom" : "top";
    isRunning = true;
    intervalId = setInterval(tick, 1000);
    pauseToggle.disabled = false;
    updateDisplay();
    return;
  }

  if (side !== activeSide || !isRunning) return;

  const playerJustMoved = side === "top" ? topColor : bottomColor;

  if (incrementSeconds > 0) {
    if (side === "top") topSeconds += incrementSeconds;
    else bottomSeconds += incrementSeconds;
  }

  recordMove(playerJustMoved);
  activeSide = side === "top" ? "bottom" : "top";
  updateDisplay();
}

clockTop.addEventListener("click", function () { handleClockTap("top"); });
clockBottom.addEventListener("click", function () { handleClockTap("bottom"); });


/* ---------- Recording moves ---------- */

function recordMove(player, notationOverride) {
  const notation = notationOverride || "(unrecorded)";
  moves.push({ number: moveNumber, player: player, notation: notation });
  renderMoveList();
  if (player === "black") moveNumber++;
}

function renderMoveList() {
  if (moves.length === 0) {
    moveListEl.innerHTML = '<li class="move-log__empty">No moves recorded yet.</li>';
    pgnOutput.value = "";
    return;
  }

  moveListEl.innerHTML = "";
  moves.forEach(function (move) {
    const li = document.createElement("li");
    const cls = move.player === "white" ? "move-log__player--white" : "move-log__player--black";
    li.innerHTML = '<span class="' + cls + '">' + capitalize(move.player) + "</span> — " + move.notation;
    moveListEl.appendChild(li);
  });

  pgnOutput.value = buildPgn();
}

function buildPgn() {
  let pgn = "";
  let n = 1;
  for (let i = 0; i < moves.length; i += 2) {
    const white = moves[i];
    const black = moves[i + 1];
    pgn += n + ". " + white.notation + (black ? " " + black.notation + " " : " ");
    n++;
  }
  return pgn.trim();
}


/* ---------- Reset ---------- */

resetLink.addEventListener("click", function () {
  stopClock();
  topSeconds = secondsPerSide;
  bottomSeconds = secondsPerSide;
  topColor = null;
  bottomColor = null;
  activeSide = null;
  gameStarted = false;
  moveNumber = 1;
  moves = [];
  renderMoveList();
  updateDisplay();

  pauseToggle.disabled = true;
  setPauseButtonState(false);
});


/* ---------- Pause / resume ---------- */

function setPauseButtonState(paused) {
  pauseLabel.textContent = paused ? "Resume" : "Pause";
  pauseIcon.innerHTML = paused
    ? '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M7 5l12 7-12 7z"></path></svg>'
    : '<svg viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="5" width="4" height="14"></rect><rect x="14" y="5" width="4" height="14"></rect></svg>';
}

pauseToggle.addEventListener("click", function () {
  if (!gameStarted) return;
  if (isRunning) {
    stopClock();
    setPauseButtonState(true);
  } else {
    isRunning = true;
    intervalId = setInterval(tick, 1000);
    setPauseButtonState(false);
  }
});


/* ---------- Modal open/close (shared) ---------- */

document.querySelectorAll(".modal-close").forEach(function (btn) {
  btn.addEventListener("click", function () {
    document.getElementById(btn.dataset.close).hidden = true;
  });
});

document.querySelectorAll(".modal-overlay").forEach(function (overlay) {
  overlay.addEventListener("click", function (e) {
    if (e.target === overlay) overlay.hidden = true;
  });
});


/* ---------- Time settings modal ---------- */

openTimeSettings.addEventListener("click", function () {
  timeModalNote.textContent = gameStarted
    ? "Game already in progress — applying will restart the clock."
    : "";
  timeModal.hidden = false;
});

applyTimeBtn.addEventListener("click", function () {
  const mins = parseInt(minutesInput.value, 10) || 5;
  const inc = parseInt(incrementInput.value, 10) || 0;
  secondsPerSide = mins * 60;
  incrementSeconds = inc;

  stopClock();
  topSeconds = secondsPerSide;
  bottomSeconds = secondsPerSide;
  topColor = null;
  bottomColor = null;
  activeSide = null;
  gameStarted = false;
  moveNumber = 1;
  moves = [];
  renderMoveList();
  updateDisplay();

  pauseToggle.disabled = true;
  setPauseButtonState(false);

  timeModal.hidden = true;
});


/* ---------- Manual move modal (mini board) ---------- */

const FILES = ["a", "b", "c", "d", "e", "f", "g", "h"];

function buildMiniBoard() {
  miniBoard.innerHTML = "";
  for (let rank = 8; rank >= 1; rank--) {
    for (let fileIndex = 0; fileIndex < 8; fileIndex++) {
      const square = document.createElement("div");
      const isLight = (rank + fileIndex) % 2 === 0;
      const name = FILES[fileIndex] + rank;

      square.className = "mini-board__square" + (isLight ? " mini-board__square--light" : "");
      square.dataset.square = name;
      square.addEventListener("click", function () { handleSquareClick(name, square); });
      miniBoard.appendChild(square);
    }
  }
}

function handleSquareClick(name, squareEl) {
  if (selectedFrom === null) {
    selectedFrom = name;
    squareEl.classList.add("mini-board__square--selected");
  } else if (selectedTo === null && name !== selectedFrom) {
    selectedTo = name;
    squareEl.classList.add("mini-board__square--selected");
    movePreviewText.textContent = selectedFrom + " → " + selectedTo;
  }
}

function clearMiniBoardSelection() {
  selectedFrom = null;
  selectedTo = null;
  movePreviewText.textContent = "—";
  document.querySelectorAll(".mini-board__square--selected").forEach(function (el) {
    el.classList.remove("mini-board__square--selected");
  });
}

openManualMove.addEventListener("click", function () {
  clearMiniBoardSelection();
  moveModal.hidden = false;
});

clearMoveBtn.addEventListener("click", clearMiniBoardSelection);

confirmMoveBtn.addEventListener("click", function () {
  if (!selectedFrom || !selectedTo) return;
  if (!gameStarted || activeSide === null) {
    alert("Tap a clock first to start the game before adding a move.");
    return;
  }
  const player = activeSide === "top" ? topColor : bottomColor;
  recordMove(player, selectedFrom + selectedTo);
  moveModal.hidden = true;
});

buildMiniBoard();


/* ============================================================
   VOICE / SCORESHEET MODAL
   ============================================================ */

openVoiceScoresheet.addEventListener("click", function () {
  voiceModal.hidden = false;
});

/* ---- Tabs ---- */
tabVoiceBtn.addEventListener("click", function () {
  tabVoiceBtn.classList.add("is-active");
  tabSheetBtn.classList.remove("is-active");
  tabVoice.hidden = false;
  tabSheet.hidden = true;
});

tabSheetBtn.addEventListener("click", function () {
  tabSheetBtn.classList.add("is-active");
  tabVoiceBtn.classList.remove("is-active");
  tabSheet.hidden = false;
  tabVoice.hidden = true;
});

/* ---- Move parsing — JS port of Voice_MOve.py's nlp.post_processing() ----
   Same idea as your Python regex pipeline: normalize spoken words for
   pieces/files/ranks, detect captures/check/checkmate/castling, then
   assemble SAN-like notation. Simplified for a single-move, in-browser
   demo (no Whisper — uses the Web Speech API instead). */

const PIECE_MAP = [
  [/\b(knight|night)\b/g, "N"],
  [/\b(bishop|boshop)\b/g, "B"],
  [/\b(rook|brook|book)\b/g, "R"],
  [/\b(queen|queens)\b/g, "Q"],
  [/\b(king|kings)\b/g, "K"],
  [/\b(pawn|porn|pone)\b/g, ""],
];

const FILE_MAP = [
  [/\b(a|ay|eh)\b/g, "a"],
  [/\b(b|bee|be)\b/g, "b"],
  [/\b(c|see|sea|si)\b/g, "c"],
  [/\b(d|dee|the)\b/g, "d"],
  [/\b(e|ee)\b/g, "e"],
  [/\b(f|ef|eff)\b/g, "f"],
  [/\b(g|gee|ji)\b/g, "g"],
  [/\b(h|aitch|age|etch)\b/g, "h"],
];

const RANK_MAP = [
  [/\b(one|1)\b/g, "1"],
  [/\b(two|too|2)\b/g, "2"],
  [/\b(three|3)\b/g, "3"],
  [/\b(four|for|4)\b/g, "4"],
  [/\b(five|5)\b/g, "5"],
  [/\b(six|6)\b/g, "6"],
  [/\b(seven|7)\b/g, "7"],
  [/\b(eight|ate|it|8)\b/g, "8"],
];

function parseSpokenMove(raw) {
  if (!raw || !raw.trim()) return null;

  const lower = raw.toLowerCase();

  // Castling
  if (/\b(castle|castles|castling)\b.*\b(queen|queenside|long)\b/.test(lower)) return "O-O-O";
  if (/\b(castle|castles|castling)\b.*\b(king|kingside|short)\b/.test(lower)) return "O-O";
  if (/\b(castle|castles|castling)\b/.test(lower)) return "O-O";

  const capture = /\bx\b|takes|take|captures|capture/.test(lower);
  const checkmate = /\b(check\s*mate|checkmate)\b/.test(lower);
  const check = /\bcheck\b/.test(lower) && !checkmate;

  let text = lower.replace(/[^\w\s-]/g, " ").replace(/\s+/g, " ").trim();
  text = text.replace(/\b(to|takes|take|captures|capture|on|move|moves|plays|play)\b/g, " ");
  text = text.replace(/\s+/g, " ").trim();

  PIECE_MAP.forEach(function (pair) { text = text.replace(pair[0], pair[1]); });
  FILE_MAP.forEach(function (pair) { text = text.replace(pair[0], pair[1]); });
  RANK_MAP.forEach(function (pair) { text = text.replace(pair[0], pair[1]); });

  const tokens = text.replace(/\s+/g, "");
  const moveRe = /([NBRQK])?([a-h])?([1-8])?(x)?([a-h])([1-8])([NBRQ])?/;
  const m = tokens.match(moveRe);

  if (!m) return null;

  const piece = m[1] || "";
  const fromFile = m[2] || "";
  const fromRank = m[3] || "";
  const cap = (m[4] || capture) ? "x" : "";
  const toFile = m[5];
  const toRank = m[6];
  const promo = m[7] || "";

  if (!toFile || !toRank) return null;

  let notation;
  if (!piece) {
    notation = cap ? fromFile + "x" + toFile + toRank : toFile + toRank;
  } else {
    notation = piece + fromFile + fromRank + cap + toFile + toRank;
  }
  if (promo) notation += "=" + promo;
  if (checkmate) notation += "#";
  else if (check) notation += "+";

  return notation;
}

/* ---- Web Speech API wiring ---- */

let recognition = null;
let isRecording = false;
const SpeechRecognitionCtor = window.SpeechRecognition || window.webkitSpeechRecognition;

if (SpeechRecognitionCtor) {
  recognition = new SpeechRecognitionCtor();
  recognition.lang = "en-US";
  recognition.interimResults = false;
  recognition.maxAlternatives = 1;

  recognition.addEventListener("result", function (event) {
    const transcript = event.results[0][0].transcript;
    voiceTranscriptText.textContent = transcript;
    const parsed = parseSpokenMove(transcript);
    lastParsedVoiceMove = parsed;
    voiceMoveText.textContent = parsed || "Couldn't parse a move";
  });

  recognition.addEventListener("end", function () {
    isRecording = false;
    micBtn.classList.remove("is-recording");
    voiceStatus.textContent = "Tap the mic to start";
  });

  recognition.addEventListener("error", function () {
    isRecording = false;
    micBtn.classList.remove("is-recording");
    voiceStatus.textContent = "Didn't catch that — tap to try again";
  });
} else {
  voiceStatus.textContent = "Voice input isn't supported in this browser (try Chrome or Edge)";
  micBtn.disabled = true;
}

micBtn.addEventListener("click", function () {
  if (!recognition) return;
  if (isRecording) {
    recognition.stop();
    return;
  }
  isRecording = true;
  micBtn.classList.add("is-recording");
  voiceStatus.textContent = "Listening…";
  voiceTranscriptText.textContent = "—";
  voiceMoveText.textContent = "—";
  lastParsedVoiceMove = null;
  recognition.start();
});

/* ---- Scoresheet upload (staged preview only — OCR is backend work) ---- */

sheetInput.addEventListener("change", function () {
  const file = sheetInput.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = function (e) {
    sheetPreview.src = e.target.result;
    sheetPreview.hidden = false;
    sheetNote.hidden = false;
  };
  reader.readAsDataURL(file);
});

/* ---- Add parsed voice move to the log ---- */

addVoiceMoveBtn.addEventListener("click", function () {
  if (!lastParsedVoiceMove) {
    alert("No parsed move yet — record a move on the Voice tab first.");
    return;
  }
  if (!gameStarted || activeSide === null) {
    alert("Tap a clock first to start the game before adding a move.");
    return;
  }
  const player = activeSide === "top" ? topColor : bottomColor;
  recordMove(player, lastParsedVoiceMove);
  voiceModal.hidden = true;
});


/* ---- Moves + PGN modal ---- */

openMovesPgn.addEventListener("click", function () {
  renderMoveList();
  pgnModal.hidden = false;
});

copyPgnBtn.addEventListener("click", function () {
  if (!pgnOutput.value) return;
  navigator.clipboard.writeText(pgnOutput.value).then(function () {
    copyPgnBtn.textContent = "Copied!";
    setTimeout(function () { copyPgnBtn.textContent = "Copy PGN"; }, 1500);
  });
});


/* ---- Initial state ---- */
updateDisplay();
