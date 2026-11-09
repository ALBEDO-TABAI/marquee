struct Params { amount: f32 }
// 声纹环: a ring of sound bars around the middle, pulsing to the beat.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let d = p - vec2<f32>(0.5 * aspect, 0.5);
    let r = length(d);
    let ang = atan2(d.y, d.x) / 6.2832 + 0.5;
    let n = 64.0;
    let seg = floor(ang * n);
    let beat = pow(1.0 - fract(t * 2.0), 3.0);
    let len = 0.04 + 0.12 * value_noise(vec2<f32>(seg * 0.5, t * 4.0), 5.0) * (0.6 + 0.4 * beat);
    let base = 0.2 + 0.02 * beat;
    let thin = step(abs(fract(ang * n) - 0.5), 0.3);
    let bar = step(base, r) * step(r, base + len) * thin;
    let circle = exp(-abs(r - base) * 260.0);
    let hue = vec3<f32>(0.5) + 0.5 * cos(6.2832 * (vec3<f32>(0.0, 0.33, 0.67) + ang + t * 0.15));
    let glow = exp(-abs(r - base - len * 0.5) * 30.0) * 0.25;
    let look = mix(c.rgb * 0.78, hue * 1.3, bar) + hue * (circle + glow);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
