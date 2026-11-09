struct Params { amount: f32 }
// 录像带: a worn tape - colour bleeding, a tracking band, wobble and noise.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let wob = sin(uv.y * 12.0 + t * 3.0) * 0.0015 + sin(t * 37.0) * 0.0008;
    let band_y = fract(t * 0.15);
    let in_band = exp(-pow((uv.y - band_y) * 18.0, 2.0));
    let tear = in_band * (hash(vec2<f32>(floor(uv.y * frame.size.y / 2.0), floor(t * 30.0)), 280.0) - 0.5) * 0.04;
    let q = uv + vec2<f32>(wob + tear, 0.0);
    let y = luma(sample(q).rgb);
    // Chroma at half sharpness, late by a few pixels.
    let o = vec2<f32>(4.0, 0.0) / frame.size;
    let chroma = (sample(q + o).rgb + sample(q + o * 2.0).rgb + sample(q + o * 3.0).rgb) / 3.0;
    let col = vec3<f32>(y) + (chroma - vec3<f32>(luma(chroma))) * 0.85;
    let noise = (hash(floor(uv * frame.size), fract(t * 5.3)) - 0.5) * 0.08 + in_band * 0.15 * hash(floor(uv * frame.size * 0.5), fract(t * 3.1));
    let look = contrast(col, 0.9) * vec3<f32>(1.02, 0.98, 1.04) + vec3<f32>(noise);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
