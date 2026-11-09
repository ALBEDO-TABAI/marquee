//! Local screenshot-control socket, started only when `CONCAT_SHOT_PORT` is set.
//!
//! One JSON object per line, one reply line. Used by the Ready restyle
//! contact-sheet runner so every shelf, inspector tab and overlay can be
//! opened by state rather than by guessed clicks.

use std::io::{BufRead, BufReader, Write};
use std::net::TcpListener;
use std::sync::mpsc;
use std::time::Duration;

use concat_project::model::ClipKind;
use slint::{ComponentHandle, SharedString};

use crate::host::{self, Shell};
use crate::panes::Msg;
use crate::panes::captions::CaptionsMsg;
use crate::panes::export::ExportMsg;
use crate::panes::settings::SettingsMsg;
use crate::ui::{Editor, GlassChrome, Theme, Tips};

/// Binds `GlassChrome.refresh` to a window snapshot and starts the listener.
pub fn install(app: &crate::ui::App) {
    app.global::<GlassChrome>().on_refresh(|| {
        Shell::with(|_, app| {
            let frost = host::capture_window_frost(&app);
            app.global::<GlassChrome>().set_frost(frost);
        });
    });
    listen();
}

fn listen() {
    let Ok(raw) = std::env::var("CONCAT_SHOT_PORT") else {
        return;
    };
    let Ok(port) = raw.parse::<u16>() else {
        log::warn!("CONCAT_SHOT_PORT={raw} is not a port");
        return;
    };
    std::thread::Builder::new()
        .name("concat-shot".into())
        .spawn(move || {
            let bind = format!("127.0.0.1:{port}");
            let listener = match TcpListener::bind(&bind) {
                Ok(l) => l,
                Err(error) => {
                    log::warn!("shot control: {error}");
                    return;
                }
            };
            log::info!("shot control listening on {bind}");
            for stream in listener.incoming() {
                let Ok(mut stream) = stream else { continue };
                let _ = stream.set_read_timeout(Some(Duration::from_secs(30)));
                let Ok(clone) = stream.try_clone() else { continue };
                let mut reader = BufReader::new(clone);
                let mut line = String::new();
                if reader.read_line(&mut line).is_err() {
                    continue;
                }
                let cmd = line.trim().to_string();
                if cmd.is_empty() {
                    continue;
                }
                let (tx, rx) = mpsc::channel();
                let sent = slint::invoke_from_event_loop(move || {
                    let reply = apply(&cmd);
                    let _ = tx.send(reply);
                });
                let reply = if sent.is_err() {
                    "err event-loop".to_string()
                } else {
                    rx.recv_timeout(Duration::from_secs(8))
                        .unwrap_or_else(|_| "err timeout".into())
                };
                let _ = writeln!(stream, "{reply}");
            }
        })
        .ok();
}

fn apply(line: &str) -> String {
    let value: serde_json::Value = match serde_json::from_str(line) {
        Ok(v) => v,
        Err(error) => return format!("err parse: {error}"),
    };
    let op = value.get("op").and_then(|v| v.as_str()).unwrap_or("");
    match op {
        "ping" => "ok".into(),
        "theme" => {
            let dark = value.get("dark").and_then(|v| v.as_bool()).unwrap_or(true);
            Shell::with(|_, app| app.global::<Theme>().set_dark(dark));
            "ok".into()
        }
        "library" => {
            let tab = value.get("tab").and_then(|v| v.as_i64()).unwrap_or(0) as i32;
            let text_category = value
                .get("text_category")
                .and_then(|v| v.as_i64())
                .unwrap_or(0) as i32;
            Shell::with(|_, app| {
                let editor = app.global::<Editor>();
                editor.set_library_tab(tab);
                editor.set_library_text_category(text_category);
            });
            "ok".into()
        }
        "select_clip" => {
            let kind = value.get("kind").and_then(|v| v.as_str()).unwrap_or("video");
            let wanted = match kind {
                "audio" => ClipKind::Audio,
                "text" => ClipKind::Text,
                "image" => ClipKind::Image,
                "sticker" | "shape" => ClipKind::Shape,
                "effect" | "layer" => ClipKind::Layer,
                _ => ClipKind::Video,
            };
            let mut found = None;
            Shell::with(|shell, app| {
                {
                    let mut state = shell.studio.borrow_mut();
                    let clips = &state.timeline().clips;
                    found = clips
                        .iter()
                        .find(|clip| clip.kind == wanted)
                        .map(|clip| clip.id.clone());
                    if found.is_none() && matches!(kind, "sticker" | "shape") {
                        found = clips
                            .iter()
                            .find(|clip| {
                                clip.name.to_ascii_lowercase().contains("sticker")
                                    || matches!(clip.kind, ClipKind::Shape | ClipKind::Image)
                            })
                            .map(|clip| clip.id.clone());
                    }
                    if found.is_none() && matches!(kind, "effect" | "layer") {
                        found = clips
                            .iter()
                            .find(|clip| {
                                matches!(clip.kind, ClipKind::Layer | ClipKind::SoundLayer)
                            })
                            .map(|clip| clip.id.clone());
                    }
                    if let Some(id) = found.as_deref() {
                        state.clip_pressed(id, false, -1);
                    }
                }
                shell.studio.borrow().publish(&app, &shell.models);
            });
            match found {
                Some(id) => format!("ok {id}"),
                None => format!("err no {kind} clip"),
            }
        }
        "inspector" => {
            let jump_tab = value
                .get("jump_tab")
                .and_then(|v| v.as_str())
                .unwrap_or("Video");
            let jump_section = value
                .get("jump_section")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            Shell::with(|_, app| {
                let editor = app.global::<Editor>();
                editor.set_inspector_jump_tab(SharedString::from(jump_tab));
                editor.set_inspector_jump_section(SharedString::from(jump_section));
                let token = editor.get_inspector_jump_token();
                editor.set_inspector_jump_token(token.wrapping_add(1));
            });
            "ok".into()
        }
        "settings" => {
            let tab = value.get("tab").and_then(|v| v.as_i64()).unwrap_or(1) as i32;
            Shell::with(|shell, app| {
                {
                    let mut state = shell.studio.borrow_mut();
                    state.handle(Msg::Settings(SettingsMsg::Open));
                    state.handle(Msg::Settings(SettingsMsg::PageChanged(tab)));
                }
                shell.studio.borrow().publish(&app, &shell.models);
            });
            "ok".into()
        }
        "export" => {
            Shell::with(|shell, app| {
                {
                    let mut state = shell.studio.borrow_mut();
                    state.handle(Msg::Export(ExportMsg::Open));
                }
                shell.studio.borrow().publish(&app, &shell.models);
            });
            "ok".into()
        }
        "captions" => {
            Shell::with(|shell, app| {
                {
                    let mut state = shell.studio.borrow_mut();
                    state.handle(Msg::Captions(CaptionsMsg::Open));
                }
                shell.studio.borrow().publish(&app, &shell.models);
            });
            "ok".into()
        }
        "menu" => {
            // Through the strip, as the keyboard opens one: the menu is then
            // placed under its own label, where a click would put it.
            let index = value.get("index").and_then(|v| v.as_i64()).unwrap_or(0) as i32;
            Shell::with(|_, app| {
                app.global::<GlassChrome>().invoke_refresh();
                app.invoke_open_menu_from_keys(index);
            });
            "ok".into()
        }
        "dropdown" => {
            Shell::with(|_, app| {
                let editor = app.global::<Editor>();
                editor.set_summon_select(editor.get_summon_select().wrapping_add(1));
            });
            "ok".into()
        }
        "tooltip" => {
            let text = value
                .get("text")
                .and_then(|v| v.as_str())
                .unwrap_or("Play");
            Shell::with(|_, app| {
                app.global::<GlassChrome>().invoke_refresh();
                let tips = app.global::<Tips>();
                tips.set_text(SharedString::from(text));
                tips.set_anchor_x(900.0);
                tips.set_anchor_y(72.0);
                tips.set_anchor_w(72.0);
                tips.set_anchor_h(28.0);
                tips.set_shown(true);
                tips.set_warm(true);
            });
            "ok".into()
        }
        "toast" => {
            let message = value
                .get("message")
                .and_then(|v| v.as_str())
                .unwrap_or("Project saved");
            let failed = value.get("failed").and_then(|v| v.as_bool()).unwrap_or(false);
            Shell::with(|shell, app| {
                shell.studio.borrow_mut().notify(message, failed);
                shell.studio.borrow().publish(&app, &shell.models);
            });
            "ok".into()
        }
        "welcome" => {
            Shell::with(|shell, app| {
                {
                    let _ = shell.studio.borrow_mut().close_project();
                }
                shell.studio.borrow().publish(&app, &shell.models);
            });
            "ok".into()
        }
        "backdrop" => {
            Shell::with(|_, app| app.global::<GlassChrome>().invoke_refresh());
            "ok".into()
        }
        "hover" => {
            let kind = value.get("kind").and_then(|v| v.as_str()).unwrap_or("");
            let id = value.get("id").and_then(|v| v.as_str()).unwrap_or("");
            if id.is_empty() {
                return "err hover needs id".into();
            }
            // Gated by CONCAT_SHOT_PORT: drives gallery hover without a pointer.
            Shell::with(|shell, app| {
                shell
                    .studio
                    .borrow_mut()
                    .gallery_hover(&app, kind, id);
            });
            "ok".into()
        }
        // Scroll the shelf so a tile is near the top: by `id` within the
        // shelf `tab` / `text_category` names, or by `index`.
        "reveal" => {
            let tab = value.get("tab").and_then(|v| v.as_i64()).unwrap_or(1) as i32;
            let text_category = value
                .get("text_category")
                .and_then(|v| v.as_i64())
                .unwrap_or(0) as i32;
            let id = value.get("id").and_then(|v| v.as_str()).unwrap_or("").to_owned();
            let wanted = value.get("index").and_then(|v| v.as_i64());
            let mut found: Option<usize> = wanted.map(|i| i.max(0) as usize);
            Shell::with(|_, app| {
                use slint::Model;
                let editor = app.global::<Editor>();
                editor.set_library_tab(tab);
                editor.set_library_text_category(text_category);
                if found.is_none() && !id.is_empty() {
                    found = match (tab, text_category) {
                        (1, 3) => editor
                            .get_catalogue_textanims()
                            .iter()
                            .position(|e| e.id.as_str() == id),
                        (1, 1) => editor
                            .get_language_presets()
                            .iter()
                            .position(|p| p.id.as_str() == id),
                        (1, 4) => editor
                            .get_template_presets()
                            .iter()
                            .position(|p| p.id.as_str() == id),
                        (1, _) => editor
                            .get_style_presets()
                            .iter()
                            .position(|p| p.id.as_str() == id),
                        (2, _) => editor
                            .get_catalogue_stickers()
                            .iter()
                            .position(|e| e.id.as_str() == id),
                        (3, _) => editor
                            .get_catalogue_transitions()
                            .iter()
                            .position(|e| e.id.as_str() == id),
                        (4, _) => editor
                            .get_catalogue_effects()
                            .iter()
                            .position(|e| e.id.as_str() == id),
                        (5, _) => editor
                            .get_catalogue_filters()
                            .iter()
                            .position(|e| e.id.as_str() == id),
                        _ => None,
                    };
                }
                if let Some(index) = found {
                    editor.set_library_reveal_index(index as i32);
                    editor.set_library_reveal_token(
                        editor.get_library_reveal_token().wrapping_add(1),
                    );
                }
            });
            match found {
                Some(index) => format!("ok {index}"),
                None => format!("err no {id} on tab {tab}"),
            }
        }
        // The page offset directly, in logical pixels from the top.
        "sticker_shelf" => {
            let shelf = value.get("shelf").and_then(|v| v.as_i64()).unwrap_or(0) as i32;
            Shell::with(|_, app| {
                let editor = app.global::<Editor>();
                editor.set_library_tab(2);
                editor.set_library_sticker_shelf(shelf);
                editor.set_library_sticker_token(editor.get_library_sticker_token().wrapping_add(1));
            });
            "ok".into()
        }
        "scroll" => {
            let y = value.get("y").and_then(|v| v.as_f64()).unwrap_or(0.0) as f32;
            Shell::with(|_, app| {
                let editor = app.global::<Editor>();
                editor.set_library_scroll_y(y);
                editor.set_library_scroll_token(editor.get_library_scroll_token().wrapping_add(1));
            });
            "ok".into()
        }
        // `wake` shows the transport again; `play` toggles playback.
        "transport" => {
            let wake = value.get("wake").and_then(|v| v.as_bool()).unwrap_or(false);
            let play = value.get("play").and_then(|v| v.as_bool()).unwrap_or(false);
            Shell::with(|_, app| {
                let editor = app.global::<Editor>();
                if wake {
                    editor.set_transport_wake(editor.get_transport_wake().wrapping_add(1));
                }
                if play {
                    editor.invoke_play_toggled();
                }
            });
            "ok".into()
        }
        // A text preset placed at the playhead, as a click on its card does.
        "add_text" => {
            let id = value.get("id").and_then(|v| v.as_str()).unwrap_or("default");
            let name = value.get("name").and_then(|v| v.as_str()).unwrap_or("Title");
            let payload = format!("text:{id}:{name}");
            Shell::with(|shell, app| {
                shell.studio.borrow_mut().place_at_playhead(&payload);
                shell.studio.borrow().publish(&app, &shell.models);
            });
            "ok".into()
        }
        // Clicks a sticker / filter / text-animation tile without a pointer:
        // the same Editor callback the tile fires.
        "apply_filter" => {
            let id = value.get("id").and_then(|v| v.as_str()).unwrap_or("").to_owned();
            let label = value.get("label").and_then(|v| v.as_str()).unwrap_or("").to_owned();
            if id.is_empty() {
                return "err apply_filter needs id".into();
            }
            Shell::with(|_, app| {
                app.global::<Editor>()
                    .invoke_library_apply_filter(id.as_str().into(), label.as_str().into())
            });
            "ok".into()
        }
        // Moves the playhead, in seconds.
        "seek" => {
            let at = value.get("at").and_then(|v| v.as_f64()).unwrap_or(0.0) as f32;
            Shell::with(|_, app| app.global::<Editor>().invoke_seek(at));
            "ok".into()
        }
        "leave" => {
            Shell::with(|shell, app| {
                shell.studio.borrow_mut().gallery_leave(&app);
            });
            "ok".into()
        }
        "close" => {
            Shell::with(|shell, app| {
                {
                    let mut state = shell.studio.borrow_mut();
                    state.handle(Msg::Settings(SettingsMsg::Close));
                    state.handle(Msg::Export(ExportMsg::Close));
                    state.handle(Msg::Captions(CaptionsMsg::Close));
                    state.open_menu = -1;
                    state.menu_bar_token = state.menu_bar_token.saturating_add(1);
                }
                let chrome = app.global::<GlassChrome>();
                chrome.set_dismiss(chrome.get_dismiss().wrapping_add(1));
                app.global::<Tips>().invoke_close();
                shell.studio.borrow().publish(&app, &shell.models);
            });
            "ok".into()
        }
        other => format!("err unknown op {other}"),
    }
}
