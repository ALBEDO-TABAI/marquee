struct Params { amount: f32 }
// 丁达尔: shafts of warm light falling from the top corner.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let src = vec2<f32>(0.15, -0.05);
    var shafts = 0.0;
    var w = 1.0;
    let step_uv = (uv - src) / 28.0;
    var q = uv;
    for (var i = 0; i < 28; i++) {
        q -= step_uv;
        shafts += smoothstep(0.6, 1.0, luma(sample(q).rgb)) * w;
        w *= 0.95;
    }
    shafts = shafts / 14.0;
    let d = uv - src;
    let ang = atan2(d.x * aspect, d.y);
    let beams = smoothstep(0.45, 0.95, value_noise(vec2<f32>(ang * 9.0 + t * 0.15, 0.0), 60.0)) * exp(-length(d) * 1.4);
    let light = vec3<f32>(1.0, 0.86, 0.6) * (shafts * 0.6 + beams * 0.9);
    let look = screen(c.rgb * 0.88, light);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
