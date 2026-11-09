struct Params { amount: f32 }
// 旅途漏光: golden afternoon sun pouring in from the top right corner.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let src = vec2<f32>(1.0 * aspect + 0.05, -0.05);
    let d = length(p - src);
    let sweep = 0.5 + 0.5 * sin(t * 0.6);
    let sun = exp(-d * (3.6 - 0.8 * sweep)) * 1.4;
    let ring = exp(-abs(d - 0.75) * 18.0) * 0.18;
    let rainbow = vec3<f32>(0.5) + 0.5 * cos(6.2832 * (vec3<f32>(0.0, 0.33, 0.67) + d * 2.5));
    let gold = vec3<f32>(1.0, 0.72, 0.32);
    let graded = c.rgb * vec3<f32>(1.05, 1.0, 0.9);
    let look = screen(graded, gold * sun + rainbow * ring);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
