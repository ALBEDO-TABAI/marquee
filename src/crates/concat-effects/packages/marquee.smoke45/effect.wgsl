struct Params { amount: f32 }
// 烟雾: grey smoke curling up from below.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let rise = vec2<f32>(0.0, t * 0.12);
    let warp = vec2<f32>(fbm(p * 2.0 + rise, 150.0), fbm(p * 2.0 + rise + vec2<f32>(5.2, 1.3), 151.0)) - vec2<f32>(0.5);
    let n = fbm(p * 2.6 + warp * 1.6 + vec2<f32>(0.0, t * 0.22), 152.0);
    let rise_mask = smoothstep(0.0, 1.0, uv.y) * 0.9 + 0.1;
    let thick = smoothstep(0.3, 0.7, n) * rise_mask;
    let grey = vec3<f32>(0.78, 0.78, 0.8);
    let look = mix(c.rgb * (1.0 - thick * 0.25), grey, thick * 0.92);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
