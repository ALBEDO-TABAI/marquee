fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = smoothstep(0.0, 1.0, progress);
    let flash = 0.85 * (1.0 - abs(t * 2.0 - 1.0));
    let leak = vec3<f32>(1.00, 0.35, 0.05) * flash;
    let a = from_at(uv);
    let b = to_at(uv);
    let mixed = mix(a, b, t);
    return vec4<f32>(clamp(mixed.rgb + leak, vec3<f32>(0.0), vec3<f32>(1.0)), mixed.a);
}
