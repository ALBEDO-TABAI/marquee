struct Params { amount: f32 }
// 投影叠影: an old film projector - flicker, gate weave, dust and a ghost frame.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let tick = floor(t * 18.0);
    let weave = (vec2<f32>(hash(vec2<f32>(tick, 1.0), 120.0), hash(vec2<f32>(tick, 2.0), 121.0)) - vec2<f32>(0.5)) * vec2<f32>(0.003, 0.006);
    let s = sample(uv + weave);
    let ghost = sample(uv + weave + vec2<f32>(0.012, 0.0)).rgb;
    let flicker = 0.9 + 0.12 * hash(vec2<f32>(tick, 3.0), 122.0);
    var img = mix(s.rgb, ghost, 0.3) * flicker;
    img = mix(vec3<f32>(luma(img)), img, 0.6) * vec3<f32>(1.08, 1.0, 0.84);
    let specks = step(0.998, hash(floor(uv * frame.size / 2.0) + vec2<f32>(tick * 13.0), 123.0));
    let hair = exp(-abs(uv.x - hash(vec2<f32>(floor(t * 2.0), 4.0), 124.0)) * 900.0) * step(0.5, hash(vec2<f32>(floor(t * 2.0), 5.0), 125.0));
    let hot = 1.0 - smoothstep(0.2, 0.75, length((uv - vec2<f32>(0.5)) * vec2<f32>(aspect, 1.0)));
    let look = img * (0.55 + 0.55 * hot) * (1.0 - specks * 0.7 - hair * 0.6);
    return vec4<f32>(mix(c.rgb, look, a), s.a);
}
