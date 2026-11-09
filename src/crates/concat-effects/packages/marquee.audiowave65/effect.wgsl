struct Params { amount: f32 }
// 波形: a glowing sound wave running across the middle.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let x = uv.x;
    let env = sin(x * 3.1416);
    let amp = 0.12 * (0.5 + 0.5 * value_noise(vec2<f32>(t * 2.0, 0.0), 6.0));
    let y = 0.5 + env * amp * (sin(x * 31.0 + t * 9.0) * 0.6 + sin(x * 73.0 - t * 13.0) * 0.3 + sin(x * 11.0 + t * 4.0) * 0.4);
    let dy = abs(uv.y - y) * frame.size.y;
    let line = 1.0 - smoothstep(1.0, 2.5, dy);
    let glow = exp(-dy / (frame.size.y * 0.02));
    let col = mix(vec3<f32>(0.2, 0.9, 1.0), vec3<f32>(1.0, 0.35, 0.9), x);
    let look = c.rgb * 0.82 + col * (line * 1.2 + glow * 0.6);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
