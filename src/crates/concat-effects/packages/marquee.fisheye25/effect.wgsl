struct Params { amount: f32 }
// 鱼眼: a round fisheye view, the middle swollen, the world bent into a circle on black.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let d = (uv - vec2<f32>(0.5)) * vec2<f32>(aspect, 1.0);
    let r = length(d) / 0.5;
    // The middle magnified, the rim squeezed: a source radius that grows
    // faster than the drawn one towards the circle's edge.
    let rs = pow(r, 1.0 + 0.9 * a) * (1.0 + 0.25 * a);
    let q = vec2<f32>(0.5) + normalize(d + vec2<f32>(1e-6)) * rs * 0.5 / vec2<f32>(aspect, 1.0);
    let s = sample(clamp(q, vec2<f32>(0.0), vec2<f32>(1.0)));
    let rim = 1.0 - smoothstep(0.97, 1.0, r);
    let look = s.rgb * rim;
    return vec4<f32>(mix(c.rgb, look, min(a * 1.5, 1.0)), c.a);
}
