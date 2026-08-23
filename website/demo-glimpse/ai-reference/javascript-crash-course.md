# JavaScript Crash Course — for building your Chess Clock

You know Python already, so every section below leans on that. JS syntax differs, but the thinking is the same.

---

## 1. Variables

```js
let whiteSeconds = 300;   // can be reassigned later
const minutesPerSide = 5; // cannot be reassigned
```

- `let` = normal variable, like Python's plain `x = 5`
- `const` = locked after creation — use it by default, switch to `let` only when the value needs to change
- Every line ends in `;` (Python doesn't require this — JS does, by convention)
- No colons, no indentation-based blocks — JS uses `{ }` curly braces instead

```python
# Python
x = 5
if x > 3:
    print("big")
```
```js
// JavaScript
let x = 5;
if (x > 3) {
  console.log("big");
}
```
`console.log()` is JS's `print()`.

---

## 2. Data types

```js
let name = "Aarav";        // string
let count = 12;            // number (JS has no separate int/float)
let isRunning = true;      // boolean
let nothing = null;        // like Python's None
let notSet;                // undefined — declared but never given a value
```

---

## 3. Functions

```js
function greet(name) {
  return "Hello, " + name;
}
```

Same idea as Python's `def`, but the body is wrapped in `{ }` instead of relying on indentation.

There's also a shorter "arrow function" style you'll see a lot in real JS code:

```js
const greet = (name) => {
  return "Hello, " + name;
};
```

Both work the same — the arrow style is just more common in modern code. Use whichever reads clearer to you while learning.

---

## 4. Conditionals

```js
if (whiteSeconds <= 0) {
  console.log("White is out of time");
} else if (whiteSeconds <= 30) {
  console.log("Low time warning");
} else {
  console.log("Plenty of time");
}
```

Comparison operators are almost identical to Python: `>`, `<`, `>=`, `<=`.
Equality is the one gotcha: use `===` (not `==`) to compare values in JS — it checks type too, which avoids weird bugs. Python's `==` maps to JS's `===`, not `==`.

---

## 5. Arrays (JS's version of Python lists)

```js
let moves = [];              // empty array, like moves = []
moves.push("e4");            // like .append()
moves.push("Nf3");
console.log(moves[0]);       // "e4" — same indexing as Python
console.log(moves.length);   // like len(moves)
```

Looping over one:
```js
moves.forEach(function (move) {
  console.log(move);
});
```
This is JS's version of `for move in moves:`.

---

## 6. Objects (JS's version of Python dicts)

```js
let move = {
  number: 1,
  player: "white",
  notation: "e4"
};

console.log(move.player);   // dot notation instead of move["player"]
```

You can also mix objects into arrays — this is exactly what your move log will be:

```js
let moves = [
  { number: 1, player: "white", notation: "e4" },
  { number: 1, player: "black", notation: "e5" }
];
```

---

## 7. The DOM — reaching into your HTML

This is the one genuinely new concept with no direct Python equivalent, because Python scripts don't normally control a web page.

```js
const clockEl = document.getElementById("white-clock");
```

This line finds the HTML element with `id="white-clock"` and stores a reference to it in `clockEl`. Once you have that reference, you can read or change it:

```js
clockEl.textContent = "05:00";        // change the visible text
clockEl.classList.add("is-active");   // add a CSS class
clockEl.classList.remove("is-active");// remove a CSS class
clockEl.classList.toggle("is-active", someBoolean); // add/remove based on true/false
```

Match this back to your `clock.html` — every element with an `id` (`white-clock`, `black-time`, `move-list`, etc.) is something you can grab with `getElementById` and control from JS.

---

## 8. Events — reacting to clicks

```js
const button = document.getElementById("start-btn");

button.addEventListener("click", function () {
  console.log("Button was clicked!");
});
```

`addEventListener(eventName, functionToRun)` means "when `eventName` happens on this element, run this function." This is how taps on your clock buttons will trigger move-recording and turn-switching.

---

## 9. setInterval — the ticking loop

There's no Python equivalent you already know for this one. It's JS's way of saying "run this repeatedly, forever, until I say stop":

```js
let seconds = 10;

const intervalId = setInterval(function () {
  seconds--;
  console.log(seconds);
  if (seconds <= 0) {
    clearInterval(intervalId); // stops the repeating calls
  }
}, 1000); // 1000 milliseconds = 1 second
```

This is exactly how your clock ticks down once per second while running.

---

## 10. Putting it together — the shape of your clock logic

```js
// 1. Grab elements
const whiteTimeEl = document.getElementById("white-time");

// 2. State (variables that change over time)
let whiteSeconds = 300;
let isRunning = false;
let intervalId = null;

// 3. A function to update what's on screen
function updateDisplay() {
  const mins = Math.floor(whiteSeconds / 60);
  const secs = whiteSeconds % 60;
  whiteTimeEl.textContent = mins + ":" + secs;
}

// 4. A function that runs every second
function tick() {
  whiteSeconds--;
  updateDisplay();
}

// 5. Start/stop functions
function start() {
  isRunning = true;
  intervalId = setInterval(tick, 1000);
}

function stop() {
  isRunning = false;
  clearInterval(intervalId);
}

// 6. Wire a button to start it
document.getElementById("start-btn").addEventListener("click", start);
```

That's genuinely most of the language you need for this project. Everything else (recording moves into an array, rendering them as a list) is combining the pieces above.

---

## Cheat sheet: Python → JavaScript

| Python | JavaScript |
|---|---|
| `x = 5` | `let x = 5;` |
| `def f(x):` | `function f(x) { }` |
| `print(x)` | `console.log(x);` |
| `if x > 3:` | `if (x > 3) { }` |
| `x == y` | `x === y` |
| `list.append(x)` | `array.push(x)` |
| `len(list)` | `array.length` |
| `for x in list:` | `array.forEach(function(x) { })` |
| `dict["key"]` | `object.key` |
| `None` | `null` |
| f-strings `f"{x}"` | template strings `` `${x}` `` |

---

## Your task

Using this, write `clock.js` yourself against your existing `clock.html`. Suggested build order:

1. Grab all the elements you need with `getElementById`
2. Set up your state variables (`whiteSeconds`, `blackSeconds`, `activePlayer`, `isRunning`)
3. Write `formatTime()` and `updateDisplay()`
4. Write `tick()` and wire it to `setInterval` inside a `start()` function
5. Add click listeners on the two clock buttons to switch turns
6. Add the move-recording array and rendering last

Post your code as you go — happy to review each piece rather than just handing you the finished file.
