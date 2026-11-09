struct Params { amount: f32 }
// 软焦宠物: a soft, warm portrait focus with pastel bokeh drifting around the edges.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let d = length((uv - vec2<f32>(0.5)) * vec2<f32>(aspect, 1.0));
    let soft = mix(c.rgb, soften(uv, frame.size.y / 30.0), 0.35 + 0.65 * smoothstep(0.2, 0.6, d));
    let warm = matte(soft * vec3<f32>(1.06, 1.0, 0.94), 0.06, 1.0);
    var spots = vec3<f32>(0.0);
    let q = p * 5.0 + vec2<f32>(t * 0.15, sin(t * 0.4) * 0.2);
    let id = floor(q);
    let f = fract(q) - vec2<f32>(0.5) - (vec2<f32>(hash(id, 190.0), hash(id, 191.0)) - vec2<f32>(0.5)) * 0.4;
    let r = 0.16 + 0.12 * hash(id, 192.0);
    let on = step(0.45, hash(id, 193.0)) * smoothstep(0.25, 0.55, d);
    spots = mix(vec3<f32>(1.0, 0.8, 0.85), vec3<f32>(1.0, 0.95, 0.75), hash(id, 194.0)) * smoothstep(r, r * 0.75, length(f)) * on * 0.45;
    let look = screen(warm, spots);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
