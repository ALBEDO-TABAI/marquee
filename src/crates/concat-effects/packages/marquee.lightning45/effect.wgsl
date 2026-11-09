struct Params { amount: f32 }
// 闪电: a storm - the picture darkened and blued, a bolt striking with a flash.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let ph = loop_phase(1.8);
    let strike = step(ph, 0.12) + step(0.18, ph) * step(ph, 0.24) + step(0.82, ph) * step(ph, 0.95);
    let round_no = floor(look_time() / 1.8);
    let x0 = 0.3 + 0.4 * hash(vec2<f32>(round_no, 0.0), 100.0);
    var x = x0;
    var y = 0.0;
    var d = 10.0;
    // A jagged bolt: twelve kinked segments from the top.
    for (var i = 0; i < 12; i++) {
        let y1 = y + 0.075;
        let x1 = x + (hash(vec2<f32>(round_no, f32(i)), 101.0) - 0.5) * 0.12;
        let pa = uv - vec2<f32>(x, y);
        let ba = vec2<f32>(x1 - x, y1 - y);
        let h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
        let e = (pa - ba * h) * vec2<f32>(aspect, 1.0);
        d = min(d, length(e));
        x = x1;
        y = y1;
    }
    let bolt = (exp(-d * 500.0) * 1.5 + exp(-d * 40.0) * 0.5) * strike;
    let storm = c.rgb * vec3<f32>(0.6, 0.66, 0.85) * (1.0 + strike * 0.9);
    let look = storm + vec3<f32>(0.8, 0.88, 1.0) * bolt;
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
