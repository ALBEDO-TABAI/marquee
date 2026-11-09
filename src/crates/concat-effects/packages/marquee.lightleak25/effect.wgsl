struct Params { amount: f32 }
// 漏光: warm red and orange light leaking in from the edges, drifting.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let n1 = value_noise(vec2<f32>(uv.x * 1.5 + t * 0.25, uv.y * 1.2), 90.0);
    let n2 = value_noise(vec2<f32>(uv.x * 1.2 - t * 0.18, uv.y * 1.6 + 3.0), 91.0);
    let left = smoothstep(0.55, 0.0, uv.x) * n1;
    let right = smoothstep(0.45, 1.0, uv.x) * n2;
    let leak = vec3<f32>(1.0, 0.3, 0.1) * left * 1.4 + vec3<f32>(1.0, 0.65, 0.2) * right * 1.3 + vec3<f32>(1.0, 0.9, 0.5) * pow(left + right, 3.0) * 0.4;
    let look = screen(c.rgb, min(leak, vec3<f32>(1.2)));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
