// RGB 撕裂: torn rows and split channels across the cut.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // Rows torn sideways and the channels split, worst at the cut.
    let mid = sin(3.14159265 * p);
    let row = floor(uv.y * 24.0);
    let tear = (hash(vec2<f32>(row, 1.0), floor(p * 30.0)) - 0.5) * 0.12 * mid;
    let q = vec2<f32>(fract(uv.x + tear), uv.y);
    let s = 0.015 * mid;
    let after = hash(vec2<f32>(row, 2.0), 5.0) * 0.3 + 0.35 < p;
    let r = select(from_at(q + vec2<f32>(s, 0.0)), to_at(q + vec2<f32>(s, 0.0)), after).r;
    let mid_c = select(from_at(q), to_at(q), after);
    let b = select(from_at(q - vec2<f32>(s, 0.0)), to_at(q - vec2<f32>(s, 0.0)), after).b;
    return vec4<f32>(r, mid_c.g, b, mid_c.a);
}
