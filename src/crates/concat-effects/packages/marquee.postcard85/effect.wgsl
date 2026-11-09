struct Params { amount: f32 }
// 旅途明信片: a white border, warm print and a stamp.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    // A white border, a warm print, a red stamp in the top right corner.
    let x = min(uv.x, 1.0 - uv.x) * aspect;
    let border = 1.0 - smoothstep(0.045, 0.05, min(x, min(uv.y, 1.0 - uv.y)));
    let sx = (uv.x - 0.86) * aspect;
    let sy = uv.y - 0.15;
    let stamp = (1.0 - smoothstep(0.07, 0.075, abs(sx))) * (1.0 - smoothstep(0.085, 0.09, abs(sy)));
    let teeth = step(0.5, fract((sx + sy) * 90.0));
    let edge = stamp * (1.0 - (1.0 - smoothstep(0.055, 0.06, abs(sx))) * (1.0 - smoothstep(0.07, 0.075, abs(sy))));
    let stamp_rgb = mix(vec3<f32>(0.82, 0.25, 0.2), vec3<f32>(0.97, 0.94, 0.88), edge * teeth);
    let warm = c.rgb * vec3<f32>(1.05, 1.0, 0.9);
    let look = mix(mix(warm, stamp_rgb, stamp), vec3<f32>(0.97, 0.96, 0.92), border);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
