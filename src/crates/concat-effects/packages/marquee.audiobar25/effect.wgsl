struct Params { amount: f32 }
// 频谱条: a row of spectrum bars dancing along the bottom.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let n = 28.0;
    let x = uv.x * n;
    let bar = floor(x);
    let gap = abs(fract(x) - 0.5);
    let beat = pow(1.0 - fract(t * 2.0), 3.0);
    let level = 0.15 + 0.55 * value_noise(vec2<f32>(bar * 0.7, t * 3.5), 1.0) * (0.6 + 0.4 * beat)
        + 0.2 * hash(vec2<f32>(bar, floor(t * 12.0)), 2.0);
    let top = 1.0 - level * 0.42;
    let lit = step(top, uv.y) * step(gap, 0.36);
    // Bars split into segments, coloured along the row.
    let seg = step(0.25, fract((1.0 - uv.y) * 40.0));
    let hue = vec3<f32>(0.5) + 0.5 * cos(6.2832 * (vec3<f32>(0.0, 0.33, 0.67) + uv.x * 0.8 + t * 0.1));
    let floor_dark = mix(1.0, 0.55, smoothstep(0.55, 1.0, uv.y));
    let look = mix(c.rgb * floor_dark, hue * 1.15, lit * seg * 0.92);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
