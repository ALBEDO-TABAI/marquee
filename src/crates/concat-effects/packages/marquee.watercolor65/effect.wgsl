struct Params { amount: f32 }
// 水彩: soft washes of colour bleeding on textured paper.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let wob = (vec2<f32>(value_noise(p * 14.0, 180.0), value_noise(p * 14.0 + vec2<f32>(4.0), 181.0)) - vec2<f32>(0.5)) * 0.02;
    let washed = soften(uv + wob, max(frame.size.y / 70.0, 2.0));
    let flat = floor(washed * 6.0 + vec3<f32>(0.5)) / 6.0;
    let pigment = mix(washed, flat, 0.5);
    let edge = smoothstep(0.1, 0.5, edge_at(uv + wob)) * 0.35;
    let paper = 0.92 + 0.08 * value_noise(uv * frame.size / 3.0, 182.0);
    let light = mix(pigment, vec3<f32>(1.0), 0.18) * (1.0 - edge) * paper;
    let look = saturation(light, 1.1);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
