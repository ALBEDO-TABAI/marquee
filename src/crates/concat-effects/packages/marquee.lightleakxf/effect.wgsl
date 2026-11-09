// 漏光过渡: a warm light leak across a dissolve.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // A warm leak washes in from the top left and drains away.
    let t = smoothstep(0.2, 0.8, p);
    let base = mix(from_at(uv), to_at(uv), t);
    let spot = vec2<f32>(mix(-0.3, 1.1, p), 0.15);
    let leak = sin(3.14159265 * p) * (1.0 - smoothstep(0.0, 0.9, distance(uv, spot)));
    let over = clamp(vec3<f32>(1.0, 0.5, 0.22) * leak * 1.4, vec3<f32>(0.0), vec3<f32>(1.0));
    return vec4<f32>(vec3<f32>(1.0) - (vec3<f32>(1.0) - base.rgb) * (vec3<f32>(1.0) - over), base.a);
}
