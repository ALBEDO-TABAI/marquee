// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Jareer Abdullah and Concat contributors

//! What a placed clip looks and sounds like: its patchable fields, speed, transform, keys and cutout.
//!
//! One arm per command, exactly as [`super::apply`] routes them here;
//! everything these arms share lives in the parent module.

use super::*;

/// Applies one of this module's commands. Any other is a routing error.
pub(super) fn apply(
    project: &mut Project,
    _mint: &mut IdMint,
    command: Command,
) -> Result<Outcome, CommandError> {
    match command {
        Command::UpdateClip { clip_id, patch } => {
            let timeline = project.active_mut();
            let Some(clip) = timeline.clip_mut(&clip_id) else {
                return Ok(Outcome::default());
            };
            let mut applied = false;
            if let Some(name) = patch.name {
                applied |= assign(&mut clip.name, name);
            }
            if let Some(volume) = patch.volume {
                applied |= assign(&mut clip.volume, volume.max(0.0));
            }
            if let Some(fade_in) = patch.fade_in {
                applied |= assign(&mut clip.fade_in, fade_in.max(0.0));
            }
            if let Some(fade_out) = patch.fade_out {
                applied |= assign(&mut clip.fade_out, fade_out.max(0.0));
            }
            if let Some(anim) = patch.anim {
                applied |= assign(&mut clip.anim, anim.tidy());
            }
            if let Some(opacity) = patch.opacity {
                applied |= assign(&mut clip.opacity, opacity.clamp(0.0, 1.0));
            }
            if let Some(preserve) = patch.preserve_pitch {
                applied |= assign(&mut clip.preserve_pitch, preserve);
            }
            if let Some(muted) = patch.muted {
                // Unmuted is the absent value, so a document never carries
                // a `muted: false` that means the same as nothing.
                applied |= assign(&mut clip.muted, muted.then_some(true));
            }
            if let Some(flip) = patch.flip_h {
                applied |= assign(&mut clip.flip_h, flip);
            }
            if let Some(flip) = patch.flip_v {
                applied |= assign(&mut clip.flip_v, flip);
            }
            if let Some(blend) = patch.blend {
                let blend = if blend == "normal" {
                    String::new()
                } else {
                    blend
                };
                applied |= assign(&mut clip.blend, blend);
            }
            if let Some(crop) = patch.crop {
                let crop = crop.map(Crop::tidy).filter(|crop| !crop.is_none());
                applied |= assign(&mut clip.crop, crop);
            }
            if let Some(mask) = patch.mask {
                applied |= assign(&mut clip.mask, mask.map(ClipMask::tidy));
            }
            if let Some(filters) = patch.filters {
                applied |= assign(&mut clip.filters, filters);
            }
            if let Some(effects) = patch.video_effects {
                applied |= assign(&mut clip.video_effects, effects);
            }
            if let Some(transition) = patch.transition_in {
                applied |= assign(&mut clip.transition_in, transition);
            }
            if let Some(field) = patch.text {
                match field {
                    TextField::Clear => {
                        applied |= assign(&mut clip.text, None);
                    }
                    TextField::Words(words) => {
                        let mut style = clip.text.clone().unwrap_or_default();
                        applied |= assign(&mut style.content, words);
                        applied |= assign(&mut clip.name, first_line(&style.content));
                        applied |= assign(&mut clip.text, Some(style));
                    }
                    TextField::Style(style) => {
                        applied |= assign(&mut clip.name, first_line(&style.content));
                        applied |= assign(&mut clip.text, Some(*style));
                    }
                }
            }
            if let Some(shape) = patch.shape
                && clip.kind == crate::model::ClipKind::Shape
            {
                applied |= assign(&mut clip.shape, Some(shape.tidy()));
            }
            if let Some(stream) = patch.audio_stream {
                applied |= assign(&mut clip.audio_stream, stream);
            }
            if let Some(background) = patch.background {
                applied |= assign(&mut clip.background, background.map(Background::tidy));
            }
            Ok(Outcome {
                created_id: None,
                applied,
            
            ..Default::default()
            })
        }

        Command::StyleTextRange {
            clip_id,
            start,
            end,
            patch,
        } => {
            let Some(clip) = project.active_mut().clip_mut(&clip_id) else {
                return Ok(Outcome::default());
            };
            if clip.kind != ClipKind::Text {
                return Ok(Outcome::default());
            }
            let Some(text) = clip.text.as_mut() else {
                return Ok(Outcome::default());
            };
            let before = text.runs.clone();
            text.style_range(start, end, &patch);
            Ok(Outcome {
                created_id: None,
                applied: text.runs != before,
            
            ..Default::default()
            })
        }

        Command::ClearTextStyles {
            clip_id,
            start,
            end,
        } => {
            let Some(clip) = project.active_mut().clip_mut(&clip_id) else {
                return Ok(Outcome::default());
            };
            if clip.kind != ClipKind::Text {
                return Ok(Outcome::default());
            }
            let Some(text) = clip.text.as_mut() else {
                return Ok(Outcome::default());
            };
            let before = text.runs.clone();
            match (start, end) {
                (Some(start), Some(end)) => text.clear_range(start, end),
                _ => text.runs.clear(),
            }
            Ok(Outcome {
                created_id: None,
                applied: text.runs != before,
            
            ..Default::default()
            })
        }

        Command::SetClipSpeed {
            clip_id,
            speed,
            ripple,
            clear_curve,
        } => {
            let timeline = project.active_mut();
            let Some(clip) = timeline.clip_mut(&clip_id) else {
                return Ok(Outcome::default());
            };
            // The amount of source covered is held constant - that is what
            // makes this a speed change rather than a trim.
            let next = speed.clamp(MIN_SPEED, MAX_SPEED);
            let source_covered = clip.duration * clip.speed;
            let old_end = clip.start + clip.duration;
            let mut warnings = Vec::new();
            let mut applied = false;
            if clip.speed_curve.is_some() && !clear_curve {
                warnings.push(
                    "speedCurve kept; pass clearCurve: true to replace it with a constant speed"
                        .into(),
                );
            } else {
                applied |= assign(&mut clip.speed, next);
                if clear_curve || clip.speed_curve.is_some() {
                    applied |= assign(&mut clip.speed_curve, None);
                }
                if ripple {
                    applied |= assign(
                        &mut clip.duration,
                        (source_covered / next).max(MIN_CLIP_DURATION),
                    );
                    make_room(timeline, &clip_id, old_end, true);
                }
            }
            Ok(Outcome {
                created_id: None,
                applied,
                warnings,
                ..Default::default()
            })
        }

        Command::SetClipCutout { clip_id, cutout } => {
            let timeline = project.active_mut();
            let Some(clip) = timeline.clip_mut(&clip_id) else {
                return Ok(Outcome::default());
            };
            let applied = assign(&mut clip.cutout, cutout.map(Cutout::tidy));
            Ok(Outcome {
                created_id: None,
                applied,
            
            ..Default::default()
            })
        }

        Command::SetClipStabilize { clip_id, stabilize } => {
            let timeline = project.active_mut();
            let Some(clip) = timeline.clip_mut(&clip_id) else {
                return Ok(Outcome::default());
            };
            // Only footage has a camera that moved: a still, a title, a
            // shape or a layer has nothing to steady.
            if clip.kind != ClipKind::Video && stabilize.is_some() {
                return Ok(Outcome::default());
            }
            let applied = assign(&mut clip.stabilize, stabilize.map(Stabilize::tidy));
            Ok(Outcome {
                created_id: None,
                applied,
            
            ..Default::default()
            })
        }

        Command::SetClipVoice { clip_id, voice } => {
            let timeline = project.active_mut();
            let Some(clip) = timeline.clip_mut(&clip_id) else {
                return Ok(Outcome::default());
            };
            // Only what plays sound has a voice in it: footage and sound.
            if !matches!(clip.kind, ClipKind::Video | ClipKind::Audio) && voice.is_some() {
                return Ok(Outcome::default());
            }
            let applied = assign(&mut clip.voice, voice.map(VoiceMix::tidy));
            Ok(Outcome {
                created_id: None,
                applied,
            
            ..Default::default()
            })
        }

        Command::AddCutoutStroke { clip_id, stroke } => {
            let timeline = project.active_mut();
            let Some(clip) = timeline.clip_mut(&clip_id) else {
                return Ok(Outcome::default());
            };
            let Some(stroke) = stroke.tidy() else {
                return Ok(Outcome::default());
            };
            let cutout = clip.cutout.get_or_insert_with(Cutout::auto);
            cutout.mode = CutoutMode::Custom;
            cutout.strokes.push(stroke);
            Ok(Outcome {
                created_id: None,
                applied: true,
            
            ..Default::default()
            })
        }

        Command::DuckAudio {
            music_id,
            trigger_id,
            amount,
            attack,
            release,
        } => {
            let timeline = project.active();
            let Some(music) = timeline.clip(&music_id).cloned() else {
                return Ok(Outcome::default());
            };
            let Some(trigger) = timeline.clip(&trigger_id) else {
                return Ok(Outcome::default());
            };
            let amount = amount.max(0.0);
            let attack = attack.max(0.0);
            let release = release.max(0.0);
            let win_start = trigger.start.max(music.start);
            let win_end = (trigger.start + trigger.duration).min(music.start + music.duration);
            if win_end <= win_start + 1e-4 || music.duration <= 1e-6 {
                return Ok(Outcome {
                    created_id: None,
                    applied: false,
                    warnings: vec![
                        "duckAudio: music and trigger do not overlap; wrote 0 keys".into(),
                    ],
                    ..Default::default()
                });
            }
            let rest = music.volume.max(0.0);
            let down = (win_start - attack).max(music.start);
            let up = (win_end + release).min(music.start + music.duration);
            let frac = |time: f64| ((time - music.start) / music.duration).clamp(0.0, 1.0);
            // Keys closer than KEY_EPSILON collapse; a 0.12s attack on a
            // 78s music clip is ~0.0015 and would swallow the attack key.
            let ats = separate_key_ats([
                frac(down),
                frac(win_start),
                frac(win_end),
                frac(up),
            ]);
            let timeline = project.active_mut();
            let Some(clip) = timeline.clip_mut(&music_id) else {
                return Ok(Outcome::default());
            };
            let before = clip.keys.clone();
            clip.set_key(KeyProperty::Volume, ats[0], rest, KeyEase::default());
            clip.set_key(KeyProperty::Volume, ats[1], amount, KeyEase::default());
            clip.set_key(KeyProperty::Volume, ats[2], amount, KeyEase::default());
            clip.set_key(KeyProperty::Volume, ats[3], rest, KeyEase::default());
            Ok(Outcome {
                created_id: None,
                applied: clip.keys != before,
            
            ..Default::default()
            })
        }

        Command::SetClipKey {
            clip_id,
            property,
            at,
            value,
            ease,
        } => {
            let timeline = project.active_mut();
            let Some(clip) = timeline.clip_mut(&clip_id) else {
                return Ok(Outcome::default());
            };
            if !at.is_finite() || !value.is_finite() {
                return Ok(Outcome::default());
            }
            // Mask keys are invisible unless the clip already has a mask:
            // flatten (and preview) skip animation on a missing mask.
            if matches!(
                property,
                KeyProperty::MaskX
                    | KeyProperty::MaskY
                    | KeyProperty::MaskWidth
                    | KeyProperty::MaskHeight
                    | KeyProperty::MaskRotation
                    | KeyProperty::MaskRoundness
                    | KeyProperty::MaskFeather
            ) && clip.mask.is_none()
            {
                clip.mask = Some(ClipMask::of(MaskShape::Rectangle));
            }
            // Clamped the way the field itself is, so a key can never hold a
            // value the constant would have been refused. The clamps are the
            // ones ClipPatch applies; keeping them here as well is what stops
            // a key being the back door round them.
            let value = match property {
                KeyProperty::Scale => value.clamp(MIN_SCALE, MAX_SCALE),
                KeyProperty::Opacity => value.clamp(0.0, 1.0),
                // No ceiling, matching ClipPatch: the level fader goes to
                // +24 dB because quiet material needs it, and a key is the
                // same value at a different instant.
                KeyProperty::Volume => value.max(0.0),
                KeyProperty::OffsetX | KeyProperty::OffsetY | KeyProperty::Rotation => value,
                mask => ClipMask::clamp(mask, value),
            };
            let before = clip.keys.clone();
            clip.set_key(property, at, value, ease);
            Ok(Outcome {
                created_id: None,
                applied: clip.keys != before,
            
            ..Default::default()
            })
        }

        Command::ClearClipKey {
            clip_id,
            property,
            at,
        } => {
            let timeline = project.active_mut();
            let Some(clip) = timeline.clip_mut(&clip_id) else {
                return Ok(Outcome::default());
            };
            let applied = clip.clear_key(property, at);
            Ok(Outcome {
                created_id: None,
                applied,
            
            ..Default::default()
            })
        }

        Command::ClearClipKeys { clip_id, property } => {
            let timeline = project.active_mut();
            let Some(clip) = timeline.clip_mut(&clip_id) else {
                return Ok(Outcome::default());
            };
            let applied = clip.clear_keys(property);
            Ok(Outcome {
                created_id: None,
                applied,
            
            ..Default::default()
            })
        }

        Command::SetEffectKey {
            clip_id,
            entry,
            key,
            at,
            value,
            ease,
        } => {
            let timeline = project.active_mut();
            let Some(link) = timeline
                .clip_mut(&clip_id)
                .and_then(|clip| clip.video_effects.get_mut(entry))
            else {
                return Ok(Outcome::default());
            };
            if !at.is_finite() || !value.is_finite() {
                return Ok(Outcome::default());
            }
            let before = link.keys.clone();
            link.set_key(&key, at, value, ease);
            Ok(Outcome {
                created_id: None,
                applied: link.keys != before,
            
            ..Default::default()
            })
        }

        Command::ClearEffectKey {
            clip_id,
            entry,
            key,
            at,
        } => {
            let timeline = project.active_mut();
            let Some(link) = timeline
                .clip_mut(&clip_id)
                .and_then(|clip| clip.video_effects.get_mut(entry))
            else {
                return Ok(Outcome::default());
            };
            let applied = link.clear_key(&key, at);
            Ok(Outcome {
                created_id: None,
                applied,
            
            ..Default::default()
            })
        }

        Command::ClearEffectKeys {
            clip_id,
            entry,
            key,
        } => {
            let timeline = project.active_mut();
            let Some(link) = timeline
                .clip_mut(&clip_id)
                .and_then(|clip| clip.video_effects.get_mut(entry))
            else {
                return Ok(Outcome::default());
            };
            let applied = link.clear_keys(&key);
            Ok(Outcome {
                created_id: None,
                applied,
            
            ..Default::default()
            })
        }

        Command::SetClipSpeedCurve {
            clip_id,
            curve,
            ripple,
        } => {
            let timeline = project.active_mut();
            let Some(clip) = timeline.clip_mut(&clip_id) else {
                return Ok(Outcome::default());
            };
            let curve = curve.filter(|points| crate::speed::curve_of(points).is_some());
            let source_covered = clip.duration * clip.speed;
            let old_end = clip.start + clip.duration;
            let mean = curve
                .as_ref()
                .map(|points| crate::speed::mean_of(points))
                .unwrap_or(clip.speed)
                .clamp(MIN_SPEED, MAX_SPEED);
            let mut applied = assign(&mut clip.speed_curve, curve) | assign(&mut clip.speed, mean);
            if ripple {
                applied |= assign(
                    &mut clip.duration,
                    (source_covered / mean).max(MIN_CLIP_DURATION),
                );
                make_room(timeline, &clip_id, old_end, true);
            }
            Ok(Outcome {
                created_id: None,
                applied,
            
            ..Default::default()
            })
        }

        Command::MatchClip { clip_id, like } => {
            let timeline = project.active_mut();
            let Some(clip) = timeline.clip_mut(&clip_id) else {
                return Ok(Outcome::default());
            };
            let mut matched = *like;
            matched.id = clip.id.clone();
            matched.track_id = clip.track_id.clone();
            matched.media_id = clip.media_id.clone();
            matched.kind = clip.kind;
            matched.start = clip.start;
            matched.duration = clip.duration;
            matched.source_start = clip.source_start;
            matched.speed = clip.speed;
            matched.speed_curve = clip.speed_curve.clone();
            matched.detached_from = clip.detached_from.clone();
            matched.transition_in = clip.transition_in.clone();
            // A title's words and a shape's figure are what it is, and only
            // a clip of the same kind can wear them.
            if matched.text.is_some() != clip.text.is_some() {
                matched.text = clip.text.clone();
            }
            if matched.shape.is_some() != clip.shape.is_some() {
                matched.shape = clip.shape.clone();
            }
            let applied = assign(clip, matched);
            Ok(Outcome {
                created_id: None,
                applied,
            
            ..Default::default()
            })
        }
        Command::SetClipTransform {
            clip_id,
            scale,
            offset_x,
            offset_y,
            rotation,
            stretch_x,
            stretch_y,
        } => {
            let timeline = project.active_mut();
            let Some(clip) = timeline.clip_mut(&clip_id) else {
                return Ok(Outcome::default());
            };
            let mut applied = false;
            if let Some(scale) = scale {
                applied |= assign(&mut clip.scale, scale.clamp(MIN_SCALE, MAX_SCALE));
            }
            if let Some(offset) = offset_x {
                applied |= assign(&mut clip.offset_x, offset.clamp(-MAX_OFFSET, MAX_OFFSET));
            }
            if let Some(offset) = offset_y {
                applied |= assign(&mut clip.offset_y, offset.clamp(-MAX_OFFSET, MAX_OFFSET));
            }
            if let Some(rotation) = rotation {
                applied |= assign(&mut clip.rotation, wrap_rotation(rotation));
            }
            if let Some(stretch) = stretch_x {
                applied |= assign(&mut clip.stretch_x, stretch.clamp(MIN_STRETCH, MAX_STRETCH));
            }
            if let Some(stretch) = stretch_y {
                applied |= assign(&mut clip.stretch_y, stretch.clamp(MIN_STRETCH, MAX_STRETCH));
            }
            Ok(Outcome {
                created_id: None,
                applied,
            
            ..Default::default()
            })
        }

        Command::FrameClip {
            clip_id,
            framing,
            at,
        } => {
            let timeline = project.active();
            let frame = (timeline.video.width, timeline.video.height);
            let Some(media) = timeline
                .clip(&clip_id)
                .and_then(|clip| project.media_by_id(&clip.media_id))
                .map(|item| (item.width, item.height))
            else {
                return Ok(Outcome::default());
            };
            let Some(clip) = project.active_mut().clip_mut(&clip_id) else {
                return Ok(Outcome::default());
            };
            let at = at.clamp(0.0, 1.0);
            let Some(scale) = clip.framing_scale(framing, media, frame, at) else {
                return Ok(Outcome::default());
            };
            let before = clip.clone();
            clip.write_at(KeyProperty::Scale, scale, at);
            clip.write_at(KeyProperty::OffsetX, 0.0, at);
            clip.write_at(KeyProperty::OffsetY, 0.0, at);
            // A stretch is a picture pulled out of its shape, and neither a
            // fit nor a fill is: both are the picture as it was shot.
            clip.stretch_x = 1.0;
            clip.stretch_y = 1.0;
            Ok(Outcome {
                created_id: None,
                applied: *clip != before,
            
            ..Default::default()
            })
        }

        _ => unreachable!("commands::apply routes only this module's commands here"),
    }
}

/// What a retimed clip does to the lane behind it. One that ends later
/// than `old_end` and would cover what follows it pushes the rest of the
/// lane along by the growth, as a freeze frame's does. On the magnetic
/// timeline (`ripple`) the lane follows the clip's end either way, so a
/// clip sped up leaves no gap, as a magnetic trim leaves none. Shared by
/// the constant rate and the curve, which both stretch a clip.
fn make_room(timeline: &mut Timeline, clip_id: &str, old_end: f64, ripple: bool) {
    let Some(clip) = timeline.clip(clip_id) else {
        return;
    };
    let (track_id, start, duration) = (clip.track_id.clone(), clip.start, clip.duration);
    let moved = start + duration - old_end;
    let pushed = moved > 0.0 && !timeline.is_free(&track_id, start, duration, &[clip_id]);
    if (ripple && moved != 0.0) || pushed {
        let main = timeline.background_lane().map(str::to_owned);
        for other in timeline.clips_where(|other| {
            other.id != clip_id
                && other.track_id == track_id
                && other.start >= old_end - crate::placement::TOUCH
        }) {
            other.start = (other.start + moved).max(0.0);
        }
        // Linkage: sped up, the clip gave back the end of its old span;
        // slowed down, it put more in at its old end.
        let ripple = if moved < 0.0 {
            clips::Ripple::Removed(vec![(old_end + moved, old_end)])
        } else {
            clips::Ripple::Inserted {
                at: old_end,
                length: moved,
            }
        };
        clips::follow_main(timeline, main.as_deref(), &track_id, ripple);
    }
}

/// Spread four key fractions so neighbouring ones stay at least
/// `KEY_EPSILON` apart (otherwise `set_key` overwrites the earlier).
fn separate_key_ats(mut ats: [f64; 4]) -> [f64; 4] {
    let eps = crate::model::KEY_EPSILON + 1e-9;
    for i in 1..4 {
        if ats[i] < ats[i - 1] + eps {
            ats[i] = (ats[i - 1] + eps).min(1.0);
        }
    }
    for i in (0..3).rev() {
        if ats[i + 1] < ats[i] + eps {
            ats[i] = (ats[i + 1] - eps).max(0.0);
        }
    }
    for i in 1..4 {
        if ats[i] < ats[i - 1] + eps {
            ats[i] = (ats[i - 1] + eps).min(1.0);
        }
    }
    ats
}
