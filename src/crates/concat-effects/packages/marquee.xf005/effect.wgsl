fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = clamp(progress, 0.0, 1.0);
    let k = 1.0 - abs(t * 2.0 - 1.0);
    // Bands of rows jump sideways by their own amount, re-dealt eight
    // times through the cut; each band switches shot at its own moment.
    let step_t = floor(t * 8.0);
    let band = floor(uv.y * 14.0);
    let r1 = fract(sin(band * 12.9898 + step_t * 78.233) * 43758.5453);
    let r2 = fract(sin(band * 39.346 + step_t * 11.135) * 24634.6345);
    let shift = (r1 - 0.5) * 0.18 * k;
    let q = vec2<f32>(uv.x + shift, uv.y);
    let s = 0.03 * k;
    let pick = step(r2 * 0.6 + 0.2, t);
    let r = mix(from_at(q + vec2<f32>(s, 0.0)), to_at(q + vec2<f32>(s, 0.0)), pick).r;
    let g = mix(from_at(q), to_at(q), pick);
    let b = mix(from_at(q - vec2<f32>(s, 0.0)), to_at(q - vec2<f32>(s, 0.0)), pick).b;
    return vec4<f32>(r, g.g, b, g.a);
}
