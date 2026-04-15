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
    
clock = ChessClock(initial_time=60, increment=2)

clock.start()

while not clock.is_flagged():
    times = clock.get_times()
    print(f"\rP1: {times['player1']}s | P2: {times['player2']}s | Turn: P{clock.current_player}", end="")

    # user_input = input("\nPress ENTER to switch, 'p' to pause: ")



winner = clock.get_winner()
print(f"\nPlayer {winner} wins on time!")