import curses
import random
import time

# Game Constants
WIDTH = 60
HEIGHT = 20
PLAYER_CHAR = "🚀"
ENEMY_CHAR = "👾"
BULLET_CHAR = "|"
STAR_CHAR = "."
EXPLOSION_CHAR = "💥"

class SpaceGame:
    def __init__(self, stdscr):
        self.stdscr = stdscr
        self.setup_terminal()
        self.player_pos = [HEIGHT // 2, WIDTH // 2]
        self.bullets = []
        self.enemies = []
        self.stars = [[random.randint(0, HEIGHT-1), random.randint(0, WIDTH-1)] for _ in range(50)]
        self.score = 0
        self.running = True
        self.last_tick = time.time()

    def setup_terminal(self):
        curses.curs_set(0)
        self.stdscr.nodelay(True)
        self.stdscr.timeout(100)
        curses.start_color()
        curses.init_pair(1, curses.COLOR_GREEN, curses.COLOR_BLACK)  # Player
        curses.init_pair(2, curses.COLOR_RED, curses.COLOR_BLACK)    # Enemy
        curses.init_pair(3, curses.COLOR_WHITE, curses.COLOR_BLACK)  # Stars
        curses.init_pair(4, curses.COLOR_YELLOW, curses.COLOR_BLACK) # Bullets/Explosions

    def spawn_enemy(self):
        if random.random() < 0.05:
            side = random.choice(['top', 'bottom', 'left', 'right'])
            if side == 'top': pos = [0, random.randint(0, WIDTH-1)]
            elif side == 'bottom': pos = [HEIGHT-1, random.randint(0, WIDTH-1)]
            elif side: pos = [random.randint(0, HEIGHT-1), 0] if side == 'left' else [random.randint(0, HEIGHT-1), WIDTH-1]
            self.enemies.append(pos)

    def update(self):
        # Move stars (scrolling effect)
        for star in self.stars:
            star[0] = (star[0] + 1) % HEIGHT
            if star[0] == 0: star[1] = random.randint(0, WIDTH-1)

        # Move bullets
        new_bullets = []
        for b in self.bullets:
            b[0] -= 1 # Upwards
            if 0 <= b[0] < HEIGHT:
                new_bullets.append(b)
        self.bullets = new_bullets

        # Move enemies
        for e in self.enemies:
            if e[0] < self.player_pos[0]: e[0] += 1
            elif e[0] > self.player_pos[0]: e[0] -= 1
            if e[1] < self.player_pos[1]: e[1] += 1
            elif e[1] > self.player_pos[1]: e[1] -= 1

        # Collision detection
        for b in self.bullets[:]:
            for e in self.enemies[:]:
                if b[0] == e[0] and b[1] == e[1]:
                    self.score += 10
                    if b in self.bullets: self.bullets.remove(b)
                    if e in self.enemies: self.enemies.remove(e)

        # Check player collision
        for e in self.enemies:
            if e == self.player_pos:
                self.running = False

        self.spawn_enemy()

    def draw(self):
        self.stdscr.clear()
        
        # Draw stars
        for s in self.stars:
            try: self.stdscr.addstr(s[0], s[1], STAR_CHAR, curses.color_pair(3))
            except: pass

        # Draw player
        try: self.stdscr.addstr(self.player_pos[0], self.player_pos[1], PLAYER_CHAR, curses.color_pair(1))
        except: pass

        # Draw bullets
        for b in self.bullets:
            try: self.stdscr.addstr(b[0], b[1], BULLET_CHAR, curses.color_pair(4))
            except: pass

        # Draw enemies
        for e in self.enemies:
            try: self.stdscr.addstr(e[0], e[1], ENEMY_CHAR, curses.color_pair(2))
            except: pass

        # Draw Score
        self.stdscr.addstr(0, 0, f"Score: {self.score} | Use WASD to Move | Q to Quit", curses.A_BOLD)
        self.stdscr.refresh()

    def run(self):
        while self.running:
            try:
                key = self.stdscr.getch()
                if key == ord('q') or key == ord('Q'): break
                elif key == ord('w') and self.player_pos[0] > 0: self.player_pos[0] -= 1
                elif key == ord('s') and self.player_pos[0] < HEIGHT-1: self.player_pos[0] += 1
                elif key == ord('a') and self.player_pos[1] > 0: self.player_pos[1] -= 1
                elif key == ord('d') and self.player_pos[1] < WIDTH-1: self.player_pos[1] += 1
                elif key in [ord(' '), ord('f')]: # Space or F to shoot
                    self.bullets.append([self.player_pos[0]-1, self.player_pos[1]])

                self.update()
                self.draw()
                time.sleep(0.05)
            except Exception as e:
                break
        self.stdscr.nodelay(False)
        self.stdscr.addstr(HEIGHT//2, WIDTH//4, " GAME OVER ", curses.A_REVERSE)
        self.stdint_sleep(2)

    def stdint_sleep(self, sec):
        time.sleep(sec)

if __name__ == "__main__":
    try:
        curses.wrapper(lambda ss: SpaceGame(ss).run())
    except KeyboardInterrupt:
        pass
