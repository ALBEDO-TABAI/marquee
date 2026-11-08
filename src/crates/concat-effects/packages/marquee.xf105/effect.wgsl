fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = smoothstep(0.0, 1.0, progress);
    let ang = t * 3.14159265;
    let cs = cos(ang); let sn = sin(ang);
    let q = uv - vec2<f32>(0.5);
    let r = vec2<f32>(q.x * cs - q.y * sn, q.x * sn + q.y * cs) + vec2<f32>(0.5);
    return mix(from_at(r), to_at(uv), t);
}
