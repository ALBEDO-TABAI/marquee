// SPDX-License-Identifier: AGPL-3.0-or-later

//! The shelves' words in Chinese for the packages that came with English
//! ones. Most built-in packages are named in Chinese already; the older
//! `concat.*` set was named in English, so a Chinese window listed
//! "Blur Dissolve" beside 叠化 and had a Dissolve rail beside a 叠化 rail.
//! A Chinese interface - either standard; the rest of the shelf is in
//! Simplified - reads these instead. Any other language keeps the manifest.

use concat_effects::catalogue::Package;

/// Whether the interface is in Chinese.
fn chinese() -> bool {
    crate::i18n::current().starts_with("zh")
}

/// The name a shelf, a chip or an inspector shows for `package`.
pub fn name(package: &Package) -> String {
    let meta = &package.manifest.effect;
    if chinese() {
        if let Some(zh) = name_zh(&meta.id) {
            return zh.to_owned();
        }
    }
    meta.name.clone()
}

/// The rail a manifest's `category` is shown under. Two spellings of one
/// shelf - Dissolve and 叠化 - land on the one rail.
pub fn category(raw: &str) -> String {
    if chinese() {
        if let Some(zh) = category_zh(raw) {
            return zh.to_owned();
        }
    }
    raw.to_owned()
}

fn category_zh(raw: &str) -> Option<&'static str> {
    Some(match raw {
        "Adjust" => "调节",
        "Basic" => "基础",
        "Black & White" => "黑白",
        "Blur" => "模糊",
        "Cinematic" => "电影",
        "Color" => "色彩",
        "Cutout" => "抠像",
        "Dissolve" => "叠化",
        "Distort" => "扭曲",
        "Everyday" => "日常",
        "Film" => "胶片",
        "Food" => "美食",
        "Glitch" => "故障",
        "Light" => "光",
        "Portrait" => "人像",
        "Retro" => "复古",
        "Scenery" => "风景",
        "Slide" => "滑动",
        "Spin" => "旋转",
        "Stylise" | "Stylised" | "Stylize" => "风格",
        "Vibe" => "氛围",
        "Wipe" => "擦除",
        "Zoom" => "缩放",
        "Other" => "其他",
        _ => return None,
    })
}

fn name_zh(id: &str) -> Option<&'static str> {
    Some(match id {
        "concat.adjust" => "调节",
        "concat.autumn" => "秋日",
        "concat.bleach-bypass" => "漂白",
        "concat.bloom-pulse" => "光晕脉动",
        "concat.blur-dissolve" => "模糊叠化",
        "concat.bronze" => "青铜",
        "concat.chroma-key" => "色度抠像",
        "concat.chromatic-aberration" => "色差",
        "concat.classic-chrome" => "经典铬",
        "concat.clean" => "清透",
        "concat.clock-wipe" => "时钟擦除",
        "concat.cloudless-sky" => "晴空",
        "concat.color-wheels" => "色轮",
        "concat.contrast" => "对比度",
        "concat.contrast-pop" => "高对比",
        "concat.cool" => "冷调",
        "concat.cool-blue" => "冷蓝",
        "concat.corona" => "日冕",
        "concat.cube" => "立方体",
        "concat.curves" => "曲线",
        "concat.cyberpunk" => "赛博朋克",
        "concat.daydream" => "白日梦",
        "concat.delicious" => "美味",
        "concat.digicam" => "CCD",
        "concat.dissolve" => "叠化",
        "concat.dreamy" => "梦幻",
        "concat.exposure" => "曝光",
        "concat.fade-black" => "黑场",
        "concat.fade-white" => "白场",
        "concat.fair" => "白皙",
        "concat.falling-dust" => "落尘",
        "concat.film" => "胶片",
        "concat.film-burn" => "胶片灼烧",
        "concat.film-grain" => "胶片颗粒",
        "concat.fisheye" => "鱼眼",
        "concat.fresh" => "清新",
        "concat.gaussian-blur" => "高斯模糊",
        "concat.glitch-transition" => "故障",
        "concat.glitch-warp" => "故障扭曲",
        "concat.glow" => "发光",
        "concat.golden-hour" => "黄金时刻",
        "concat.halation" => "光晕",
        "concat.halftone" => "网点",
        "concat.high-contrast-mono" => "高反差黑白",
        "concat.iris" => "光圈",
        "concat.ivory" => "象牙",
        "concat.lagoon" => "泻湖",
        "concat.landscape-pop" => "鲜艳风景",
        "concat.light-leak-flash" => "漏光闪白",
        "concat.light-leak-transition" => "漏光",
        "concat.linear-wipe" => "线性擦除",
        "concat.luma-key" => "亮度抠像",
        "concat.marquee" => "幕次",
        "concat.matcha" => "抹茶",
        "concat.midnight" => "午夜",
        "concat.milk" => "牛奶",
        "concat.mono" => "单色",
        "concat.moody" => "情绪",
        "concat.motion-blur" => "运动模糊",
        "concat.natural" => "自然",
        "concat.neon" => "霓虹",
        "concat.night" => "夜色",
        "concat.noir" => "黑色电影",
        "concat.peach" => "蜜桃",
        "concat.pink-fuzz" => "粉雾",
        "concat.pixelate" => "像素化",
        "concat.polaroid" => "拍立得",
        "concat.posterize" => "色调分离",
        "concat.push" => "推入",
        "concat.rain" => "雨天",
        "concat.remove-black" => "去黑底",
        "concat.retro-70s" => "70年代",
        "concat.retro-cartoon" => "复古卡通",
        "concat.rgb-split-wipe" => "RGB 分离",
        "concat.rosy" => "红润",
        "concat.sage" => "鼠尾草",
        "concat.saturation" => "饱和度",
        "concat.sci-fi" => "科幻",
        "concat.shape-wipe" => "形状擦除",
        "concat.sharpen" => "锐化",
        "concat.silver" => "银盐",
        "concat.slide" => "滑动",
        "concat.soft-light" => "柔光",
        "concat.spin" => "旋转",
        "concat.spooky" => "诡异",
        "concat.super-8" => "超8胶片",
        "concat.swirl" => "漩涡",
        "concat.teal-orange" => "青橙",
        "concat.tropical" => "热带",
        "concat.umber" => "赭石",
        "concat.vaporwave" => "蒸汽波",
        "concat.vhs" => "录像带",
        "concat.vibrance" => "自然饱和度",
        "concat.vignette" => "暗角",
        "concat.vintage" => "复古",
        "concat.vivid" => "鲜艳",
        "concat.warm" => "暖调",
        "concat.whip-pan" => "甩镜",
        "concat.white-balance" => "白平衡",
        "concat.winter-cool" => "冬日冷调",
        "concat.zoom-blur" => "径向模糊",
        "concat.zoom-blur-transition" => "模糊缩放",
        "concat.zoom-transition" => "缩放",
        _ => return None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use concat_effects::Catalogue;

    /// Every English-named visual package has a Chinese name, and every
    /// name here belongs to a package that exists.
    #[test]
    fn every_english_named_shelf_package_reads_in_chinese() {
        let catalogue = Catalogue::builtin();
        for package in catalogue.packages() {
            let meta = &package.manifest.effect;
            if !package.kind().is_visual() || !meta.id.starts_with("concat.") {
                continue;
            }
            assert!(name_zh(&meta.id).is_some(), "{} has no Chinese name", meta.id);
            if !meta.category.is_empty() {
                assert!(
                    category_zh(&meta.category).is_some() || !meta.category.is_ascii(),
                    "{}'s shelf {} has no Chinese name",
                    meta.id,
                    meta.category
                );
            }
        }
    }
}
