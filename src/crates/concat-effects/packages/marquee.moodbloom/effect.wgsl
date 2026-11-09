// bloom 叠化: a dissolve that blooms at its middle.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // The dissolve blooms: highlights spill light at the middle.
    let t = smoothstep(0.0, 1.0, p);
    let base = mix(from_at(uv), to_at(uv), t);
    let l = luma(base.rgb);
    let bloom = sin(3.14159265 * p) * (0.06 + l * l * 0.45);
    return vec4<f32>(base.rgb + vec3<f32>(1.0, 0.95, 0.9) * bloom, base.a);
}
