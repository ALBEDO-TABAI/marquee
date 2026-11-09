struct Params { amount: f32 }
// 综艺贴条: striped variety-show tape strips sliding into the corners.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let ph = min(loop_phase(2.0) * 4.0, 1.0);
    let slide = 1.0 - pow(1.0 - ph, 3.0);
    let k = 0.42;
    let r1 = vec2<f32>(p.x * cos(k) + p.y * sin(k), -p.x * sin(k) + p.y * cos(k));
    let band1 = step(abs(r1.y - 0.02), 0.045) * step(r1.x, -0.2 + slide * 0.55);
    let r2 = vec2<f32>(p.x * cos(k) + p.y * sin(k), -p.x * sin(k) + p.y * cos(k)) - vec2<f32>(aspect * 0.9, 0.62);
    let band2 = step(abs(r2.y + 0.25), 0.045) * step(-slide * 0.55 + 0.2, r2.x);
    let stripes1 = step(0.5, fract(r1.x * 18.0 - r1.y * 6.0));
    let stripes2 = step(0.5, fract(r2.x * 18.0 + r2.y * 6.0));
    var look = c.rgb;
    look = mix(look, mix(vec3<f32>(1.0, 0.86, 0.1), vec3<f32>(0.12), stripes1), band1);
    look = mix(look, mix(vec3<f32>(1.0, 0.3, 0.55), vec3<f32>(1.0), stripes2), band2);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
