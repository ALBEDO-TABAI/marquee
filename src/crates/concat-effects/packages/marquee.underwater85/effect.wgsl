struct Params { amount: f32 }
// 水下: rippling light, red absorbed, a blue-green cast.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let wave = vec2<f32>(sin(uv.y * 26.0 + t * 1.7) * 0.006, cos(uv.x * 19.0 + t * 1.3) * 0.004) * a;
    let w = sample(uv + wave);
    let k = abs(value_noise(p * 9.0 + vec2<f32>(t * 0.5, t * 0.3), 3.0) - value_noise(p * 9.0 - vec2<f32>(t * 0.4, -t * 0.2), 4.0));
    let caustic = (1.0 - smoothstep(0.0, 0.06, k)) * 0.3 * (1.0 - uv.y * 0.6);
    let depth = mix(1.0, 0.7, uv.y);
    let look = (w.rgb * vec3<f32>(0.42, 0.88, 1.08) + vec3<f32>(0.0, 0.05, 0.12) + vec3<f32>(0.6, 0.95, 1.0) * caustic) * depth;
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
