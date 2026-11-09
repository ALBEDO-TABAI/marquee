struct Params { amount: f32 }
// Golden-angle disc taps: the lens blur's aperture, `n` of them.
fn disc_tap(i: i32, n: i32) -> vec2<f32> {
    let r = sqrt((f32(i) + 0.5) / f32(n));
    let th = f32(i) * 2.39996323;
    return vec2<f32>(cos(th), sin(th)) * r;
}
// 散景: a fast lens wide open - everything melted, the lights into round discs.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let r = frame.size.y / 20.0 * (0.25 + 0.75 * a);
    var sum = vec3<f32>(0.0);
    var weight = 0.0;
    for (var i = 0; i < 48; i++) {
        let s = sample(uv + disc_tap(i, 48) * r / frame.size).rgb;
        let w = 1.0 + 12.0 * pow(smoothstep(0.55, 1.0, luma(s)), 2.0);
        sum += s * w;
        weight += w;
    }
    let look = sum / weight;
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
