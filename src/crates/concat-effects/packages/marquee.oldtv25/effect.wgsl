struct Params { amount: f32 }
// 旧电视: a black and white set - snow, scanlines, a rolling bar, a wobble.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let wob = sin(uv.y * 40.0 + t * 7.0) * 0.002 + step(0.97, hash(vec2<f32>(floor(uv.y * 60.0), floor(t * 15.0)), 240.0)) * 0.02;
    let s = sample(uv + vec2<f32>(wob, 0.0));
    let l = luma(s.rgb);
    let snow = hash(floor(uv * frame.size), fract(t * 9.17)) - 0.5;
    let line = 0.8 + 0.2 * sin(uv.y * frame.size.y * 3.1416 / 1.5);
    let bar = 1.0 + 0.18 * exp(-pow(fract(uv.y - t * 0.3) - 0.5, 2.0) * 60.0);
    let look = vignette(vec3<f32>(l * line * bar + snow * 0.22), uv, 0.75) * vec3<f32>(0.95, 1.0, 1.02);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
