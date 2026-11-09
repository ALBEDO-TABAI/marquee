struct Params { amount: f32 }
// Golden-angle disc taps: the lens blur's aperture, `n` of them.
fn disc_tap(i: i32, n: i32) -> vec2<f32> {
    let r = sqrt((f32(i) + 0.5) / f32(n));
    let th = f32(i) * 2.39996323;
    return vec2<f32>(cos(th), sin(th)) * r;
}
// 移轴: a sharp band across the middle, the top and bottom blurred - a miniature.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let off = abs(uv.y - 0.55);
    let k = smoothstep(0.1, 0.38, off) * a;
    let r = frame.size.y / 22.0 * k;
    var sum = vec3<f32>(0.0);
    for (var i = 0; i < 32; i++) {
        sum += sample(uv + disc_tap(i, 32) * r / frame.size).rgb;
    }
    let toy = contrast(saturation(sum / 32.0, 1.35), 1.08);
    return vec4<f32>(mix(c.rgb, toy, min(a * 2.0, 1.0)), c.a);
}
