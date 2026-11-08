fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = smoothstep(0.0, 1.0, progress);
    let o = 0.000 * sin(t * 3.14159265);
    let off = vec2<f32>(1.0, -1.0) * (t + o);
    let a = from_at(uv + off);
    let b = to_at(uv - (vec2<f32>(1.0, -1.0) - off));
    return mix(a, b, t);
}
