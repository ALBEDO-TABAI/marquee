struct Params { amount: f32 }
// 变形光斑: a blue horizontal streak flare across the lights.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    // The brights smeared sideways, as an anamorphic lens does.
    var streak = vec3<f32>(0.0);
    for (var i = -10; i <= 10; i++) {
        let s = sample(uv + vec2<f32>(f32(i) * 0.022, 0.0)).rgb;
        let w = exp(-abs(f32(i)) * 0.18);
        streak += max(s - vec3<f32>(0.86), vec3<f32>(0.0)) * w;
    }
    streak = vec3<f32>(luma(streak)) * vec3<f32>(0.35, 0.65, 1.3) * 0.3;
    // And the flare itself: a source drifting across, a long blue line.
    let src = vec2<f32>((0.3 + 0.12 * sin(t * 0.6)) * aspect, 0.32);
    let d = p - src;
    let line = exp(-abs(d.y) * 90.0) * exp(-abs(d.x) * 1.1);
    let core = exp(-length(d) * 18.0);
    let flare = vec3<f32>(0.25, 0.55, 1.5) * line * 2.4 + vec3<f32>(0.9, 0.95, 1.2) * core;
    let look = screen(c.rgb, max(streak + flare, vec3<f32>(0.0)));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
