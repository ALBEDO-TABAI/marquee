struct Params { amount: f32 }
// 飘雪: snowflakes drifting down, near ones big and soft, the picture cooled.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    var flakes = 0.0;
    for (var k = 0; k < 4; k++) {
        let layer = f32(k);
        let scale = 5.0 + layer * 4.0;
        let speed = 0.06 + 0.03 * layer;
        let q = p * scale + vec2<f32>(sin(t * 0.8 + p.y * 3.0 + layer) * 0.35, -t * speed * scale);
        let id = floor(q);
        if (hash(id, 160.0 + layer) < 0.4) { continue; }
        let f = fract(q) - vec2<f32>(0.5) - (vec2<f32>(hash(id, 161.0 + layer), hash(id, 162.0 + layer)) - vec2<f32>(0.5)) * 0.6;
        let r = (0.07 + 0.06 * hash(id, 163.0 + layer)) * (1.3 - layer * 0.2);
        flakes += smoothstep(r, r * 0.35, length(f)) * (1.0 - layer * 0.15);
    }
    let cold = c.rgb * vec3<f32>(0.94, 0.98, 1.06) + vec3<f32>(0.03, 0.04, 0.06);
    let look = mix(cold, vec3<f32>(1.0), min(flakes, 1.0));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
