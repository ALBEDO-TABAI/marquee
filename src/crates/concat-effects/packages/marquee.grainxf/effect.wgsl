// 颗粒叠化: a grain-by-grain dissolve.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // Grain by grain: each 2px cell turns over at its own moment.
    let cell = floor(uv * frame.size / 2.0);
    let turn = hash(cell, 11.0);
    let edge = smoothstep(turn - 0.06, turn + 0.06, p * 1.12 - 0.06);
    return mix(from_at(uv), to_at(uv), edge);
}
