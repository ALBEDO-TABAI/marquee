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
            Shell::with(|shell, app| {
                {
                    let mut state = shell.studio.borrow_mut();
                    state.open_menu = value.get("index").and_then(|v| v.as_i64()).unwrap_or(0) as i32;
                    state.menu_bar_token = state.menu_bar_token.saturating_add(1);
                }
                shell.studio.borrow().publish(&app, &shell.models);
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
