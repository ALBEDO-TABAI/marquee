"""Neutral drawn stand-ins for a smart pack's picture slots.

Each scene is drawn, never photographed: a moon over a roofline for a
中秋 opening shot, a product on a podium for 带货, a faceless bust in a
studio for 口播. They exist so a pack's poster and hover show what the
pack is for, under its own titles, without anyone's face or any
third-party picture. Pure Pillow; drawn at twice the size and scaled
down, so every edge is smooth.
"""
import math
import random
from PIL import Image, ImageDraw, ImageFilter, ImageChops

SS = 2  # supersampling


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


class Canvas:
    def __init__(self, w, h, seed):
        self.w, self.h = w * SS, h * SS
        self.s = min(self.w, self.h)
        self.im = Image.new("RGB", (self.w, self.h))
        self.d = ImageDraw.Draw(self.im)
        self.r = random.Random(seed)

    # geometry in 0..1 of width/height; sizes in fractions of the short side
    def X(self, u):
        return u * self.w

    def Y(self, v):
        return v * self.h

    def S(self, k):
        return k * self.s

    def vgrad(self, top, bottom, y0=0.0, y1=1.0):
        top, bottom = rgb(top), rgb(bottom)
        a, b = int(self.Y(y0)), int(self.Y(y1))
        for y in range(a, b):
            self.d.line([(0, y), (self.w, y)], fill=lerp(top, bottom, (y - a) / max(1, b - a - 1)))

    def rect(self, u0, v0, u1, v1, fill, radius=0.0, outline=None, width=0):
        self.d.rounded_rectangle([self.X(u0), self.Y(v0), self.X(u1), self.Y(v1)],
                                 radius=self.S(radius), fill=rgb(fill) if fill else None,
                                 outline=rgb(outline) if outline else None, width=int(self.S(width)))

    def circle(self, u, v, r, fill, outline=None, width=0):
        x, y, rr = self.X(u), self.Y(v), self.S(r)
        self.d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=rgb(fill) if fill else None,
                       outline=rgb(outline) if outline else None, width=int(self.S(width)))

    def ellipse(self, u, v, rx, ry, fill):
        x, y = self.X(u), self.Y(v)
        self.d.ellipse([x - self.S(rx), y - self.S(ry), x + self.S(rx), y + self.S(ry)], fill=rgb(fill))

    def poly(self, pts, fill):
        self.d.polygon([(self.X(u), self.Y(v)) for u, v in pts], fill=rgb(fill))

    def line(self, pts, color, width):
        self.d.line([(self.X(u), self.Y(v)) for u, v in pts], fill=rgb(color), width=max(1, int(self.S(width))), joint="curve")

    def glow(self, draw, blur, strength=1.0):
        """Something light drawn on black, blurred and added: a lamp, a moon's halo."""
        layer = Image.new("RGB", self.im.size)
        draw(ImageDraw.Draw(layer), self)
        layer = layer.filter(ImageFilter.GaussianBlur(self.S(blur)))
        if strength != 1.0:
            layer = layer.point(lambda p: int(p * strength))
        self.im = ImageChops.add(self.im, layer)
        self.d = ImageDraw.Draw(self.im)

    def ridge(self, base, amp, freq, color, phase=0.0, rough=0.0):
        pts = [(0, 1.0)]
        for i in range(0, 121):
            u = i / 120
            v = base + amp * math.sin(u * math.tau * freq + phase) + rough * math.sin(u * math.tau * freq * 3.7 + phase * 2)
            pts.append((u, v))
        pts.append((1, 1.0))
        self.poly(pts, color)

    def bust(self, u, v, k, body, head=None, shoulder_w=1.0):
        """A faceless head and shoulders, `k` the head's radius: who speaks, not who."""
        head = head or body
        self.ellipse(u, v + k * 2.9 * (self.s / self.h), k * 2.6 * shoulder_w, k * 1.9, body)
        self.rect(u - k * 0.45 * self.s / self.w, v + k * 0.6 * self.s / self.h,
                  u + k * 0.45 * self.s / self.w, v + k * 1.6 * self.s / self.h, body)
        self.ellipse(u, v, k * 0.86, k, head)

    def stars(self, n, v1, color="#ffffff", rmax=0.004):
        for _ in range(n):
            self.circle(self.r.random(), self.r.random() * v1, rmax * (0.4 + self.r.random()), color)

    def bokeh(self, n, colors, rmin, rmax, v0=0.0, v1=1.0, strength=0.8):
        spots = [(self.r.random(), v0 + self.r.random() * (v1 - v0), rmin + self.r.random() * (rmax - rmin),
                  self.r.choice(colors)) for _ in range(n)]

        def draw(d, c):
            for u, v, r, col in spots:
                x, y, rr = c.X(u), c.Y(v), c.S(r)
                d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=rgb(col))
        self.glow(draw, rmin * 0.35, strength)

    def vignette(self, amount=0.35):
        mask = Image.new("L", self.im.size, 0)
        md = ImageDraw.Draw(mask)
        md.ellipse([-self.w * 0.25, -self.h * 0.25, self.w * 1.25, self.h * 1.25], fill=255)
        mask = mask.filter(ImageFilter.GaussianBlur(self.s * 0.18))
        dark = Image.new("RGB", self.im.size, (0, 0, 0))
        self.im = Image.composite(self.im, Image.blend(self.im, dark, amount), mask)
        self.d = ImageDraw.Draw(self.im)

    def result(self, w, h):
        return self.im.resize((w, h), Image.LANCZOS)


# ---------------------------------------------------------------- scenes
# Each takes a Canvas and a palette tint (0..1) that turns a pack's
# variant of the scene a little, never into another scene.

def moon_roofline(c, t):
    c.vgrad("#0d1838", "#2a3f72")
    c.stars(60, 0.55)
    c.glow(lambda d, c: d.ellipse([c.X(.68) - c.S(.2), c.Y(.3) - c.S(.2), c.X(.68) + c.S(.2), c.Y(.3) + c.S(.2)], fill=(120, 100, 50)), .08)
    c.circle(.68, .30, .12, "#f6e3a1")
    c.circle(.655, .285, .02, "#ead08a"); c.circle(.70, .32, .014, "#ead08a")
    # a pavilion roof and an osmanthus branch
    c.poly([(0, .78), (.12, .70), (.30, .66), (.48, .70), (.6, .78)], "#0a1022")
    c.rect(0, .78, .62, 1, "#0a1022")
    c.ridge(.86, .015, 1.2, "#070b18")
    c.line([(1.0, .05), (.86, .14), (.78, .16)], "#1b1410", .012)
    for u, v in [(.92, .08), (.88, .12), (.83, .14), (.79, .17), (.95, .1)]:
        c.circle(u, v, .012, "#e8b04a")
    c.vignette(.3)


def reunion_table(c, t):
    c.vgrad("#3a1f1a", "#6b3524")
    c.bokeh(14, ["#ffb35a", "#ff8a3d"], .02, .05, 0, .45, .5)
    for u in (.18, .82):  # lanterns
        c.line([(u, 0), (u, .12)], "#2a1410", .004)
        c.ellipse(u, .2, .07, .085, "#d8382b"); c.rect(u - .02, .27, u + .02, .30, "#e8b04a")
    c.bust(.33, .45, .075, "#2b1712"); c.bust(.66, .44, .08, "#24130f")
    c.bust(.5, .5, .065, "#331b14")
    c.ellipse(.5, .9, .62, .16, "#8a4a2a")
    for u in (.36, .5, .64):
        c.circle(u, .86, .045, "#e2b062"); c.circle(u, .86, .03, "#c98c3c")


def lanterns_fireworks(c, t):
    c.vgrad("#2a0508", "#7a1016")
    def fw(d, c):
        for (u, v, r, col) in [(.25, .25, .16, (255, 190, 80)), (.72, .18, .12, (255, 110, 90)), (.55, .4, .09, (255, 230, 150))]:
            for k in range(28):
                a = k / 28 * math.tau
                d.line([(c.X(u) + math.cos(a) * c.S(r) * .3, c.Y(v) + math.sin(a) * c.S(r) * .3),
                        (c.X(u) + math.cos(a) * c.S(r), c.Y(v) + math.sin(a) * c.S(r))], fill=col, width=int(c.S(.006)))
    c.glow(fw, .004, 1.0); c.glow(fw, .02, .8)
    for i, u in enumerate((.12, .3, .7, .88)):
        top = .0; v = .55 + (i % 2) * .08
        c.line([(u, top), (u, v - .09)], "#3a0a08", .004)
        c.ellipse(u, v, .075, .09, "#e0302a"); c.ellipse(u, v, .05, .09, "#c42420")
        c.rect(u - .025, v - .1, u + .025, v - .08, "#f0c24a"); c.rect(u - .025, v + .08, u + .025, v + .1, "#f0c24a")
        c.line([(u, v + .1), (u, v + .16)], "#f0c24a", .006)


def christmas_tree(c, t):
    c.vgrad("#0b1a2e", "#1d3b57")
    c.stars(40, .5)
    c.ridge(.82, .02, .8, "#e9eef5"); c.rect(0, .86, 1, 1, "#dfe6ef")
    for k, (w, v) in enumerate([(.22, .78), (.17, .62), (.12, .47)]):
        c.poly([(.5 - w * c.s / c.w * 1.2, v), (.5, v - .22), (.5 + w * c.s / c.w * 1.2, v)], ["#1f5b3a", "#236842", "#2a7a4c"][k])
    c.rect(.485, .78, .515, .86, "#5a3a22")
    c.bokeh(26, ["#ffd36b", "#ff6b6b", "#7fd3ff"], .006, .012, .3, .78, 1.2)
    c.circle(.5, .24, .025, "#ffd36b")
    for u, col in [(.33, "#c8323a"), (.66, "#2f6fd0"), (.73, "#e0b640")]:
        c.rect(u - .05, .8, u + .05, .9, col); c.rect(u - .008, .8, u + .008, .9, "#f5f0e0")


def gifts_fireplace(c, t):
    c.vgrad("#2b1610", "#4a271a")
    c.rect(.2, .2, .8, .75, "#5b3324"); c.rect(.3, .35, .7, .75, "#160b07")
    c.glow(lambda d, c: d.ellipse([c.X(.38), c.Y(.5), c.X(.62), c.Y(.8)], fill=(255, 140, 40)), .05, 1.2)
    c.rect(.15, .18, .85, .23, "#7a4a33")
    for i, u in enumerate((.25, .4, .6, .75)):
        c.line([(u, .23), (u, .3)], "#e8d8b0", .003); c.rect(u - .025, .3, u + .025, .38, ["#c8323a", "#2f7a4a"][i % 2], .01)
    c.rect(0, .78, 1, 1, "#3a1f15")
    for u, w, h, col in [(.18, .09, .14, "#c8323a"), (.32, .07, .1, "#2f7a4a"), (.8, .1, .12, "#e0b640")]:
        c.rect(u - w / 2, .9 - h, u + w / 2, .9, col, .006); c.rect(u - .008, .9 - h, u + .008, .9, "#f5efe0")


def string_lights(c, t):
    c.vgrad("#1a1430", "#3a2450")
    c.bokeh(30, ["#ffcf6b", "#ff7fa8", "#8fd7ff", "#b6ff8f"], .015, .05, 0, 1, .7)
    for k in range(3):
        pts = [(u / 20, .12 + k * .14 + .06 * math.sin(u / 20 * math.pi)) for u in range(21)]
        c.line(pts, "#0e0a1c", .003)
        for i in range(1, 20, 2):
            u, v = pts[i]
            c.poly([(u - .02, v), (u + .02, v), (u, v + .07)], ["#ff6b6b", "#ffd36b", "#6bc6ff", "#9cff8f"][(i + k) % 4])


def party_balloons(c, t):
    c.vgrad("#ffd9c7", "#f3a6a0")
    for u, v, col in [(.15, .25, "#ff6b8a"), (.28, .15, "#ffd36b"), (.8, .2, "#6bb8ff"), (.9, .32, "#b48cff"), (.68, .1, "#ff9f5a")]:
        c.line([(u, v + .1), (u + .02, v + .4)], "#ffffff", .002)
        c.ellipse(u, v, .055, .07, col)
    c.bust(.38, .5, .08, "#7a3f4a"); c.bust(.6, .48, .085, "#5e2f3d")
    c.rect(0, .9, 1, 1, "#d98a86")


def dawn_landscape(c, t):
    c.vgrad("#2b3a55", "#e6a77a")
    c.glow(lambda d, c: d.ellipse([c.X(.3) - c.S(.15), c.Y(.62) - c.S(.15), c.X(.3) + c.S(.15), c.Y(.62) + c.S(.15)], fill=(255, 190, 120)), .1)
    c.ridge(.6, .06, .7, "#5b6a8a", 1.0, .01)
    c.ridge(.68, .05, 1.1, "#3c4a68", 2.0, .01)
    c.ridge(.8, .04, 1.7, "#222c44", .5, .008)
    mist = Image.new("RGB", c.im.size, (230, 200, 190))
    c.im = Image.blend(c.im, mist, .12); c.d = ImageDraw.Draw(c.im)


def profile_rim(c, t):
    c.vgrad("#0e1014", "#1b1e26")
    c.glow(lambda d, c: d.ellipse([c.X(.62), c.Y(.1), c.X(1.2), c.Y(1.1)], fill=(80, 110, 160)), .12)
    c.ellipse(.45, .45, .17, .2, "#07080b"); c.ellipse(.42, .95, .34, .25, "#07080b")
    c.line([(.6, .3), (.62, .45), (.6, .6)], "#9fc0ff", .006)


def action_burst(c, t):
    c.vgrad("#2a0f05", "#ff7a1a")
    for k in range(48):
        a = k / 48 * math.tau
        c.line([(.5, .5), (.5 + math.cos(a) * .9, .5 + math.sin(a) * .9)], "#ffd27a" if k % 2 else "#ff9a3a", .01)
    c.circle(.5, .5, .12, "#fff1c4")
    c.poly([(.35, .9), (.45, .62), (.55, .62), (.65, .9)], "#1a0a04")


def night_road(c, t):
    c.vgrad("#050812", "#1a2238")
    c.poly([(.44, .5), (.56, .5), (1.0, 1), (0, 1)], "#111520")
    for k in range(6):
        v0 = .52 + k * k * .012; v1 = v0 + .01 + k * .006
        c.poly([(.497 - k * .003, v0), (.503 + k * .003, v0), (.505 + k * .006, v1), (.495 - k * .006, v1)], "#e8d27a")
    c.glow(lambda d, c: [d.ellipse([c.X(u) - c.S(.03), c.Y(.55) - c.S(.03), c.X(u) + c.S(.03), c.Y(.55) + c.S(.03)], fill=(255, 240, 200)) for u in (.47, .53)], .03, 1.3)
    c.ridge(.5, .02, 2.3, "#0a0e18")


def rain_window(c, t):
    c.vgrad("#2a3644", "#4a5a6a")
    c.bokeh(24, ["#ffb36b", "#ff7f6b", "#9fd0ff"], .03, .07, 0, 1, .6)
    for _ in range(70):
        u, v = c.r.random(), c.r.random()
        c.ellipse(u, v, .004, .007, "#b8c8d8")
    c.rect(.48, 0, .52, 1, "#1c242e"); c.rect(0, .48, 1, .52, "#1c242e")


def back_view_sea(c, t):
    c.vgrad("#b9c4cf", "#e8d6c8", 0, .55)
    c.vgrad("#6f8496", "#3e5163", .55, 1)
    c.line([(0, .55), (1, .55)], "#f2e6da", .003)
    c.ellipse(.62, .62, .04, .045, "#20262c"); c.ellipse(.62, .76, .07, .1, "#20262c")
    c.rect(0, .86, 1, 1, "#cdbba6")


def noodle_bowl(c, t):
    c.vgrad("#5a3a26", "#3a2418")
    for k in range(9):
        c.line([(0, k / 8), (1, k / 8 + .1)], "#4a2f1f", .004)
    c.circle(.5, .52, .36, "#f1ebe2"); c.circle(.5, .52, .31, "#c6762f")
    for k in range(14):
        a = k / 14 * math.tau
        c.line([(.5 + math.cos(a) * .05 * c.s / c.w, .52 + math.sin(a) * .05 * c.s / c.h), (.5 + math.cos(a + 1.1) * .22 * c.s / c.w, .52 + math.sin(a + 1.1) * .22 * c.s / c.h)], "#f2d58a", .01)
    c.circle(.42, .44, .06, "#f7f1d8"); c.circle(.42, .44, .03, "#f2b43a")
    for u, v in [(.58, .46), (.6, .6), (.45, .62)]:
        c.circle(u, v, .025, "#4f8a3a")
    c.line([(.78, .12), (.9, .92)], "#2b1a10", .014); c.line([(.83, .1), (.94, .9)], "#2b1a10", .014)


def restaurant(c, t):
    c.vgrad("#3b2216", "#6a3a22")
    for u in (.2, .5, .8):
        c.line([(u, 0), (u, .18)], "#1a0f08", .003)
        c.poly([(u - .06, .22), (u + .06, .22), (u + .03, .17), (u - .03, .17)], "#1a0f08")
    c.glow(lambda d, c: [d.ellipse([c.X(u) - c.S(.1), c.Y(.24) - c.S(.06), c.X(u) + c.S(.1), c.Y(.24) + c.S(.06)], fill=(255, 170, 80)) for u in (.2, .5, .8)], .05, 1.1)
    c.rect(0, .62, 1, 1, "#7a4a2c")
    for u in (.25, .5, .75):
        c.ellipse(u, .74, .12, .05, "#efe7dc"); c.ellipse(u, .73, .07, .03, ["#c8562f", "#6a9a3a", "#d8a03a"][int(u * 4) % 3])
    c.rect(.62, .52, .66, .66, "#d8e8f0")


def neon_grid(c, t):
    c.vgrad("#0a0420", "#2a0848")
    for k in range(1, 14):
        v = .55 + (k / 13) ** 2 * .45
        c.line([(0, v), (1, v)], "#ff3ec8", .003)
    for k in range(-10, 11):
        c.line([(.5 + k * .02, .55), (.5 + k * .16, 1)], "#ff3ec8", .003)
    c.circle(.5, .38, .16, "#ff9a3e")
    for k in range(5):
        c.rect(.2, .32 + k * .035, .8, .335 + k * .035 + .006, "#2a0848")
    c.circle(.5, .5, .05, None, "#3ef0ff", .006); c.line([(.43, .5), (.57, .5)], "#3ef0ff", .004); c.line([(.5, .43), (.5, .57)], "#3ef0ff", .004)


def victory(c, t):
    c.vgrad("#081a3a", "#0a3a6a")
    c.glow(lambda d, c: d.ellipse([c.X(.3), c.Y(.15), c.X(.7), c.Y(.75)], fill=(255, 200, 60)), .1, .8)
    c.poly([(.42, .3), (.58, .3), (.56, .48), (.44, .48)], "#f2c03a")
    c.rect(.47, .48, .53, .58, "#d9a52a"); c.rect(.43, .58, .57, .63, "#b8861e")
    for u in (.3, .7):
        c.poly([(u, .25), (u + .015, .29), (u + .05, .29), (u + .022, .315), (u + .032, .355), (u, .33), (u - .032, .355), (u - .022, .315), (u - .05, .29), (u - .015, .29)], "#ffe27a")
    c.rect(.2, .72, .8, .78, "#123a6e", .01); c.rect(.2, .72, .62, .78, "#3ef0ff", .01)


def city_day(c, t):
    c.vgrad("#8fc3e8", "#e6f0f5")
    c.circle(.8, .2, .06, "#fff6d8")
    r = c.r
    for layer, col, base in [(0, "#a9bccb", .5), (1, "#7f95a8", .58), (2, "#566b80", .66)]:
        u = 0
        while u < 1:
            w = .04 + r.random() * .07; h = .1 + r.random() * .25
            c.rect(u, base - h, u + w, 1, col)
            if layer == 2:
                for wy in range(int(h / .04)):
                    for wx in range(int(w / .02)):
                        c.rect(u + .005 + wx * .02, base - h + .01 + wy * .04, u + .013 + wx * .02, base - h + .03 + wy * .04, "#9fb4c6")
            u += w + .004
    c.rect(0, .9, 1, 1, "#3f4f5f")


def city_night(c, t):
    c.vgrad("#060a1e", "#24164a")
    c.stars(30, .3)
    r = c.r
    lit = []
    for layer, col, base in [(0, "#1a1a3a", .55), (1, "#121230", .66), (2, "#0a0a20", .78)]:
        u = 0
        while u < 1:
            w = .04 + r.random() * .07; h = .12 + r.random() * .3
            c.rect(u, base - h, u + w, 1, col)
            for wy in range(int(h / .035)):
                for wx in range(int(w / .018)):
                    if r.random() < .35:
                        lit.append((u + .004 + wx * .018, base - h + .01 + wy * .035))
            u += w + .003
    def draw(d, c):
        for u, v in lit:
            d.rectangle([c.X(u), c.Y(v), c.X(u + .008), c.Y(v + .015)], fill=(255, 200, 110) if r.random() < .7 else (120, 220, 255))
    c.glow(draw, .0, 1.0); c.glow(draw, .01, .6)
    c.vgrad("#0a0a20", "#2a1240", .82, 1)


def neon_street(c, t):
    c.vgrad("#0a0612", "#1a0a24")
    c.rect(0, 0, .3, .8, "#120a1c"); c.rect(.7, 0, 1, .8, "#120a1c")
    def signs(d, c):
        for u0, v0, u1, v1, col in [(.04, .15, .24, .2, (255, 60, 180)), (.76, .25, .96, .3, (60, 220, 255)), (.06, .4, .2, .44, (255, 200, 60)), (.78, .5, .94, .54, (255, 80, 120))]:
            d.rounded_rectangle([c.X(u0), c.Y(v0), c.X(u1), c.Y(v1)], radius=c.S(.01), outline=col, width=int(c.S(.008)))
    c.glow(signs, .0); c.glow(signs, .02, .9)
    c.poly([(.3, .8), (.7, .8), (1, 1), (0, 1)], "#1c1028")
    c.bokeh(10, ["#ff3cb4", "#3cdcff"], .01, .03, .82, 1, .6)
    c.ellipse(.5, .62, .03, .035, "#05030a"); c.ellipse(.5, .74, .055, .09, "#05030a")


def street_day(c, t):
    c.vgrad("#bcd6ea", "#f2ede4")
    c.poly([(0, 0), (.38, .35), (.38, .75), (0, 1)], "#c9a98a"); c.poly([(1, 0), (.62, .35), (.62, .75), (1, 1)], "#a8b8a0")
    for k in range(5):
        v = .1 + k * .14
        c.poly([(.05, v + .02), (.3, .33 + k * .06), (.3, .36 + k * .06), (.05, v + .08)], "#e9dccb")
        c.poly([(.95, v + .02), (.7, .33 + k * .06), (.7, .36 + k * .06), (.95, v + .08)], "#dfe8d8")
    c.poly([(.38, .75), (.62, .75), (1, 1), (0, 1)], "#8a8c8c")
    c.ellipse(.46, .64, .012, .014, "#4a4a52"); c.rect(.452, .655, .468, .72, "#4a4a52")


def host_studio(c, t, wall="#3a4a5a", body="#1e252c", shelf=True, lamp=True, centre=.5):
    c.vgrad(wall, lerp_hex(wall, "#000000", .35))
    if shelf:
        for k in range(3):
            v = .2 + k * .17
            c.rect(.06, v, .3, v + .012, "#2a2018")
            for i in range(6):
                c.rect(.07 + i * .035, v - .06 - (i % 3) * .01, .095 + i * .035, v, ["#a85a3a", "#3a6a8a", "#c8a24a", "#5a8a5a"][(i + k) % 4])
    if lamp:
        c.glow(lambda d, c: d.ellipse([c.X(.82) - c.S(.12), c.Y(.32) - c.S(.12), c.X(.82) + c.S(.12), c.Y(.32) + c.S(.12)], fill=(255, 180, 90)), .07)
        c.line([(.82, .36), (.82, .8)], "#1a1410", .006); c.poly([(.78, .36), (.86, .36), (.84, .28), (.8, .28)], "#e8c08a")
    c.bust(centre, .42, .1, body)


def lerp_hex(a, b, t):
    return "#%02x%02x%02x" % lerp(rgb(a), rgb(b), t)


def host_ringlight(c, t):
    c.vgrad("#f4dfe0", "#e8c4c8")
    for k in range(4):
        c.rect(.06, .18 + k * .18, .94, .19 + k * .18, "#d9aab0")
        for i in range(10):
            if i not in (4, 5):
                c.rect(.08 + i * .09, .1 + k * .18, .13 + i * .09, .18 + k * .18, ["#ff8aa0", "#ffd36b", "#8ad0ff", "#c8a0ff"][(i + k) % 4], .006)
    c.circle(.5, .4, .2, None, "#ffffff", .02)
    c.bust(.5, .42, .095, "#5a3440")


def product_podium(c, t, bg=("#e9e3dc", "#c9bfb4"), prod="#2f6fd0", cap="#f2f2f2"):
    c.vgrad(*bg)
    c.ellipse(.5, .78, .3, .07, lerp_hex(bg[1], "#000000", .15)); c.rect(.5 - .3 * c.s / c.w, .72, .5 + .3 * c.s / c.w, .78, lerp_hex(bg[1], "#ffffff", .2))
    c.ellipse(.5, .72, .3, .07, lerp_hex(bg[1], "#ffffff", .45))
    c.rect(.5 - .09 * c.s / c.w, .32, .5 + .09 * c.s / c.w, .72, prod, .04)
    c.rect(.5 - .05 * c.s / c.w, .22, .5 + .05 * c.s / c.w, .33, cap, .01)
    c.rect(.5 - .06 * c.s / c.w, .45, .5 + .06 * c.s / c.w, .56, "#ffffff", .006)
    c.glow(lambda d, c: d.rectangle([c.X(.5 - .07 * c.s / c.w), c.Y(.34), c.X(.5 - .045 * c.s / c.w), c.Y(.7)], fill=(120, 120, 120)), .01, .8)


def desk_use(c, t):
    c.vgrad("#d8d2c8", "#b8ae9e", 0, .55)
    c.rect(0, .55, 1, 1, "#9a7a5a")
    c.poly([(.25, .58), (.62, .58), (.68, .86), (.2, .86)], "#2a2e34"); c.poly([(.27, .6), (.6, .6), (.65, .83), (.23, .83)], "#6ab0e8")
    c.ellipse(.82, .72, .07, .03, "#f2efe8"); c.rect(.82 - .045 * c.s / c.w, .6, .82 + .045 * c.s / c.w, .72, "#f2efe8")
    c.ellipse(.42, .95, .12, .1, "#c88a6a")


def beauty(c, t):
    c.vgrad("#f9e1e4", "#f0c2c8")
    c.ellipse(.62, .66, .3, .06, "#e9a7b2")
    for k in range(6):
        c.line([(.2 + k * .015, .8), (.55 + k * .02, .55)], "#d56a7e", .02)
    c.rect(.3, .25, .38, .7, "#2a2226", .02); c.rect(.31, .14, .37, .26, "#c8344a", .01)
    c.circle(.7, .45, .13, "#e8d8c8"); c.circle(.7, .45, .1, "#d9a890")


def cream_detail(c, t):
    c.vgrad("#f3ece6", "#e3d6cc")
    c.circle(.5, .55, .34, "#ffffff"); c.circle(.5, .55, .3, "#f6efe8")
    for k in range(5):
        r = .05 + k * .05
        c.d.arc([c.X(.5) - c.S(r), c.Y(.55) - c.S(r), c.X(.5) + c.S(r), c.Y(.55) + c.S(r)], 20 + k * 30, 260 + k * 25, fill=rgb("#e2d4c6"), width=int(c.S(.02)))
    c.rect(.05, .1, .2, .9, "#c8a48a", .02)


def lineup(c, t):
    c.vgrad("#fff4e0", "#f2d6a8")
    c.rect(0, .7, 1, .74, "#c89a5a"); c.rect(0, .74, 1, 1, "#e8c48a")
    for i, (h, col) in enumerate([(.3, "#e0503a"), (.4, "#3a8ad0"), (.25, "#4aa86a"), (.36, "#8a5ad0"), (.28, "#f0b03a")]):
        u = .12 + i * .19
        c.rect(u - .05, .7 - h, u + .05, .7, col, .02); c.rect(u - .035, .7 - h * .6, u + .035, .7 - h * .35, "#ffffff", .005)


def product_turntable(c, t):
    c.vgrad("#1a1e28", "#303846")
    c.glow(lambda d, c: d.polygon([(c.X(.4), 0), (c.X(.6), 0), (c.X(.75), c.Y(.85)), (c.X(.25), c.Y(.85))], fill=(90, 90, 110)), .04)
    c.ellipse(.5, .82, .3, .06, "#4a5262"); c.ellipse(.5, .8, .3, .06, "#9aa2b2")
    c.rect(.5 - .12 * c.s / c.w, .38, .5 + .12 * c.s / c.w, .78, "#e8e2d8", .02)
    c.rect(.5 - .12 * c.s / c.w, .38, .5 + .12 * c.s / c.w, .46, "#e0503a", .02)


def single_product(c, t, col="#ff6a3a"):
    c.vgrad("#ffe9d6", "#ffd0b0")
    c.rect(.5 - .3 * c.s / c.w, .2, .5 + .3 * c.s / c.w, .85, "#ffffff", .03)
    c.ellipse(.5, .66, .2, .07, col); c.poly([(.5 - .2 * c.s / c.w, .66), (.5 - .1 * c.s / c.w, .45), (.5 + .14 * c.s / c.w, .5), (.5 + .2 * c.s / c.w, .66)], col)
    c.ellipse(.5, .7, .21, .03, "#f2f2f2")


def screen_ui(c, t, accent="#3a8ad0"):
    c.vgrad("#20242c", "#14171c")
    c.rect(.12, .12, .88, .78, "#0c0e12", .015); c.rect(.14, .15, .86, .75, "#f4f6f8", .008)
    c.rect(.14, .15, .86, .2, "#dfe4ea"); [c.circle(.16 + k * .02, .175, .006, col) for k, col in enumerate(["#ff5f57", "#febc2e", "#28c840"])]
    c.rect(.16, .23, .3, .72, "#e8ecf0", .005)
    for k in range(6):
        c.rect(.33, .24 + k * .075, .33 + (.5 - (k % 3) * .1), .27 + k * .075, accent if k == 2 else "#c8d0d8", .004)
    c.rect(.45, .78, .55, .86, "#0c0e12"); c.rect(.36, .86, .64, .88, "#0c0e12", .004)


def topdown_notebook(c, t):
    c.vgrad("#c8b49a", "#b09a7e")
    c.rect(.2, .15, .62, .88, "#fbf8f0", .01)
    for k in range(10):
        c.line([(.24, .25 + k * .06), (.58, .25 + k * .06)], "#c8d6e8", .003)
    for k, w in enumerate((.25, .18, .28)):
        c.circle(.26, .31 + k * .18, .018, "#e0503a"); c.line([(.3, .31 + k * .18), (.3 + w, .31 + k * .18)], "#3a3a44", .008)
    c.line([(.72, .2), (.9, .75)], "#2a5ad0", .014); c.circle(.85, .25, .07, "#6a4a3a"); c.circle(.85, .25, .055, "#3a2418")


def whiteboard(c, t):
    c.vgrad("#d8dde2", "#b8c0c8")
    c.rect(.08, .1, .92, .82, "#fbfcfd", .01, "#8a96a2", .008)
    c.rect(.15, .2, .35, .32, None, .01, "#2a5ad0", .006); c.rect(.6, .2, .82, .32, None, .01, "#e0503a", .006)
    c.rect(.38, .52, .6, .64, None, .01, "#2a9a5a", .006)
    c.line([(.35, .26), (.6, .26)], "#2a2a33", .005); c.line([(.25, .32), (.45, .52)], "#2a2a33", .005); c.line([(.71, .32), (.55, .52)], "#2a2a33", .005)
    c.line([(.15, .72), (.4, .72)], "#2a2a33", .006); c.line([(.5, .72), (.82, .72)], "#2a2a33", .006)
    c.rect(.3, .82, .7, .85, "#8a96a2")


def chart_paper(c, t):
    c.vgrad("#eef2f6", "#dfe6ee")
    c.line([(.15, .2), (.15, .8), (.85, .8)], "#3a4450", .006)
    for i, (h, col) in enumerate([(.2, "#8ab0d8"), (.32, "#8ab0d8"), (.26, "#8ab0d8"), (.46, "#e0503a"), (.38, "#8ab0d8")]):
        u = .22 + i * .12
        c.rect(u, .8 - h, u + .07, .8, col, .006)
    c.line([(.25, .55), (.37, .45), (.49, .5), (.61, .3), (.73, .36)], "#2a2a33", .006)


def lightbulb(c, t):
    c.vgrad("#ffe27a", "#ffc23a")
    c.circle(.5, .42, .18, "#fff8e0"); c.rect(.5 - .07 * c.s / c.w, .55, .5 + .07 * c.s / c.w, .7, "#5a5a66", .01)
    for k in range(12):
        a = k / 12 * math.tau
        c.line([(.5 + math.cos(a) * .24 * c.s / c.w, .42 + math.sin(a) * .24 * c.s / c.h), (.5 + math.cos(a) * .3 * c.s / c.w, .42 + math.sin(a) * .3 * c.s / c.h)], "#ffffff", .012)


def host_solid(c, t, bg="#2a7a6a", body="#123a32"):
    c.vgrad(bg, lerp_hex(bg, "#000000", .25))
    c.circle(.75, .3, .22, lerp_hex(bg, "#ffffff", .15)); c.circle(.2, .8, .16, lerp_hex(bg, "#ffffff", .1))
    c.bust(.5, .44, .1, body)


def stage_singer(c, t):
    c.vgrad("#08040e", "#1a0a2a")
    for u, col in [(.2, (180, 60, 255)), (.5, (255, 220, 160)), (.8, (60, 160, 255))]:
        c.glow(lambda d, c, u=u, col=col: d.polygon([(c.X(u - .02), 0), (c.X(u + .02), 0), (c.X(u + .25), c.Y(.9)), (c.X(u - .25), c.Y(.9))], fill=col), .03, .55)
    c.bust(.5, .5, .08, "#05030a"); c.line([(.56, .68), (.56, .95)], "#05030a", .008); c.circle(.56, .64, .025, "#2a2a33")
    c.rect(0, .92, 1, 1, "#120818")


def clouds_sky(c, t):
    c.vgrad("#7aa8e0", "#f2c8b8")
    for u, v, s in [(.3, .3, 1.0), (.7, .45, .8), (.45, .65, 1.2), (.8, .2, .6)]:
        for du, dv, r in [(-.06, 0, .07), (0, -.03, .09), (.06, 0, .07), (0, .02, .08)]:
            c.circle(u + du * s * c.s / c.w, v + dv * s, r * s, "#fbf4f0")


def news_studio(c, t):
    c.vgrad("#0a2a5a", "#05162e")
    c.circle(.5, .38, .22, "#1a4a8a"); c.circle(.5, .38, .22, None, "#5aa0ff", .004)
    for k in range(-3, 4):
        c.line([(.5 + k * .05 * c.s / c.w, .16), (.5 + k * .05 * c.s / c.w, .6)], "#3a7ad8", .002)
        c.line([(.5 - .22 * c.s / c.w, .38 + k * .05), (.5 + .22 * c.s / c.w, .38 + k * .05)], "#3a7ad8", .002)
    c.rect(.1, .2, .26, .4, "#123a6e", .01); c.rect(.74, .2, .9, .4, "#123a6e", .01)
    c.poly([(.1, .7), (.9, .7), (1, 1), (0, 1)], "#dfe6ee"); c.rect(.1, .68, .9, .72, "#c8102e")


def map_pins(c, t):
    c.vgrad("#e8eef2", "#d8e2e8")
    c.poly([(.1, .3), (.35, .2), (.55, .28), (.6, .5), (.45, .7), (.2, .65)], "#cfe0c8")
    c.poly([(.62, .18), (.9, .25), (.88, .6), (.68, .55)], "#cfe0c8")
    c.line([(0, .45), (.3, .5), (.7, .35), (1, .4)], "#ffffff", .012)
    c.line([(.2, 0), (.35, .5), (.4, 1)], "#ffffff", .01)
    for u, v in [(.34, .42), (.76, .38)]:
        c.circle(u, v - .06, .035, "#e0302a"); c.poly([(u - .025 * c.s / c.w, v - .05), (u + .025 * c.s / c.w, v - .05), (u, v)], "#e0302a"); c.circle(u, v - .06, .012, "#ffffff")


def mic_podcast(c, t, body="#2a2238", wall="#3a2e4a"):
    c.vgrad(wall, lerp_hex(wall, "#000000", .3))
    for k in range(8):
        for j in range(5):
            c.rect(.62 + k * .045, .1 + j * .09, .655 + k * .045, .18 + j * .09, lerp_hex(wall, "#000000", .15 + (k + j) % 2 * .1), .004)
    c.bust(.38, .44, .09, body)
    c.line([(.38, .62), (.52, .5), (.58, .58)], "#14101c", .01)
    c.rect(.54, .52, .62, .68, "#1a1622", .03)
    c.d.arc([c.X(.38) - c.S(.11), c.Y(.44) - c.S(.12), c.X(.38) + c.S(.11), c.Y(.44) + c.S(.06)], 180, 360, fill=rgb("#14101c"), width=int(c.S(.02)))


def phone_stand(c, t):
    c.vgrad("#f0f2f4", "#d4d8de")
    c.rect(.5 - .13 * c.s / c.w, .15, .5 + .13 * c.s / c.w, .78, "#16181c", .03)
    c.rect(.5 - .115 * c.s / c.w, .18, .5 + .115 * c.s / c.w, .75, "#3a6ad0", .02)
    c.glow(lambda d, c: d.ellipse([c.X(.5) - c.S(.08), c.Y(.35), c.X(.5) + c.S(.08), c.Y(.55)], fill=(160, 100, 255)), .05)
    c.ellipse(.5, .84, .22, .04, "#b8bec6")


def macro_ports(c, t):
    c.vgrad("#2a2e34", "#3c4148")
    c.rect(0, .35, 1, .65, "#8a9098"); c.rect(0, .35, 1, .38, "#c8ced6")
    for u, w in [(.25, .1), (.45, .06), (.6, .14)]:
        c.rect(u, .46, u + w, .54, "#16181c", .015)
    c.circle(.82, .5, .03, "#16181c")


def unboxing(c, t):
    c.vgrad("#e6d8c4", "#cdb89c")
    c.poly([(.25, .45), (.75, .45), (.72, .85), (.28, .85)], "#b8875a")
    c.poly([(.25, .45), (.5, .45), (.42, .3), (.15, .32)], "#d4a272"); c.poly([(.5, .45), (.75, .45), (.85, .32), (.58, .3)], "#c8965f")
    c.rect(.38, .38, .62, .5, "#f8f8f8", .01)
    c.rect(.47, .45, .53, .85, "#e8d0a8")


def headphones(c, t, col):
    c.vgrad(lerp_hex(col, "#ffffff", .75), lerp_hex(col, "#ffffff", .55))
    c.d.arc([c.X(.5) - c.S(.26), c.Y(.5) - c.S(.3), c.X(.5) + c.S(.26), c.Y(.5) + c.S(.22)], 180, 360, fill=rgb(col), width=int(c.S(.05)))
    for s in (-1, 1):
        c.rect(.5 + s * .26 * c.s / c.w - .07 * c.s / c.w, .42, .5 + s * .26 * c.s / c.w + .07 * c.s / c.w, .66, col, .04)


def podium_123(c, t):
    c.vgrad("#2a1a4a", "#4a2a7a")
    c.bokeh(12, ["#ffd36b", "#ff8ad0"], .01, .03, 0, .5, .8)
    for u, h, col, n in [(.3, .2, "#c0c8d8", 2), (.5, .3, "#f2c03a", 1), (.7, .14, "#d08a4a", 3)]:
        c.rect(u - .09, .85 - h, u + .09, .85, col, .006)
        c.circle(u, .85 - h - .07, .045, "#ffffff")
    c.rect(0, .85, 1, 1, "#1a1030")


def flower_vase(c, t):
    c.vgrad("#e8efe6", "#cfdccb")
    c.rect(.43, .5, .57, .85, "#5a8aa8", .04)
    for u, v, col in [(.4, .3, "#f2a0b0"), (.55, .25, "#ffd36b"), (.5, .38, "#f07a6a"), (.62, .36, "#f2a0b0")]:
        c.line([(.5, .5), (u, v)], "#4a7a4a", .008); c.circle(u, v, .06, col); c.circle(u, v, .02, "#ffffff")
    c.rect(0, .85, 1, 1, "#b8a890")


def petals(c, t):
    c.vgrad("#fbe4e8", "#f2c4cc")
    for k in range(10):
        a = k / 10 * math.tau
        c.ellipse(.5 + math.cos(a) * .2 * c.s / c.w, .5 + math.sin(a) * .2, .12, .07, "#f6a6b6" if k % 2 else "#f3b8c4")
    c.circle(.5, .5, .1, "#ffd36b")


def morning_window(c, t):
    c.vgrad("#f6efe2", "#e6d6c0")
    c.rect(.15, .1, .62, .62, "#cfe6f5"); c.rect(.37, .1, .4, .62, "#f6efe2"); c.rect(.15, .34, .62, .37, "#f6efe2")
    c.glow(lambda d, c: d.rectangle([c.X(.15), c.Y(.1), c.X(.62), c.Y(.62)], fill=(80, 70, 40)), .06)
    c.rect(0, .7, 1, 1, "#c8a882")
    c.rect(.72, .48, .84, .7, "#c86a4a", .02)
    for k in range(7):
        a = -math.pi / 2 + (k - 3) * .35
        c.ellipse(.78 + math.cos(a) * .06 * c.s / c.w, .42 + math.sin(a) * .1, .03, .06, "#4a8a4a")
    c.ellipse(.3, .8, .06, .025, "#ffffff"); c.rect(.3 - .04 * c.s / c.w, .72, .3 + .04 * c.s / c.w, .8, "#ffffff")


def lake_mountains(c, t):
    c.vgrad("#9cc6e8", "#e8f2f6", 0, .55)
    c.poly([(0, .55), (.2, .25), (.35, .4), (.55, .15), (.8, .42), (1, .3), (1, .55)], "#6a86a2")
    c.poly([(.15, .32), (.2, .25), (.25, .31)], "#f4f8fb"); c.poly([(.5, .22), (.55, .15), (.6, .21)], "#f4f8fb")
    c.vgrad("#5a86a8", "#2a4a6a", .55, 1)
    c.ridge(.6, .01, 2, "#2a5a3a")


def road_trip(c, t):
    c.vgrad("#ffc89a", "#ffe8c8", 0, .5)
    c.circle(.5, .45, .12, "#fff4d8")
    c.ridge(.5, .02, 1.2, "#c88a6a")
    c.rect(0, .5, 1, 1, "#d8b07a")
    c.poly([(.47, .5), (.53, .5), (.9, 1), (.1, 1)], "#4a4a52")
    for k in range(5):
        v = .55 + k * .09
        c.rect(.495 - k * .004, v, .505 + k * .004, v + .03 + k * .01, "#fff4d8")


def forest_path(c, t):
    c.vgrad("#d8ead0", "#a8c8a0")
    for k in range(9):
        u = .05 + k * .115; w = .025 + (k % 3) * .01
        c.rect(u - w, 0, u + w, .9, "#4a3a2a")
        c.circle(u, .15 + (k % 2) * .08, .14, ["#3a7a4a", "#4a8a5a", "#2a6a3a"][k % 3])
    c.poly([(.45, .6), (.55, .6), (.75, 1), (.25, 1)], "#c8b08a")


def sunset_sea(c, t):
    c.vgrad("#3a2a5a", "#ff9a6a", 0, .6)
    c.circle(.5, .6, .12, "#ffd89a")
    c.vgrad("#c86a5a", "#2a2a4a", .6, 1)
    for k in range(8):
        v = .63 + k * .045
        c.rect(.5 - .1 + k * .005, v, .5 + .1 - k * .005, v + .008, "#ffc89a")


def speed_motion(c, t):
    c.vgrad("#1a1a22", "#3a3a4a")
    for k in range(40):
        v = c.r.random(); u = c.r.random()
        c.line([(u, v), (u + .3 + c.r.random() * .3, v)], c.r.choice(["#ff3a6a", "#ffd23a", "#ffffff", "#3ad0ff"]), .004 + c.r.random() * .006)
    c.ellipse(.5, .6, .18, .06, "#ff3a6a"); c.ellipse(.5, .66, .2, .025, "#ffffff")


def sneakers(c, t):
    c.vgrad("#d0f04a", "#a8d82a")
    for s, v in ((1, .4), (-1, .68)):
        c.poly([(.22, v + .08), (.3, v - .06), (.48, v - .04), (.62, v + .02), (.78, v + .04), (.78, v + .1), (.22, v + .1)], "#ffffff")
        c.rect(.22, v + .09, .78, .12 + v, "#1a1a1a", .01)
        c.line([(.36, v - .03), (.5, v)], "#ff3a6a", .012)


def curtains_soft(c, t):
    c.vgrad("#fff4ea", "#f2dccc")
    c.glow(lambda d, c: d.rectangle([c.X(.3), 0, c.X(.7), c.Y(1)], fill=(80, 60, 30)), .08)
    for k in range(6):
        c.rect(k * .045, 0, k * .045 + .03, 1, "#f6e2d4"); c.rect(1 - k * .045 - .03, 0, 1 - k * .045, 1, "#f6e2d4")
    c.ellipse(.5, .9, .4, .08, "#e6cdb8")


def soft_bust(c, t):
    c.vgrad("#f6e6da", "#e8cdbb")
    c.glow(lambda d, c: d.ellipse([c.X(.1), c.Y(-.2), c.X(.9), c.Y(.6)], fill=(70, 50, 20)), .1)
    c.bust(.5, .42, .1, "#a8806e")


def picnic(c, t):
    c.vgrad("#bfe0f2", "#eaf6fb", 0, .45)
    c.ridge(.45, .02, 1, "#8ac07a")
    c.rect(0, .48, 1, 1, "#7ab86a")
    c.poly([(.25, .65), (.75, .62), (.85, .9), (.15, .92)], "#e0503a")
    for k in range(4):
        c.line([(.25 + k * .13, .64), (.15 + k * .23, .92)], "#ffffff", .006)
    c.rect(.45, .68, .58, .78, "#c8965f", .01); c.circle(.68, .74, .03, "#e0302a")


def desk_topdown(c, t):
    c.vgrad("#d8c8b0", "#c4b090")
    c.rect(.18, .2, .6, .62, "#2a2e34", .015); c.rect(.2, .23, .58, .59, "#8ac0e8", .008)
    c.rect(.2, .66, .58, .82, "#e8e8ea", .01)
    for k in range(3):
        for j in range(10):
            c.rect(.21 + j * .036, .68 + k * .045, .24 + j * .036, .71 + k * .045, "#c8c8cc", .002)
    c.circle(.78, .35, .08, "#ffffff"); c.circle(.78, .35, .06, "#6a4030")
    c.ellipse(.8, .75, .05, .1, "#4a8a4a")


def desk_host(c, t):
    c.vgrad("#e6e0d6", "#cfc6b8")
    c.rect(.1, .15, .3, .45, "#a8c8a0", .01)
    c.bust(.5, .38, .09, "#3a3530")
    c.rect(0, .7, 1, 1, "#8a6a4a")
    c.poly([(.36, .7), (.64, .7), (.62, .56), (.38, .56)], "#2a2e34")
    c.circle(.8, .66, .04, "#ffffff")


def street_interview(c, t):
    street_day(c, t)
    c.bust(.42, .46, .1, "#3a3f4a")
    c.line([(.62, .9), (.56, .62)], "#1a1a1a", .012); c.circle(.555, .6, .03, "#e0302a")


def desert_dunes(c, t):
    c.vgrad("#f2c48a", "#fbe6c6", 0, .6)
    c.circle(.22, .2, .07, "#fff4dc")
    c.poly([(0, .9), (.35, .52), (.6, .46), (1, .3), (1, 1), (0, 1)], "#d89a5a")
    c.poly([(.35, .52), (.6, .46), (1, .3), (1, .42), (.62, .6)], "#b8783e")
    c.poly([(0, 1), (.0, .82), (.5, .9), (1, .7), (1, 1)], "#c88648")
    c.ellipse(.6, .405, .008, .01, "#3a2414"); c.rect(.594, .413, .606, .455, "#3a2414")
    for k in range(5):
        c.circle(.56 - k * .045, .47 + k * .018, .004, "#a8683a")


def host_board(c, t):
    c.vgrad("#d8d0c4", "#bfb4a4")
    c.rect(.42, .1, .95, .66, "#1f3a2e", .01, "#6a4a2a", .012)
    for k, w in enumerate((.3, .22, .36, .18)):
        c.line([(.47, .2 + k * .1), (.47 + w, .2 + k * .1)], "#e8efe6", .006)
    c.circle(.86, .5, .05, None, "#e8efe6", .005)
    c.rect(0, .82, 1, 1, "#8a7a64")
    c.bust(.26, .44, .1, "#2a2420")


def interview_set(c, t):
    c.vgrad("#14161c", "#22262e")
    c.glow(lambda d, c: d.ellipse([c.X(.2), c.Y(.05), c.X(.8), c.Y(.75)], fill=(70, 60, 50)), .12)
    for k in range(7):
        c.rect(.05 + k * .13, .12, .1 + k * .13, .55, "#1c2028", .01)
    c.rect(0, .78, 1, 1, "#2a2420")
    c.bust(.28, .42, .085, "#0c0d10"); c.bust(.72, .44, .08, "#0c0d10")
    c.ellipse(.5, .8, .16, .03, "#5a4a3a"); c.rect(.49, .8, .51, .92, "#3a3028")
    c.circle(.5, .76, .02, "#e8e2d8")


SCENES = {k: v for k, v in globals().items() if callable(v) and not k.startswith("_")
          and getattr(v, "__module__", None) == __name__
          and k not in ("rgb", "lerp", "lerp_hex", "Canvas", "draw")}


def draw(scene, w, h, seed, **kw):
    c = Canvas(w, h, seed)
    SCENES[scene](c, 0.0, **kw)
    return c.result(w, h)
