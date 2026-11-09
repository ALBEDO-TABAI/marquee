struct Params { amount: f32 }
// A four-pointed glint at `d` from its centre, `r` across: a hot core and
// two thin crossed rays.
fn glint(d: vec2<f32>, r: f32) -> f32 {
    let q = abs(d) / max(r, 1e-4);
    let rays = max(1.0 - q.x * 0.9 - q.y * 18.0, 0.0) + max(1.0 - q.y * 0.9 - q.x * 18.0, 0.0);
    let core = exp(-dot(q, q) * 40.0);
    return min(rays * rays + core, 1.5);
}
// 碎金闪: fine gold glitter twinkling on the bright parts of the picture.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let cell = max(frame.size.y / 70.0, 3.0);
    let q = uv * frame.size / cell;
    let id = floor(q);
    let f = (fract(q) - vec2<f32>(0.5)) * cell;
    let tw = pow(max(sin(t * (3.0 + 5.0 * hash(id, 250.0)) + hash(id, 251.0) * 6.28), 0.0), 8.0);
    let bright = smoothstep(0.35, 0.85, luma(c.rgb));
    let on = step(0.45, hash(id, 252.0)) * tw * (0.45 + 0.55 * bright);
    let g = glint(f / cell, 0.8 + 0.6 * hash(id, 253.0)) * on * 1.5;
    let gold = vec3<f32>(1.0, 0.82, 0.4);
    let look = screen(c.rgb * vec3<f32>(1.04, 1.0, 0.92), gold * min(g, 1.2));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
