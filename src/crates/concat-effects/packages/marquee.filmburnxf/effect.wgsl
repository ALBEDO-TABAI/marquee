// 胶片灼烧: an orange film burn sweeps across the cut.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // A hot orange burn spreads from the left edge and dies away.
    let t = smoothstep(0.3, 0.7, p);
    let base = mix(from_at(uv), to_at(uv), t);
    let reach = mix(-0.3, 1.3, p);
    let wobble = 0.08 * sin(uv.y * 9.0 + p * 6.0);
    let burn = sin(3.14159265 * p) * (1.0 - smoothstep(0.0, 0.45, uv.x - reach + wobble + 0.2));
    let fire = vec3<f32>(1.0, 0.45, 0.12) * burn * 0.9 + vec3<f32>(1.0, 0.9, 0.7) * burn * burn * 0.35;
    return vec4<f32>(base.rgb + fire, base.a);
}
