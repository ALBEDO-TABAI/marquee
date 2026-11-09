// 雾面过渡: fog rolls in over the cut and lifts.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // A pale fog rolls in, hides the cut, and lifts.
    let t = smoothstep(0.35, 0.65, p);
    let base = mix(from_at(uv), to_at(uv), t);
    let drift = 0.5 + 0.5 * sin(uv.x * 5.0 + uv.y * 3.0 + p * 4.0);
    let fog = sin(3.14159265 * p) * (0.65 + 0.2 * drift);
    return vec4<f32>(mix(base.rgb, vec3<f32>(0.78, 0.8, 0.82), fog), base.a);
}
