// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Jareer Abdullah

//! A local music and sound-effect library: the Audio page's 音乐库 and
//! 音效库 shelves.
//!
//! The library is a folder on this machine - never in the repository, since
//! what is in it is somebody else's licensed catalogue - holding
//! `manifest.json` and the files it names: `music/`, `sfx/`, `covers/` and
//! `beats/`. The schema is `docs/AUDIO_LIBRARY_LOCAL.md`. Where the folder
//! is: `MARQUEE_AUDIO_LIBRARY` when it is set, or `<data>/audio-library`.
//!
//! Nothing is downloaded here: an entry whose file is not in the folder is
//! listed but cannot be played or laid down. Beside the library, in the
//! app's own config folder, `audio-mine.json` keeps the user's favourites
//! and what they used last - the 我的 shelf - by card id.

use std::collections::HashMap;
use std::path::{Component, Path, PathBuf};

use serde::{Deserialize, Serialize};

use crate::AppDirs;

/// The manifest's format.
pub const SCHEMA: &str = "marquee.audio-library/1";

/// How many sounds "Recently used" keeps.
pub const RECENT: usize = 50;

/// Which shelf: music (音乐库) or sound effects (音效库).
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub enum Kind {
    /// 音乐库: songs.
    Music,
    /// 音效库: sound effects.
    Sfx,
}

impl Kind {
    /// The prefix of a card on this shelf: `music-…`, `sfx-…`.
    pub fn prefix(self) -> &'static str {
        match self {
            Kind::Music => "music-",
            Kind::Sfx => "sfx-",
        }
    }

    /// The shelf a card is on, and the entry's id.
    pub fn of_card(card: &str) -> Option<(Kind, &str)> {
        if let Some(id) = card.strip_prefix("music-") {
            Some((Kind::Music, id))
        } else {
            card.strip_prefix("sfx-").map(|id| (Kind::Sfx, id))
        }
    }
}

/// One category of a shelf, its entries in the order the shelf shows them.
#[derive(Serialize, Deserialize, Clone, Debug, Default, PartialEq)]
pub struct Category {
    /// Stable within the manifest.
    pub id: String,
    /// What the sidebar says.
    pub name: String,
    #[serde(default)]
    /// The entries' ids, in the order shown.
    pub items: Vec<String>,
}

/// One song or one sound effect.
#[derive(Serialize, Deserialize, Clone, Debug, Default, PartialEq)]
pub struct Entry {
    /// Stable within its shelf.
    pub id: String,
    /// What the row says.
    pub title: String,
    /// The singer, the composer, or who made the effect.
    #[serde(default)]
    pub artist: String,
    /// Seconds.
    #[serde(default)]
    pub duration: f64,
    /// The file, relative to the library folder; none when it was not
    /// fetched.
    #[serde(default)]
    pub audio: Option<String>,
    /// A small square picture, relative to the library folder.
    #[serde(default)]
    pub cover: Option<String>,
    /// The song's beat grid as its source published it, relative.
    #[serde(default)]
    pub beats: Option<String>,
    /// Genres and tags, for the search.
    #[serde(default)]
    pub tags: Vec<String>,
    /// A member's item in its source catalogue.
    #[serde(default)]
    pub vip: bool,
}

/// One shelf: its categories and its entries by id.
#[derive(Serialize, Deserialize, Clone, Debug, Default, PartialEq)]
pub struct Shelf {
    #[serde(default)]
    /// The sidebar's rows, in order.
    pub categories: Vec<Category>,
    #[serde(default)]
    /// Every entry, by id.
    pub items: HashMap<String, Entry>,
}

#[derive(Deserialize)]
struct Manifest {
    #[serde(default)]
    schema: String,
    #[serde(default)]
    music: Shelf,
    #[serde(default)]
    sfx: Shelf,
}

/// The library as it is on disk.
#[derive(Clone, Debug, Default)]
pub struct AudioLibrary {
    /// The folder the manifest is in.
    pub root: PathBuf,
    /// 音乐库.
    pub music: Shelf,
    /// 音效库.
    pub sfx: Shelf,
}

/// A path the manifest gives, if it stays inside the library: relative,
/// with no `..`.
fn inside(root: &Path, relative: &str) -> Option<PathBuf> {
    let path = Path::new(relative);
    path.components()
        .all(|part| matches!(part, Component::Normal(_)))
        .then(|| root.join(path))
}

impl AudioLibrary {
    /// Where the library is looked for on this machine.
    pub fn locate(dirs: &AppDirs) -> PathBuf {
        match std::env::var_os("MARQUEE_AUDIO_LIBRARY") {
            Some(dir) if !dir.is_empty() => PathBuf::from(dir),
            _ => dirs.data.join("audio-library"),
        }
    }

    /// The library in `root`, read from its manifest. An entry a category
    /// names that is not in the manifest is dropped from the category, and
    /// any path leaving the folder is forgotten.
    pub fn open(root: &Path) -> Result<AudioLibrary, String> {
        let bytes = std::fs::read(root.join("manifest.json"))
            .map_err(|error| format!("{}: {error}", root.join("manifest.json").display()))?;
        AudioLibrary::parse(root, &bytes)
    }

    /// As [`AudioLibrary::open`], from the manifest's bytes.
    pub fn parse(root: &Path, bytes: &[u8]) -> Result<AudioLibrary, String> {
        let manifest: Manifest = serde_json::from_slice(bytes)
            .map_err(|error| format!("the audio library's list is not readable: {error}"))?;
        if manifest.schema != SCHEMA {
            return Err(format!(
                "the audio library's list is {:?}, not {SCHEMA}",
                manifest.schema
            ));
        }
        let clean = |mut shelf: Shelf| {
            for entry in shelf.items.values_mut() {
                for field in [&mut entry.audio, &mut entry.cover, &mut entry.beats] {
                    if field
                        .as_deref()
                        .is_some_and(|path| inside(root, path).is_none())
                    {
                        *field = None;
                    }
                }
                if !entry.duration.is_finite() || entry.duration < 0.0 {
                    entry.duration = 0.0;
                }
            }
            for category in &mut shelf.categories {
                let items = &shelf.items;
                category.items.retain(|id| items.contains_key(id));
            }
            shelf
        };
        Ok(AudioLibrary {
            root: root.to_owned(),
            music: clean(manifest.music),
            sfx: clean(manifest.sfx),
        })
    }

    /// One shelf of the library.
    pub fn shelf(&self, kind: Kind) -> &Shelf {
        match kind {
            Kind::Music => &self.music,
            Kind::Sfx => &self.sfx,
        }
    }

    /// The entry a card names.
    pub fn entry(&self, card: &str) -> Option<(Kind, &Entry)> {
        let (kind, id) = Kind::of_card(card)?;
        self.shelf(kind).items.get(id).map(|entry| (kind, entry))
    }

    /// The entry's sound, when it is in the folder.
    pub fn audio_of(&self, entry: &Entry) -> Option<PathBuf> {
        let path = inside(&self.root, entry.audio.as_deref()?)?;
        path.is_file().then_some(path)
    }

    /// The entry's picture, when it is in the folder.
    pub fn cover_of(&self, entry: &Entry) -> Option<PathBuf> {
        let path = inside(&self.root, entry.cover.as_deref()?)?;
        path.is_file().then_some(path)
    }

    /// The entry's beats, in seconds, when its file is there and reads.
    /// The source's format is a JSON object with `linenumber` and a
    /// `realtime` list of milliseconds (or seconds) per beat line; any list
    /// of numbers under a key holding "time" is taken.
    pub fn beats_of(&self, entry: &Entry) -> Vec<f64> {
        let Some(path) = entry.beats.as_deref().and_then(|p| inside(&self.root, p)) else {
            return Vec::new();
        };
        let Ok(bytes) = std::fs::read(path) else {
            return Vec::new();
        };
        beats_from(&bytes)
    }

    /// A shelf's entries in a category, in order; `None` for all of them,
    /// each once, in category order.
    pub fn listed(&self, kind: Kind, category: Option<usize>) -> Vec<&Entry> {
        let shelf = self.shelf(kind);
        let mut seen = std::collections::HashSet::new();
        let categories: Vec<&Category> = match category {
            Some(row) => shelf.categories.get(row).into_iter().collect(),
            None => shelf.categories.iter().collect(),
        };
        categories
            .into_iter()
            .flat_map(|category| category.items.iter())
            .filter(|id| seen.insert(id.as_str()))
            .filter_map(|id| shelf.items.get(id))
            .collect()
    }

    /// Entries of a shelf matching `query` in their title, artist or tags,
    /// case- and width-blind; the title's matches first, then the rest,
    /// each in shelf order.
    pub fn search(&self, kind: Kind, query: &str) -> Vec<&Entry> {
        let words: Vec<String> = fold(query).split_whitespace().map(str::to_owned).collect();
        if words.is_empty() {
            return self.listed(kind, None);
        }
        let mut titled = Vec::new();
        let mut other = Vec::new();
        for entry in self.listed(kind, None) {
            let title = fold(&entry.title);
            let rest = fold(&format!("{} {}", entry.artist, entry.tags.join(" ")));
            if words.iter().all(|word| title.contains(word.as_str())) {
                titled.push(entry);
            } else if words
                .iter()
                .all(|word| title.contains(word.as_str()) || rest.contains(word.as_str()))
            {
                other.push(entry);
            }
        }
        titled.extend(other);
        titled
    }
}

/// Lowercase, full-width ASCII folded to half-width.
fn fold(text: &str) -> String {
    text.chars()
        .map(|c| match c {
            '\u{FF01}'..='\u{FF5E}' => char::from_u32(c as u32 - 0xFEE0).unwrap_or(c),
            '\u{3000}' => ' ',
            _ => c,
        })
        .flat_map(char::to_lowercase)
        .collect()
}

/// Beat times in seconds from a beat file's bytes.
pub fn beats_from(bytes: &[u8]) -> Vec<f64> {
    fn walk(value: &serde_json::Value, out: &mut Vec<f64>) {
        match value {
            serde_json::Value::Object(map) => {
                for (key, value) in map {
                    if let serde_json::Value::Array(list) = value
                        && key.to_ascii_lowercase().contains("time")
                        && out.is_empty()
                    {
                        let numbers: Vec<f64> = list.iter().filter_map(|v| v.as_f64()).collect();
                        if !numbers.is_empty() {
                            *out = numbers;
                            continue;
                        }
                    }
                    walk(value, out);
                }
            }
            serde_json::Value::Array(list) => list.iter().for_each(|v| walk(v, out)),
            _ => {}
        }
    }
    let Ok(value) = serde_json::from_slice::<serde_json::Value>(bytes) else {
        return Vec::new();
    };
    let mut out = Vec::new();
    walk(&value, &mut out);
    // Milliseconds when any is past an hour's worth of seconds or the
    // spacing is in the hundreds.
    let millis =
        out.windows(2).any(|pair| pair[1] - pair[0] > 30.0) || out.iter().any(|t| *t > 3600.0);
    let mut beats: Vec<f64> = out
        .into_iter()
        .map(|t| if millis { t / 1000.0 } else { t })
        .filter(|t| t.is_finite() && *t >= 0.0)
        .collect();
    beats.sort_by(f64::total_cmp);
    beats.dedup();
    beats
}

/// The 我的 shelf: favourites and recently used, by card id, newest first.
#[derive(Serialize, Deserialize, Clone, Debug, Default, PartialEq)]
pub struct Mine {
    #[serde(default)]
    /// Starred, newest first.
    pub favorites: Vec<String>,
    #[serde(default)]
    /// Laid down or played, newest first.
    pub recent: Vec<String>,
    #[serde(skip)]
    path: Option<PathBuf>,
}

impl Mine {
    /// As kept in the app's config folder.
    pub fn open(dirs: &AppDirs) -> Mine {
        Mine::at(dirs.config.join("audio-mine.json"))
    }

    /// As kept at `path`, or empty when it is not there yet.
    pub fn at(path: PathBuf) -> Mine {
        let mut mine: Mine = std::fs::read(&path)
            .ok()
            .and_then(|bytes| serde_json::from_slice(&bytes).ok())
            .unwrap_or_default();
        mine.path = Some(path);
        mine
    }

    fn save(&self) {
        let Some(path) = &self.path else { return };
        if let Some(dir) = path.parent() {
            let _ = std::fs::create_dir_all(dir);
        }
        if let Ok(text) = serde_json::to_vec_pretty(self) {
            let partial = path.with_extension("partial");
            if std::fs::write(&partial, text).is_ok() {
                let _ = std::fs::rename(&partial, path);
            }
        }
    }

    /// Whether the card is starred.
    pub fn is_favorite(&self, card: &str) -> bool {
        self.favorites.iter().any(|id| id == card)
    }

    /// Starred, or unstarred when it was; whether it is now.
    pub fn toggle_favorite(&mut self, card: &str) -> bool {
        let on = if let Some(at) = self.favorites.iter().position(|id| id == card) {
            self.favorites.remove(at);
            false
        } else {
            self.favorites.insert(0, card.to_owned());
            true
        };
        self.save();
        on
    }

    /// Used: to the head of the recent list, which keeps [`RECENT`].
    pub fn used(&mut self, card: &str) {
        self.recent.retain(|id| id != card);
        self.recent.insert(0, card.to_owned());
        self.recent.truncate(RECENT);
        self.save();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temp(name: &str) -> PathBuf {
        let dir =
            std::env::temp_dir().join(format!("concat-audiolib-{name}-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        dir
    }

    const MANIFEST: &str = r#"{
      "schema": "marquee.audio-library/1",
      "music": {
        "categories": [
          {"id": "1", "name": "推荐音乐", "items": ["a", "b", "ghost"]},
          {"id": "2", "name": "卡点", "items": ["b", "c"]}
        ],
        "items": {
          "a": {"id": "a", "title": "Drink Shop", "artist": "ALEKSANDAR", "duration": 130, "audio": "music/a.mp3", "cover": "covers/a.png", "tags": ["嘻哈/说唱"]},
          "b": {"id": "b", "title": "晴天", "artist": "周杰伦", "duration": 269.5, "audio": "../escape.mp3"},
          "c": {"id": "c", "title": "Shop Around", "artist": "x", "duration": -3, "beats": "beats/c.json"}
        }
      },
      "sfx": {
        "categories": [{"id": "10894", "name": "笑声", "items": ["s"]}],
        "items": {"s": {"id": "s", "title": "男性嘿嘿笑声24", "artist": "剪映", "duration": 0.8, "audio": "sfx/s.mp3"}}
      }
    }"#;

    #[test]
    fn a_manifest_reads_and_keeps_inside_its_folder() {
        let root = temp("read");
        std::fs::create_dir_all(root.join("music")).unwrap();
        std::fs::write(root.join("music/a.mp3"), b"id3").unwrap();
        let library = AudioLibrary::parse(&root, MANIFEST.as_bytes()).unwrap();
        assert_eq!(
            library.music.categories[0].items,
            ["a", "b"],
            "a ghost is dropped"
        );
        assert_eq!(
            library.music.items["b"].audio, None,
            "a path out of the folder is forgotten"
        );
        assert_eq!(library.music.items["c"].duration, 0.0);
        let (kind, a) = library.entry("music-a").unwrap();
        assert_eq!(kind, Kind::Music);
        assert_eq!(library.audio_of(a), Some(root.join("music/a.mp3")));
        assert_eq!(library.cover_of(a), None, "a cover not on disk is none");
        assert!(library.entry("sfx-s").is_some());
        assert!(library.entry("concat-s").is_none());
        let all: Vec<&str> = library
            .listed(Kind::Music, None)
            .iter()
            .map(|e| e.id.as_str())
            .collect();
        assert_eq!(all, ["a", "b", "c"], "each once, in category order");
        let second: Vec<&str> = library
            .listed(Kind::Music, Some(1))
            .iter()
            .map(|e| e.id.as_str())
            .collect();
        assert_eq!(second, ["b", "c"]);
        assert!(library.listed(Kind::Music, Some(9)).is_empty());
    }

    #[test]
    fn another_schema_is_refused() {
        let root = temp("schema");
        assert!(AudioLibrary::parse(&root, br#"{"schema":"x","music":{}}"#).is_err());
        assert!(AudioLibrary::parse(&root, b"not json").is_err());
        assert!(AudioLibrary::open(&root).is_err(), "no manifest");
    }

    #[test]
    fn search_puts_title_matches_first_and_folds_case_and_width() {
        let root = temp("search");
        let library = AudioLibrary::parse(&root, MANIFEST.as_bytes()).unwrap();
        let ids = |q: &str| -> Vec<String> {
            library
                .search(Kind::Music, q)
                .iter()
                .map(|e| e.id.clone())
                .collect()
        };
        assert_eq!(ids("shop"), ["a", "c"]);
        assert_eq!(ids("ＳＨＯＰ"), ["a", "c"], "full-width folds");
        assert_eq!(ids("周杰伦"), ["b"], "by artist");
        assert_eq!(ids("说唱"), ["a"], "by tag");
        assert_eq!(ids("shop aleksandar"), ["a"], "every word must match");
        assert_eq!(ids("  "), ["a", "b", "c"], "a blank search is everything");
        assert_eq!(library.search(Kind::Sfx, "笑声").len(), 1);
    }

    #[test]
    fn beats_read_in_seconds() {
        assert_eq!(
            beats_from(br#"{"linenumber":1,"realtime":[500,1000,1500]}"#),
            [0.5, 1.0, 1.5]
        );
        assert_eq!(beats_from(br#"{"beats":{"times":[0.5,1.0]}}"#), [0.5, 1.0]);
        // The catalogue's own shape: a bar position, the times, an energy.
        assert_eq!(
            beats_from(br#"{"value":[4,1,2],"time":[350,1100,1840],"energy":[1,2,3]}"#),
            [0.35, 1.1, 1.84]
        );
        assert!(beats_from(b"x").is_empty());
    }

    #[test]
    fn favourites_and_recents_persist_newest_first() {
        let root = temp("mine");
        let path = root.join("audio-mine.json");
        let mut mine = Mine::at(path.clone());
        assert!(mine.toggle_favorite("music-a"));
        assert!(mine.toggle_favorite("sfx-s"));
        for n in 0..60 {
            mine.used(&format!("sfx-{n}"));
        }
        mine.used("sfx-3");
        let again = Mine::at(path);
        assert_eq!(again.favorites, ["sfx-s", "music-a"]);
        assert_eq!(again.recent.len(), RECENT);
        assert_eq!(again.recent[0], "sfx-3");
        let mut again = again;
        assert!(!again.toggle_favorite("music-a"));
        assert!(!again.is_favorite("music-a"));
    }
}
