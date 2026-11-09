struct Params { amount: f32 }
// 幻灯投影: a slide thrown on a wall in a dark room, clicking to the next.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let ph = loop_phase(2.0);
    let slide = 1.0 - smoothstep(0.0, 0.12, ph);
    let q = (uv - vec2<f32>(0.5)) / 0.84 + vec2<f32>(0.5) + vec2<f32>(slide * 0.9, 0.0);
    let inside = smoothstep(0.0, 0.01, q.x) * smoothstep(1.0, 0.99, q.x) * smoothstep(0.0, 0.015, q.y) * smoothstep(1.0, 0.985, q.y);
    let s = sample(clamp(q, vec2<f32>(0.0), vec2<f32>(1.0))).rgb;
    let hot = 1.0 - smoothstep(0.1, 0.8, length((uv - vec2<f32>(0.5)) * vec2<f32>(aspect, 1.0)));
    let lamp = vec3<f32>(1.08, 1.0, 0.82) * (0.7 + 0.45 * hot);
    let click = exp(-ph * 30.0) * 0.4;
    let wall = vec3<f32>(0.06, 0.055, 0.05) + vec3<f32>(0.12, 0.1, 0.07) * hot;
    let look = mix(wall, s * lamp, inside) + vec3<f32>(click);
    let over = max(c.rgb - vec3<f32>(1.0), vec3<f32>(0.0));
    return vec4<f32>(mix(c.rgb, look + over, a), c.a);
}
