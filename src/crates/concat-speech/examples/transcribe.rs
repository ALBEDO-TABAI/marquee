// SPDX-License-Identifier: AGPL-3.0-or-later
//! Download (if needed) a whisper.cpp model and transcribe a media file.
//!
//!   cargo run -p concat-speech --example transcribe -- /path/clip.wav tiny.en

use concat_host::AppDirs;
use concat_speech::transcribe::{TranscribeRequest, Transcriber};

fn main() {
    let mut args = std::env::args().skip(1);
    let path = args.next().expect("usage: transcribe <media> [model-id]");
    let model_id = args.next().unwrap_or_else(|| "tiny.en".to_owned());
    let dirs = AppDirs::locate().expect("app dirs");
    let transcriber = Transcriber::new();
    if let Err(error) = transcriber.download_model(&dirs, &model_id, |progress| {
        if progress.done {
            eprintln!("downloaded {}", progress.id);
        } else if progress.total > 0 {
            eprintln!(
                "downloading {} {}/{}",
                progress.id, progress.received, progress.total
            );
        }
    }) {
        eprintln!("download: {error}");
        std::process::exit(1);
    }
    let request = TranscribeRequest {
        path,
        audio_stream: None,
        source_start: 0.0,
        window: 30.0,
        model_id,
        language: Some("en".to_owned()),
        prompt: None,
        glossary: Vec::new(),
        glossary_fuzzy: false,
            glossary_in_prompt: false,
    };
    match transcriber.transcribe(&dirs, &request, |_| {}) {
        Ok(segments) => {
            println!("{}", serde_json::to_string_pretty(&segments).expect("json"));
        }
        Err(error) => {
            eprintln!("transcribe: {error}");
            std::process::exit(2);
        }
    }
}
