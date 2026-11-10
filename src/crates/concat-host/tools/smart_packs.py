"""Writes the built-in smart packs' treatments and preview art.

    python3 tools/smart_packs.py          # from crates/concat-host

Each pack keeps its slots, media and music; what lies over the pictures
- its titles, 花字, 人名条, 章节卡, cards, stickers, looks and transitions -
is rebuilt here from the recipe its note promises, and each picture slot
gets a drawn stand-in of the shot it asks for (pack_art.py), written to
`preview/<media id>.jpg` for the poster and hover. Then regenerate the
posters with `cargo test -p concat-host --lib write_builtin_posters --
--ignored`.
"""
import copy
import json
import zlib
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import pack_art  # noqa: E402

PACKS = os.path.join(os.path.dirname(__file__), "..", "smart-packs")
CJK = "Noto Sans CJK SC"


class Pack:
    def __init__(self, doc):
        self.doc = doc
        v = doc["video"]
        self.w, self.h = v["width"], v["height"]
        self.tall = self.h > self.w
        self.clips = []
        self.n = 0

    # sizes: fractions of frame height, as titles and shapes take them
    def fs(self, k):
        # Recipes are written at a card's reading size; the type is set
        # 1.45 times that, which is what reads on a 480px poster.
        return round(k * 1.45 * (0.6 if self.tall else 1.0), 4)

    def wu(self, frac):  # a fraction of frame width, in frame heights
        return round(frac * self.w / self.h, 4)

    def _id(self, stem):
        self.n += 1
        return f"c-{stem}{self.n}"

    def base(self, cid, track, kind, start, dur, x=0.0, y=0.0, **kw):
        clip = {"id": cid, "trackId": track, "mediaId": "", "name": kw.pop("name", cid), "kind": kind,
                "start": start, "duration": dur, "sourceStart": 0.0, "volume": 1.0, "fadeIn": 0.0,
                "fadeOut": 0.0, "scale": kw.pop("scale", 1.0), "offsetX": x, "offsetY": y,
                "rotation": kw.pop("rotation", 0.0), "opacity": kw.pop("opacity", 1.0), "speed": 1.0,
                "preservePitch": True, "filters": [], "videoEffects": kw.pop("effects", [])}
        anim = kw.pop("anim", None)
        if anim:
            clip["anim"] = anim
        clip.update(kw)
        self.clips.append(clip)
        return clip

    def text(self, content, x, y, size, color="#FFFFFF", start=0.0, dur=7.0, cid=None, name="文字", font=CJK,
             weight=700, align="center", bg="", pad=(0.0315, 0.018), radius=0.0135, stroke=None, finish=None,
             shadow=False, tracking=0.0, italic=False, rotation=0.0, anim=("fade", 0.4), track="T2", **kw):
        style = {"align": align, "background": bg, "backgroundPaddingX": pad[0], "backgroundPaddingY": pad[1],
                 "backgroundRadius": radius, "color": color, "content": content, "fontFamily": font,
                 "fontSize": self.fs(size), "fontWeight": float(weight), "italic": italic, "lineHeight": 1.2,
                 "maxHeight": 0.0, "maxWidth": 0.0, "opacity": 1.0, "shadow": shadow, "strikethrough": False,
                 "strokeColor": stroke[0] if stroke else "#000000",
                 # recipes give stroke and tracking as shares of the type
                 # size; the style takes both in frame heights
                 "strokeWidth": round(stroke[1] * self.fs(size), 4) if stroke else 0.0,
                 "underline": False, "tracking": round(tracking * self.fs(size), 4)}
        if finish:
            style["finish"] = finish
        # Overlays blend in linear light, where a half-black bar reads at a
        # third: a translucent ground is kept at 80% or more.
        if len(bg) == 9 and int(bg[7:], 16) < 0xCC:
            style["background"] = bg[:7] + "CC"
        a = {"intro": anim[0], "introSecs": anim[1], "outro": "fade", "outroSecs": 0.3} if anim else None
        return self.base(cid or self._id("t"), track, "text", start, dur, x, y, name=name, text=style,
                         rotation=rotation, anim=a, **kw)

    def shape(self, kind, x, y, width, height=0.0, fill="#FFFFFF", start=0.0, dur=7.0, radius=0.0, stroke="",
              stroke_width=0.0, name="形状", anim=("fade", 0.3), rotation=0.0, opacity=1.0, track="T6", **extra):
        style = {"kind": kind, "width": round(width, 4), "fill": fill, "stroke": stroke,
                 "strokeWidth": stroke_width, "sides": extra.pop("sides", 6), "points": extra.pop("points", 5),
                 "innerRadius": extra.pop("inner", 0.5), "trimStart": 0.0, "trimEnd": 1.0}
        if height:
            style["height"] = round(height, 4)
        if len(fill) == 9 and int(fill[7:], 16) < 0xE0:
            style["fill"] = fill[:7] + "E0"
        if radius:
            style["cornerRadius"] = radius
        style.update(extra)
        a = {"intro": anim[0], "introSecs": anim[1], "outro": "fade", "outroSecs": 0.3} if anim else None
        return self.base(self._id("s"), track, "shape", start, dur, x, y, name=name, shape=style,
                         rotation=rotation, opacity=opacity, anim=a)

    def layer(self, effect, start=0.0, dur=7.0, x=0.0, y=0.0, scale=1.0, opacity=1.0, cid=None, name="特效"):
        return self.base(cid or self._id("l"), "T3", "layer", start, dur, x, y, name=name, scale=scale,
                         opacity=opacity, effects=[{"enabled": True, "id": effect, "params": {}}])

    def sticker(self, effect, x, y, scale=0.2):
        return self.layer(effect, 0.0, self.seconds, x, y, scale, cid="c-sticker", name="贴纸")

    def transition(self, effect, at, dur=0.8):
        return self.base(self._id("tr"), "T4", "transition", at - dur / 2, dur, name="转场",
                         effects=[{"enabled": True, "id": effect, "params": {}}])

    # ------------------------------------------------------------ blocks
    def title(self, content, y=-0.34, size=0.062, **kw):
        kw.setdefault("dur", 3.4)
        clip = self.text(content, kw.pop("x", 0.0), y, size, cid="c-title", name="标题", **kw)
        # a title leads without filling the frame: 7% of its height at most
        clip["text"]["fontSize"] = min(clip["text"]["fontSize"], 0.07)
        return clip

    def caption(self, content, y=0.39, start=0.8, dur=None, bg="#00000080", color="#F6F1EA"):
        return self.text(content, 0.0, y, 0.036, color, start, dur or self.seconds - start, cid="c-cap",
                         name="字幕", weight=500, bg=bg, anim=("fade", 0.25))

    def name_strip(self, name, role, x, y, accent, start=0.5, dur=3.0, side=1):
        bw, bh = self.wu(0.27 if not self.tall else 0.64), 0.12 * (0.62 if self.tall else 1)
        self.shape("square", x, y, bw, bh, "#101418E6", start, dur, radius=0.12, name="人名条底", anim=("slideRight", 0.35))
        self.shape("square", x - side * (bw / 2) * self.h / self.w, y, 0.012, bh, accent, start, dur, name="人名条色块",
                   anim=("slideRight", 0.35))
        self.text(name, x, y - bh * 0.18, 0.034, "#FFFFFF", start + 0.1, dur - 0.1, name="人名", anim=("slideRight", 0.35))
        self.text(role, x, y + bh * 0.24, 0.02, accent, start + 0.15, dur - 0.15, name="头衔", weight=500,
                  anim=("slideRight", 0.35), tracking=0.06)

    def chapter(self, number, label, start, dur, accent, x=None, y=0.0):
        x = -0.24 if x is None and not self.tall else (x or 0.0)
        self.shape("square", x, y, self.wu(0.34 if not self.tall else 0.8), 0.24 * (0.62 if self.tall else 1),
                   "#0C0F14D9", start, dur, radius=0.06, name="章节卡底", anim=("slideRight", 0.4))
        self.text(number, x, y - 0.05 * (0.62 if self.tall else 1), 0.1, accent, start + 0.1, dur - 0.1,
                  font="Bebas Neue", weight=400, name="章节号", anim=("slideUp", 0.4))
        self.text(label, x, y + 0.06 * (0.62 if self.tall else 1), 0.038, "#FFFFFF", start + 0.2, dur - 0.2,
                  name="章节名", anim=("fade", 0.4), tracking=0.08)

    def price(self, amount, x, y, start=0.4, dur=None):
        dur = dur or self.seconds - start
        self.shape("star", x, y, 0.26, 0.0, "#E8352A", start, dur, points=14, inner=0.82, name="价格角标",
                   anim=("zoomIn", 0.35), rotation=-8)
        self.text("到手价", x, y - 0.055, 0.022, "#FFE9A8", start, dur, weight=600, rotation=-8, anim=("zoomIn", 0.35))
        self.text(amount, x, y + 0.012, 0.062, "#FFFFFF", start, dur, font="Anton", weight=400, rotation=-8,
                  anim=("zoomIn", 0.35))

    def hot(self, word, x, y, color, ink="#1A1A1A", rotation=-7, start=0.6, dur=2.6, size=0.05):
        self.text(word, x, y, size, ink, start, dur, bg=color, pad=(0.024, 0.012), radius=0.02,
                  rotation=rotation, name="热词", anim=("zoomIn", 0.3))

    def list3(self, items, x, y, accent, start=0.6, step=0.25, color="#FFFFFF", gap=0.085):
        g = gap * (0.62 if self.tall else 1)
        for i, item in enumerate(items):
            yy = y + (i - 1) * g
            self.shape("circle", x, yy, 0.05 * (0.62 if self.tall else 1), 0.0, accent, start + i * step, 4.0,
                       name="序号", anim=("zoomIn", 0.25))
            self.text(str(i + 1), x, yy, 0.03, "#FFFFFF", start + i * step, 4.0, font="Anton", weight=400,
                      anim=("zoomIn", 0.25))
            self.text(item, x + 0.04 * self.h / self.w * (1.0 if not self.tall else 0.62) + 0.01, yy, 0.036, color,
                      start + i * step, 4.0, align="left", name="列表", anim=("slideLeft", 0.3), shadow=True)

    def data_card(self, big, label, x, y, accent, start=0.8, dur=3.0, panel="#FFFFFFE6", ink="#16181C"):
        k = 0.62 if self.tall else 1
        self.shape("square", x, y, self.wu(0.2 if not self.tall else 0.5), 0.2 * k, panel, start, dur, radius=0.1,
                   name="数据卡", anim=("slideUp", 0.35))
        self.text(big, x, y - 0.025 * k, 0.09, accent, start + 0.1, dur - 0.1, font="Bebas Neue", weight=400,
                  name="数据", anim=("slideUp", 0.35))
        self.text(label, x, y + 0.06 * k, 0.024, ink, start + 0.15, dur - 0.15, weight=600, name="数据说明",
                  anim=("fade", 0.3))

    def ticker(self, label, line, accent="#C8102E", y=0.4, start=0.3):
        dur = self.seconds - start
        self.shape("square", 0.0, y, self.wu(1.0), 0.085, "#0B1830F0", start, dur, name="资讯条", anim=("slideLeft", 0.35))
        self.shape("square", -0.5 + 0.08, y, self.wu(0.16), 0.085, accent, start, dur, name="资讯条标签",
                   anim=("slideLeft", 0.35))
        self.text(label, -0.42, y, 0.034, "#FFFFFF", start, dur, weight=800, name="标签", anim=("slideLeft", 0.35))
        self.text(line, -0.3, y, 0.032, "#FFFFFF", start + 0.2, dur - 0.2, align="left", weight=500, name="资讯",
                  anim=("slideLeft", 0.4))

    def effect(self, effect, opacity=1.0, start=0.0, dur=None):
        self.layer(effect, start, dur or self.seconds, opacity=opacity)


def seconds_of(doc):
    return max(c["start"] + c["duration"] for c in doc["clips"] if c.get("mediaId"))


def look(doc, effect, which=None):
    for c in doc["clips"]:
        if c["kind"] in ("video", "image") and (which is None or c["mediaId"] in which):
            c["videoEffects"] = [{"enabled": True, "id": effect, "params": {}}]


# -------------------------------------------------------------- recipes
# Every pack: its slots' scenes, its look, and its treatment.

def ads(p):  # 价格角标 + 热词 + 硬切
    p.title("限时好价 · 今日上新", x=-0.18, y=-0.36, size=0.06, color="#FFFFFF", finish="heavy", stroke=("#E8352A", 0.12))
    p.price("¥99", 0.33, 0.12)
    p.hot("爆款", -0.32, 0.08, "#FFE14A")
    p.caption("轻薄机身 · 一只手就能握住")
    p.sticker("marquee.sk770", 0.4, -0.36)


def ads2(p):  # 柔肤滤镜 + 对话条
    p.title("油皮亲妈 · 本月空瓶", y=-0.36, size=0.054, color="#7A2E3E", font=CJK, weight=700, bg="#FFFFFFD9",
            pad=(0.03, 0.016), radius=0.04)
    p.layer("marquee.ch02", 0.6, 3.0, 0.3, -0.05, 0.22, name="对话框")
    p.text("真的不搓泥！", 0.3, -0.07, 0.034, "#FFFFFF", 0.7, 2.9, name="对话", anim=("zoomIn", 0.3))
    p.caption("上脸十秒成膜 · 一整天不暗沉", bg="#FFFFFFCC", color="#7A2E3E")
    p.sticker("marquee.sk610", -0.4, -0.34)
    look(p.doc, "marquee.skinsoft")


def ads3(p):  # 字幕条 + 热词
    p.title("直播间 · 3 号链接", x=-0.25, y=-0.38, size=0.046, color="#FFFFFF", bg="#E8352A", pad=(0.024, 0.012))
    p.shape("circle", -0.44, -0.38, 0.022, 0, "#FFFFFF", 0, 7, name="直播点", anim=None)
    p.hot("库存告急", 0.3, -0.22, "#FFE14A", rotation=6)
    p.hot("拍一发二", 0.33, 0.16, "#FF5A8A", ink="#FFFFFF", rotation=-5, start=0.9)
    p.caption("主播讲解：这款我自己回购了三次", bg="#000000B0")
    p.sticker("marquee.sk220", -0.42, 0.2)


def ads4(p):  # 三行列表 + 数据卡
    p.title("本周必买清单", x=-0.2, y=-0.36, size=0.06, color="#3A2410", finish="heavy", stroke=("#FFFFFF", 0.14))
    p.list3(["收纳盒 · 抽屉分格", "随行杯 · 保冷 12 小时", "桌面灯 · 三档色温"], -0.42, 0.06, "#E8352A",
            color="#3A2410")
    p.data_card("4.9", "好评率 98%", 0.36, 0.05, "#E8352A")
    p.caption("全部链接在评论区", bg="#3A2410CC")
    p.sticker("marquee.sk720", 0.42, -0.37)


def edu(p):  # 打字机 + 字幕条
    p.title("3 分钟搞懂 · 复利", x=-0.02, y=-0.37, size=0.056, color="#FFFFFF", anim=("slideLeft", 0.9),
            bg="#0E3A30E6", pad=(0.026, 0.014))
    p.shape("line", -0.02, -0.28, p.wu(0.3), 0, "#4AD0A0", 0.2, 3.2, stroke="#4AD0A0", stroke_width=0.006, name="下划线",
            anim=("slideLeft", 0.9))
    p.caption("钱生钱的关键，是时间而不是本金", bg="#0E3A30D0")
    p.sticker("marquee.sk140", 0.42, -0.36)


def edu2(p):  # 三行列表 + 角标
    p.title("零基础 · 剪辑入门", x=0.0, y=-0.38, size=0.05, color="#2A1A10", bg="#F6C66A", pad=(0.026, 0.014))
    p.list3(["导入素材", "粗剪排序", "加字幕导出"], -0.08, 0.02, "#E0703A", color="#2A1A10", start=0.4)
    p.shape("square", 0.42, -0.36, 0.2, 0.08, "#E0703A", 0, 7, radius=0.3, name="角标", anim=("zoomIn", .3))
    p.text("STEP 1", 0.42, -0.36, 0.032, "#FFFFFF", 0, 7, font="Bebas Neue", weight=400, tracking=0.1)
    p.caption("跟着做，十分钟出第一条片", bg="#2A1A10C0")
    p.sticker("marquee.sk220", -0.43, 0.36)


def edu3(p):  # 章节卡 + 资讯条
    p.title("白板讲解 · 供需曲线", x=0.18, y=-0.38, size=0.046, color="#2A2A40")
    p.chapter("01", "什么是均衡价格", 0.4, 3.2, "#2A5AD0", x=0.3, y=-0.08)
    p.ticker("要点", "价格上升 → 需求下降，供给上升", accent="#2A5AD0")
    p.sticker("marquee.sk450", -0.44, -0.38)


def edu4(p):  # 热词 + 倒计时
    p.title("考前速记 · 三个公式", x=-0.15, y=-0.36, size=0.054, color="#FFFFFF", finish="heavy", stroke=("#1A3A32", 0.12))
    p.shape("circle", 0.36, -0.12, 0.2, 0, "", 0, 4, stroke="#FFE14A", stroke_width=0.012, name="倒计时圈", anim=("zoomIn", .3))
    p.text("3", 0.36, -0.12, 0.07, "#FFE14A", 0, 4, font="Anton", weight=400, anim=("zoomIn", 0.3))
    p.hot("必考", 0.36, 0.14, "#FFE14A", rotation=8, start=0.8)
    p.caption("记住这一句：面积等于底乘高除二", bg="#123A32D0")
    p.sticker("marquee.sk070", -0.42, 0.34)


def fest2(p):  # 朱砂花字 + 纸屑
    p.title("新年快乐", y=-0.06, size=0.07, color="#FFE7A8", finish="drop", stroke=("#8A0F12", 0.1), anim=("zoomIn", 0.5))
    p.text("HAPPY NEW YEAR", 0.0, 0.08, 0.034, "#FFE7A8", 0.3, 3.1, font="DM Serif Display", weight=400, tracking=0.25)
    p.effect("marquee.confetti45")
    p.caption("2027 · 万事顺意", bg="#8A0F12C0", color="#FFE7A8")
    p.sticker("marquee.sk720", 0.4, -0.36)
    look(p.doc, "marquee.warm")


def fest3(p):  # 暖金标题 + 飘雪
    p.title("Merry Christmas", y=-0.3, size=0.07, color="#F4D58A", font="DM Serif Display", weight=400, italic=True,
            finish="soft", anim=("fade", 0.6))
    p.text("圣诞快乐", 0.0, -0.18, 0.04, "#FFFFFF", 0.3, 3.1, tracking=0.4)
    p.effect("marquee.snow45")
    p.effect("marquee.golddust25", 0.8)
    p.caption("今年的礼物，是和你们在一起", bg="#0B2A1ED0", color="#F4D58A")
    p.sticker("marquee.sk270", -0.42, -0.36)


def fest4(p):  # 月色滤镜 + 书法标题
    p.title("但愿人长久", x=-0.3, y=-0.12, size=0.07, color="#F6E3A1", weight=900, tracking=0.2, finish="soft",
            anim=("fade", 0.8))
    p.text("千里共婵娟", -0.3, 0.0, 0.04, "#F6E3A1", 0.5, 2.9, tracking=0.5, weight=500)
    p.shape("square", -0.3, 0.08, 0.004, 0.06, "#C8102E", 0.5, 2.9, name="印章", anim=("fade", .5))
    p.text("中秋", -0.3, 0.12, 0.024, "#FFFFFF", 0.6, 2.8, bg="#C8102E", pad=(0.012, 0.008), radius=0.004, weight=800)
    p.caption("八月十五 · 团圆", bg="#0A1430B0", color="#F6E3A1")
    p.sticker("marquee.sk120", 0.42, 0.34)
    look(p.doc, "marquee.cineice", ["slot-a"])


def festival(p):  # 贴纸 + 闪光切
    p.title("一起来过节！", y=-0.34, size=0.066, color="#FFFFFF", finish="comic", stroke=("#E0306A", 0.12),
            anim=("zoomIn", 0.4), rotation=-4)
    p.layer("marquee.stkstar", 0.3, 6.7, -0.38, 0.1, 0.22, name="涂鸦星")
    p.layer("marquee.stkheart", 0.5, 6.5, 0.38, 0.14, 0.2, name="涂鸦心")
    p.effect("marquee.sparkle45")
    p.caption("把这一天存起来", bg="#3A2450C0")
    p.sticker("marquee.sk710", 0.42, -0.36)


def film(p):  # 叠化 + 暗角 + 章节卡
    p.title("第一章 · 远方", x=0.0, y=0.3, size=0.05, color="#F6EFE6", tracking=0.4, weight=600, dur=3.4,
            anim=("fade", 1.0))
    p.text("CHAPTER ONE", 0.0, 0.21, 0.026, "#C9B79C", 0.4, 3.0, font="DM Serif Display", weight=400, tracking=0.5)
    p.effect("marquee.letterbox")
    p.effect("marquee.vignette45")
    p.sticker("marquee.sk170", 0.42, -0.3, 0.16)
    look(p.doc, "marquee.cinestill")


def film2(p):  # 急推 + 闪白 + 标题
    p.title("即将上映", y=-0.3, size=0.07, color="#FFFFFF", font=CJK, weight=900, tracking=0.3, anim=("zoomIn", 0.3),
            stroke=("#2A0F05", 0.1))
    p.text("COMING SOON", 0.0, -0.19, 0.036, "#FFB04A", 0.2, 3.0, font="Bebas Neue", weight=400, tracking=0.4)
    p.shape("line", 0, -0.14, p.wu(0.3), 0, "#FFB04A", 0.3, 3.0, stroke="#FFB04A", stroke_width=0.004, name="线")
    p.effect("marquee.speedlines45")
    p.sticker("marquee.sk370", -0.42, -0.36, 0.16)
    look(p.doc, "marquee.cineorange")


def film3(p):  # 慢叠化 + 引语卡
    p.text("“", -0.3, -0.18, 0.2, "#F2E6DA", 0.2, 6.6, font="DM Serif Display", weight=400, name="引号", anim=("fade", 0.8))
    p.title("后来我才明白，\n告别也是一种礼物。", x=-0.12, y=-0.02, size=0.05, color="#F2E6DA", weight=400,
            align="left", anim=("fade", 1.0), dur=4.0)
    p.text("— 写给夏天", 0.0, 0.16, 0.026, "#C9B7A8", 0.8, 3.2, weight=400)
    p.effect("marquee.fog25", 0.8)
    p.sticker("marquee.sk170", 0.42, 0.36, 0.16)
    look(p.doc, "marquee.fadedfilm")


def food(p):  # 暖色滤镜 + 弹出花字
    p.title("巷子里的宝藏面馆", y=-0.37, size=0.054, color="#FFF4DC", finish="heavy", stroke=("#8A3A10", 0.14))
    p.hot("一口入魂", 0.32, -0.12, "#FFB43A", ink="#5A1A00", rotation=8, start=0.5, dur=3.0, size=0.056)
    p.hot("¥18", -0.34, 0.14, "#FFFFFF", ink="#C8401A", rotation=-6, start=0.8)
    p.caption("汤头熬了八个小时，面是现拉的", bg="#5A2A10C8")
    p.sticker("marquee.sk620", 0.42, 0.3)
    look(p.doc, "marquee.foodwarm")


def game(p):  # 故障 + 急推
    p.title("五杀!!", y=-0.3, size=0.07, color="#FFE14A", font=CJK, weight=900, finish="neon", rotation=-6,
            anim=("zoomIn", 0.25))
    p.text("PENTA KILL", 0.0, -0.18, 0.036, "#FF3EC8", 0.2, 3.0, font="Black Ops One", weight=400, tracking=0.2,
           rotation=-6)
    p.data_card("12/0", "KDA", 0.38, 0.2, "#3EF0FF", panel="#0A0420D0", ink="#FFFFFF")
    p.effect("marquee.glitchslice25", 0.8, 0.0, 1.2)
    p.sticker("marquee.sk200", -0.42, 0.32)


def h169(p):  # 人名条 + 章节卡
    p.title("城市漫游 · 第 3 期", x=0.28, y=-0.38, size=0.04, color="#FFFFFF", bg="#00000066")
    p.chapter("02", "旧城的早晨", 0.3, 3.2, "#F2B03A", x=-0.26, y=-0.06)
    p.name_strip("林夏", "摄影师 · 本期向导", 0.28, 0.3, "#F2B03A")
    p.sticker("marquee.sk320", 0.43, -0.2, 0.16)


def h169cine(p):  # 宽银幕 + 叠化 + 章节卡
    p.title("THE LONG ROAD", y=0.3, size=0.05, color="#F2D8B0", font="Bebas Neue", weight=400, tracking=0.6,
            anim=("fade", 1.0))
    p.text("一 · 沙丘", 0.0, 0.22, 0.026, "#E8C8A0", 0.5, 3.0, tracking=0.6, weight=400)
    p.effect("marquee.letterbox")
    p.sticker("marquee.sk160", 0.43, -0.25, 0.16)
    look(p.doc, "marquee.tealorange")


def h169talk(p):  # 双人条 + 硬切
    p.title("对谈 · 创作这件事", x=0.0, y=-0.38, size=0.042, color="#FFFFFF", bg="#1A1E26CC")
    p.name_strip("周一", "主讲人 · 独立导演", -0.27, 0.3, "#FF8A3A", start=0.4, dur=3.4)
    p.name_strip("陈默", "嘉宾 · 剪辑师", 0.27, 0.3, "#3AB0FF", start=4.2, dur=2.6)
    p.sticker("marquee.sk060", 0.43, -0.37, 0.16)


def music(p):  # 歌词卡 + 节拍硬切
    p.title("我在晚风里等你", y=0.18, size=0.07, color="#FFFFFF", weight=500, tracking=0.2, anim=("slideUp", 0.4))
    p.text("I'll wait for you in the evening breeze", 0.0, 0.23, 0.04, "#E8C8FF", 0.3, 3.1, font="DM Serif Display",
           italic=True, weight=400)
    p.effect("marquee.audiobar45", 0.9)
    p.effect("marquee.bokeh25", 0.7)
    p.sticker("marquee.sk650", 0.36, -0.4, 0.18)


def news(p):  # 字幕条 + 左擦除
    p.title("今日快讯", x=-0.36, y=-0.38, size=0.046, color="#FFFFFF", bg="#C8102E", pad=(0.024, 0.012), weight=800)
    p.text("LIVE", -0.2, -0.38, 0.03, "#FFFFFF", 0, 7, font="Bebas Neue", weight=400, bg="#0B1830", pad=(0.014, 0.008))
    p.ticker("快讯", "城市新区地铁线今日开通，首日客流超十万人次")
    p.sticker("marquee.sk030", 0.44, -0.38, 0.16)


def pack_vertical(p):  # 三镜位 + 标题 + 字幕 + 贴纸 + 转场
    p.title("周末去海边", y=-0.36, size=0.07, color="#FFFFFF", finish="drop", stroke=("#2A6AA8", 0.1))
    p.text("SEASIDE · WEEKEND", 0.0, -0.31, 0.034, "#FFFFFF", 0.3, 3.1, font="Bebas Neue", weight=400, tracking=0.3)
    p.caption("开场 → 主体 → 结尾空镜", y=0.4, start=0.8)
    p.sticker("marquee.sk600", 0.32, 0.22, 0.2)


def pack_wide(p):
    p.title("山与湖之间", x=-0.26, y=-0.32, size=0.064, color="#FFFFFF", finish="drop", stroke=("#2A4A6A", 0.1))
    p.text("A SHORT JOURNEY", -0.26, -0.22, 0.03, "#E8F2F6", 0.3, 3.1, font="Bebas Neue", weight=400, tracking=0.3)
    p.caption("开场 · 主体 · 结尾空镜，三镜一气呵成", start=0.8)
    p.sticker("marquee.sk540", 0.42, -0.36)


def podcast(p):  # 人名条 + 波形装饰
    p.title("不设限 · EP.27", x=0.3, y=-0.38, size=0.042, color="#FFFFFF", bg="#7A4AD0", pad=(0.024, 0.012))
    p.name_strip("阿柚", "主播", -0.3, 0.3, "#B48CFF")
    p.layer("marquee.audiowave45", 0, 7, 0, 0, 1.0, 0.85, name="波形")
    p.sticker("marquee.sk150", 0.43, 0.3, 0.16)


def review(p):  # 章节卡 + 放大入场
    p.title("新机上手 · 值不值", x=0.25, y=-0.36, size=0.05, color="#16181C", weight=800, anim=("zoomIn", 0.4))
    p.chapter("01", "外观与手感", 0.4, 3.2, "#7A4AFF", x=-0.28, y=0.0)
    p.caption("先说结论：屏幕是今年最好的", bg="#16181CC8")
    p.sticker("marquee.sk250", 0.43, 0.3, 0.18)


def review2(p):  # 角标 + 数据卡
    p.title("开箱 · 首发版", x=-0.25, y=-0.36, size=0.05, color="#3A2410", weight=800)
    p.shape("square", 0.38, -0.36, 0.22, 0.08, "#E8352A", 0, 7, radius=0.3, name="角标", anim=("zoomIn", .3))
    p.text("首发", 0.38, -0.36, 0.032, "#FFFFFF", 0, 7, weight=800)
    p.data_card("5000", "mAh 电池", 0.34, 0.08, "#E8352A")
    p.caption("盒子里：本体、线、一张说明书", bg="#3A2410C0")
    p.sticker("marquee.sk020", -0.42, 0.3, 0.18)


def review3(p):  # 左右分屏条 + 硬切
    p.shape("square", 0.0, 0.0, 0.008, 1.0, "#FFFFFF", 0, 7, name="分屏线", anim=None)
    p.text("A", -0.25, -0.34, 0.05, "#FFFFFF", 0.2, 6.8, font="Anton", weight=400, bg="#FF7A2A", pad=(0.02, 0.01))
    p.text("B", 0.25, -0.34, 0.05, "#FFFFFF", 0.2, 6.8, font="Anton", weight=400, bg="#2A7AFF", pad=(0.02, 0.01))
    p.shape("circle", 0.0, 0.0, 0.14, 0, "#16181C", 0.3, 6.7, name="VS底", anim=("zoomIn", 0.3))
    p.title("VS", y=0.0, size=0.06, color="#FFFFFF", font="Anton", weight=400, start=0.3, dur=6.7, anim=("zoomIn", 0.3))
    p.text("降噪 32dB", -0.25, 0.34, 0.032, "#FFFFFF", 0.6, 6.4, bg="#00000088")
    p.text("降噪 40dB", 0.25, 0.34, 0.032, "#FFFFFF", 0.6, 6.4, bg="#00000088")
    p.sticker("marquee.sk270", 0.43, -0.38, 0.16)


def review4(p):  # 三行列表 + 章节卡
    p.title("2026 年度好物 TOP 3", y=-0.38, size=0.05, color="#FFE27A", weight=900, finish="heavy", stroke=("#2A1A4A", 0.12))
    p.list3(["降噪耳机", "电子阅读器", "人体工学椅"], -0.36, 0.02, "#F2C03A")
    p.sticker("marquee.sk220", 0.42, 0.34, 0.2)
    p.effect("marquee.golddust25", 0.8)


def sq(p):  # 短内容包装
    p.title("今日花事", y=-0.36, size=0.064, color="#3A5A3A", weight=800)
    p.text("FLOWER NOTE · 04", 0.0, -0.28, 0.03, "#5A7A5A", 0.3, 3.1, font="DM Serif Display", weight=400, tracking=0.2)
    p.layer("marquee.ti21", 0.0, 7.0, 0, 0, 0.92, name="边框")
    p.caption("一束洋桔梗，放在窗边", bg="#3A5A3AB0")
    p.sticker("marquee.sk610", 0.38, 0.3, 0.18)


def talk(p):  # 人名条 + 字幕条 + 硬切
    p.title("为什么我辞职去开店", x=0.24, y=-0.37, size=0.048, color="#FFFFFF", finish="outline", stroke=("#000000", 0.08))
    p.name_strip("小北", "咖啡店主理人", -0.28, 0.24, "#F2B03A")
    p.caption("那天早上，我突然不想再挤地铁了", bg="#000000B0")
    p.sticker("marquee.sk020", 0.43, 0.2, 0.16)


def talk2(p):  # 打字机 + 字幕条
    p.title("一分钟讲清 · 通货膨胀", x=0.22, y=-0.36, size=0.046, color="#FFFFFF", anim=("slideLeft", 0.9))
    p.shape("line", 0.22, -0.3, p.wu(0.3), 0, "#F2B03A", 0.2, 3.2, stroke="#F2B03A", stroke_width=0.006, name="下划线",
            anim=("slideLeft", 0.9))
    p.caption("物价上涨，其实是钱变「轻」了", bg="#1A1410C8")
    p.sticker("marquee.sk370", -0.43, -0.36, 0.16)


def talk3(p):  # 热词 + 字幕条
    p.title("街头随机采访", x=-0.28, y=-0.37, size=0.05, color="#FFFFFF", bg="#E8352A", pad=(0.024, 0.012))
    p.hot("你存款多少？", 0.26, -0.18, "#FFE14A", rotation=5, start=0.3, dur=3.2)
    p.caption("受访者：“说出来你可能不信……”", bg="#000000B0")
    p.sticker("marquee.sk150", 0.42, 0.2, 0.18)


def talk4(p):  # 章节卡 + 角标
    p.title("桌面改造 · 第 2 期", x=0.26, y=-0.38, size=0.042, color="#3A3530")
    p.chapter("Part 2", "线材收纳", 0.3, 3.2, "#5A8A5A", x=-0.28, y=-0.06)
    p.shape("square", 0.42, 0.3, 0.16, 0.07, "#5A8A5A", 0, 7, radius=0.3, name="角标", anim=("zoomIn", .3))
    p.text("¥0 改造", 0.42, 0.3, 0.026, "#FFFFFF", 0, 7, weight=800)
    p.caption("只用了三根扎带", bg="#3A3530C0")
    p.sticker("marquee.sk040", -0.43, 0.34, 0.16)


def v916(p):  # 标题 + 花字 + 字幕条 + 转场
    p.title("城市散步计划", y=-0.36, size=0.07, color="#FFFFFF", finish="heavy", stroke=("#2A6AD0", 0.12))
    p.hot("周末去哪儿", 0.12, -0.27, "#FFE14A", rotation=-5, start=0.4, size=0.05)
    p.caption("从地铁口出来，往左拐", y=0.36)
    p.sticker("marquee.sk300", -0.33, 0.2, 0.2)


def v916fast(p):  # 硬切 + 热词 + 贴纸
    p.title("3 秒上脚", y=-0.34, size=0.07, color="#1A1A1A", finish="comic", stroke=("#FFFFFF", 0.14), rotation=-6,
            anim=("zoomIn", 0.25))
    p.hot("NEW!", 0.22, -0.24, "#FF3A6A", ink="#FFFFFF", rotation=10, start=0.3, size=0.06)
    p.layer("marquee.stkburst", 0.2, 6.8, -0.28, 0.25, 0.3, name="爆炸贴")
    p.sticker("marquee.sk710", 0.3, 0.3, 0.22)


def v916night(p):  # 暗角 + 霓虹花字
    p.title("凌晨两点的街", y=-0.3, size=0.07, color="#FFFFFF", finish="neon", stroke=("#FF3CB4", 0.1))
    p.text("MIDNIGHT", 0.0, -0.24, 0.04, "#3CDCFF", 0.3, 3.1, font="Bebas Neue", weight=400, tracking=0.4,
           finish="neon")
    p.effect("marquee.vignette45")
    p.caption("城市睡了，霓虹没有", y=0.36)
    p.sticker("marquee.sk010", 0.33, 0.24, 0.18)
    look(p.doc, "marquee.hkneon")


def v916soft(p):  # 叠化 + 人名条 + 暖滤
    p.title("慢一点也没关系", y=-0.34, size=0.062, color="#8A5A48", weight=500, tracking=0.15, anim=("fade", 0.8))
    p.name_strip("小满", "日常记录者", 0.0, 0.26, "#E8A07A")
    p.effect("marquee.lightleak25", 0.7)
    p.sticker("marquee.sk670", 0.32, -0.42, 0.16)
    look(p.doc, "marquee.cream")


def vlog(p):  # 花字 + 漏光转场 + 胶片颗粒
    p.title("春日出逃计划", x=-0.24, y=-0.34, size=0.064, color="#FFFFFF", finish="drop", stroke=("#E07A5A", 0.12),
            rotation=-3)
    p.text("Spring Escape", -0.2, -0.22, 0.044, "#FFF4D8", 0.3, 3.1, font="Pacifico", weight=400, rotation=-3)
    p.effect("marquee.grain25", 0.8)
    p.caption("今天的风是甜的", start=0.8)
    p.sticker("marquee.sk620", 0.42, -0.34, 0.18)
    look(p.doc, "marquee.kodak")


def vlog2(p):  # 地图角标 + 暖滤
    p.title("DAY 1 · 雪山脚下", x=-0.26, y=-0.36, size=0.054, color="#FFFFFF", finish="drop", stroke=("#2A4A6A", 0.1))
    p.shape("square", 0.33, 0.33, p.wu(0.22), 0.075, "#FFFFFFE6", 0.3, 6.7, radius=0.5, name="地点条")
    p.shape("circle", 0.33 - p.wu(0.085) * p.h / p.w, 0.33, 0.04, 0, "#E0302A", 0.3, 6.7, name="图钉")
    p.text("云南 · 玉龙雪山", 0.35, 0.33, 0.03, "#1A2A3A", 0.4, 6.6, weight=600)
    p.sticker("marquee.sk620", 0.43, -0.36, 0.16)
    look(p.doc, "marquee.goldenhr")


def vlog3(p):  # 手写花字 + 叠化
    p.title("今天也要好好吃饭", x=0.2, y=-0.33, size=0.054, color="#5A4030", weight=500, rotation=-2)
    p.text("slow morning", 0.24, -0.22, 0.048, "#C86A4A", 0.4, 3.0, font="Caveat Brush", weight=400, rotation=-4)
    p.layer("marquee.stkheart", 0.6, 6.4, 0.42, -0.36, 0.16, name="涂鸦心")
    p.caption("八点起床，泡一杯手冲", start=0.8, bg="#5A4030B0")
    p.sticker("marquee.sk660", -0.43, 0.34, 0.16)
    look(p.doc, "marquee.washi")


def vlog4(p):  # 颗粒 + 霓虹滤镜
    p.title("TOKYO NIGHT", x=-0.25, y=-0.34, size=0.064, color="#FFFFFF", font="Bebas Neue", weight=400, finish="neon",
            stroke=("#FF3CB4", 0.1), tracking=0.2)
    p.text("夜拍 · 第 7 夜", -0.25, -0.24, 0.03, "#3CDCFF", 0.3, 3.1, tracking=0.3)
    p.effect("marquee.grain45", 0.8)
    p.caption("下班后的东京，比白天更好看", start=0.8)
    p.sticker("marquee.sk150", 0.43, 0.3, 0.16)
    look(p.doc, "marquee.tokyo")


# pack -> (recipe, scenes per picture slot in order, transition or None, poster time)
SPEC = {
    "marquee-ads": (ads, ["product_podium", "desk_use"], None, 1.6),
    "marquee-ads2": (ads2, ["beauty", "cream_detail"], "marquee.cross-soft", 1.6),
    "marquee-ads3": (ads3, ["host_ringlight", "product_turntable"], None, 1.6),
    "marquee-ads4": (ads4, ["lineup", "single_product"], "marquee.slide", 1.8),
    "marquee-edu": (edu, ["host_studio", "screen_ui"], "marquee.wipe", 1.6),
    "marquee-edu2": (edu2, ["topdown_notebook", "screen_ui"], "marquee.slide", 1.6),
    "marquee-edu3": (edu3, ["whiteboard", "chart_paper"], "marquee.wipe", 1.6),
    "marquee-edu4": (edu4, ["host_solid", "lightbulb"], None, 1.6),
    "marquee-fest2": (fest2, ["lanterns_fireworks", "reunion_table"], "marquee.flashxf", 1.6),
    "marquee-fest3": (fest3, ["christmas_tree", "gifts_fireplace"], "marquee.cross-soft", 1.6),
    "marquee-fest4": (fest4, ["moon_roofline", "reunion_table"], "marquee.cross-soft", 1.8),
    "marquee-festival": (festival, ["string_lights", "party_balloons"], "marquee.flashxf", 1.6),
    "marquee-film": (film, ["dawn_landscape", "profile_rim"], "marquee.cross-soft", 1.8),
    "marquee-film2": (film2, ["action_burst", "night_road"], "marquee.dipwhite", 1.4),
    "marquee-film3": (film3, ["rain_window", "back_view_sea"], "concat.dissolve", 2.0),
    "marquee-food": (food, ["noodle_bowl", "restaurant"], "marquee.zoomxf", 1.6),
    "marquee-game": (game, ["neon_grid", "victory"], "marquee.glitchxf", 1.4),
    "marquee-h169": (h169, ["city_day", "host_studio"], "marquee.slide", 1.6),
    "marquee-h169cine": (h169cine, ["desert_dunes", "back_view_sea"], "concat.dissolve", 2.0),
    "marquee-h169talk": (h169talk, ["interview_set", "host_solid"], None, 1.6),
    "marquee-music": (music, ["stage_singer", "clouds_sky"], None, 1.6),
    "marquee-news": (news, ["news_studio", "map_pins"], "marquee.wipe", 1.6),
    "marquee-pack-vertical": (pack_vertical, ["sunset_sea", "picnic", "clouds_sky"], "marquee.slide", 1.6),
    "marquee-pack-wide": (pack_wide, ["forest_path", "lake_mountains", "sunset_sea"], "marquee.cross-soft", 1.6),
    "marquee-podcast": (podcast, ["mic_podcast", "mic_podcast"], None, 1.6),
    "marquee-review": (review, ["phone_stand", "macro_ports"], "marquee.zoomxf", 1.6),
    "marquee-review2": (review2, ["unboxing", "desk_use"], "marquee.slide", 1.6),
    "marquee-review3": (review3, ["headphones", "headphones"], None, 1.6),
    "marquee-review4": (review4, ["podium_123", "single_product"], "marquee.slide", 1.6),
    "marquee-sq": (sq, ["flower_vase", "petals"], "marquee.cross-soft", 1.6),
    "marquee-talk": (talk, ["host_studio", "city_day"], None, 1.6),
    "marquee-talk2": (talk2, ["host_board", "chart_paper"], "marquee.wipe", 1.6),
    "marquee-talk3": (talk3, ["street_interview", "street_day"], None, 1.6),
    "marquee-talk4": (talk4, ["desk_host", "desk_topdown"], "marquee.slide", 1.6),
    "marquee-v916": (v916, ["city_day", "street_day"], "marquee.slide", 1.6),
    "marquee-v916fast": (v916fast, ["sneakers", "speed_motion"], None, 1.4),
    "marquee-v916night": (v916night, ["neon_street", "city_night"], "marquee.glitchxf", 1.6),
    "marquee-v916soft": (v916soft, ["curtains_soft", "soft_bust"], "marquee.cross-soft", 1.8),
    "marquee-vlog": (vlog, ["picnic", "street_day"], "marquee.lightleakxf", 1.6),
    "marquee-vlog2": (vlog2, ["lake_mountains", "road_trip"], "marquee.slide", 1.6),
    "marquee-vlog3": (vlog3, ["morning_window", "desk_topdown"], "marquee.cross-soft", 1.6),
    "marquee-vlog4": (vlog4, ["city_night", "neon_street"], "marquee.glitchxf", 1.6),
}

SCENE_ARGS = {
    ("marquee-review3", 0): {"col": "#FF7A2A"}, ("marquee-review3", 1): {"col": "#2A7AFF"},
    ("marquee-podcast", 1): {"body": "#1a2a38", "wall": "#2a3e4a"},
    ("marquee-h169talk", 1): {"bg": "#3a4a7a", "body": "#141c38"},
    ("marquee-talk", 0): {"wall": "#5a4a3a", "body": "#2a2018"},
    ("marquee-edu", 0): {"wall": "#24343a", "body": "#0e1a1e", "lamp": False, "centre": 0.68},
    ("marquee-h169", 1): {"wall": "#4a3a5a", "body": "#1e1828", "lamp": False},
    ("marquee-edu4", 0): {"bg": "#2a7a6a", "body": "#123a32"},
    ("marquee-review4", 1): {"col": "#7a4aff"},
    ("marquee-ads4", 1): {"col": "#2a8a5a"},
}

KEEP_TRACKS = [
    {"id": "T1", "name": "V1", "visible": True, "muted": False},
    {"id": "T7", "name": "V2", "visible": True, "muted": False},
    {"id": "T6", "name": "Cards", "visible": True, "muted": False},
    {"id": "T2", "name": "Titles", "visible": True, "muted": False},
    {"id": "T3", "name": "Stickers", "visible": True, "muted": False},
    {"id": "T4", "name": "FX", "visible": True, "muted": False},
]


def preview_size(w, h):
    long = max(w, h)
    even = lambda s: max(2, round(s * 480 / long) // 2 * 2)
    return even(w), even(h)


def build(name):
    recipe, scenes, transition, poster = SPEC[name]
    path = os.path.join(PACKS, name, "template.json")
    doc = json.load(open(path))
    media_clips = [c for c in doc["clips"] if c.get("mediaId")]
    for c in media_clips:
        c["videoEffects"] = [] if c["kind"] != "audio" else c["videoEffects"]
        c.pop("crop", None)
    audio_tracks = [t for t in doc["tracks"] if t["id"] == "T5"]
    doc["tracks"] = KEEP_TRACKS + audio_tracks
    p = Pack(doc)
    p.seconds = seconds_of(doc)
    if name == "marquee-review3":  # the two products side by side, the whole way
        a, b = [c for c in media_clips if c["kind"] != "audio"]
        for clip, x, track in ((a, -0.25, "T1"), (b, 0.25, "T7")):
            clip.update(start=0.0, duration=p.seconds, offsetX=x, trackId=track,
                        crop={"left": 0.25, "top": 0.0, "right": 0.25, "bottom": 0.0})
        for m in doc["media"]:
            if m["id"] in (a["mediaId"], b["mediaId"]):
                m["duration"] = p.seconds
    recipe(p)
    if transition:
        cuts = sorted({c["start"] for c in media_clips if c["kind"] != "audio" and c["start"] > 0})
        for at in cuts:
            p.transition(transition, at)
    # A track holds one clip at a time: every overlay goes on the lowest
    # lane of its layer that is free for its span. Layers, bottom to top:
    # full-frame looks (snow, letterbox), cards and bars, titles and words,
    # stickers, transitions.
    def layer_of(clip):
        if clip["kind"] == "transition":
            return "FX"
        if clip["kind"] == "shape":
            return "Cards"
        if clip["kind"] == "text":
            return "Titles"
        if clip["id"] == "c-sticker" or clip.get("scale", 1.0) < 1.0:
            return "Stickers"
        return "Looks"
    order = ["Looks", "Cards", "Titles", "Stickers", "FX"]
    lanes = {name: [] for name in order}  # per layer: a list of lanes, each a list of spans
    for clip in p.clips:
        spans = lanes[layer_of(clip)]
        span = (clip["start"], clip["start"] + clip["duration"])
        for index, lane in enumerate(spans):
            if all(span[1] <= a + 1e-6 or span[0] >= b - 1e-6 for a, b in lane):
                lane.append(span)
                break
        else:
            index = len(spans)
            spans.append([span])
        clip["trackId"] = f"{layer_of(clip)}-{index + 1}"
    used = {c["trackId"] for c in media_clips}
    picture = [t for t in KEEP_TRACKS if t["id"] in ("T1", "T7") and (t["id"] == "T1" or "T7" in used)]
    overlay = [{"id": f"{name}-{n + 1}", "name": name if n == 0 else f"{name} {n + 1}", "visible": True,
                "muted": False} for name in order for n in range(len(lanes[name]))]
    doc["tracks"] = picture + overlay + audio_tracks
    doc["clips"] = media_clips + p.clips
    doc["marqueePack"]["posterTime"] = poster
    with open(path, "w") as f:
        json.dump(doc, f, ensure_ascii=False, indent=2)
        f.write("\n")
    # the stand-ins
    pw, ph = preview_size(p.w, p.h)
    out = os.path.join(PACKS, name, "preview")
    os.makedirs(out, exist_ok=True)
    for f in os.listdir(out):
        os.remove(os.path.join(out, f))
    slots = [s for s in doc["marqueePack"]["slots"] if not s.get("optional")
             and any(m["id"] == s["media"] and m["kind"] != "audio" for m in doc["media"])]
    for i, slot in enumerate(slots):
        scene = scenes[min(i, len(scenes) - 1)]
        art = pack_art.draw(scene, pw, ph, zlib.crc32(f"{name}{i}".encode()) & 0xFFFF, **SCENE_ARGS.get((name, i), {}))
        art.save(os.path.join(out, slot["media"] + ".jpg"), quality=86, optimize=True)


if __name__ == "__main__":
    names = sys.argv[1:] or sorted(SPEC)
    for name in names:
        build(name)
    print(f"{len(names)} packs written")
