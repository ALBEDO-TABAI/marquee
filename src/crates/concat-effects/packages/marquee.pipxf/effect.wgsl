// 画中画切入: the next picture grows from a framed inset.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // The incoming picture grows from a framed inset in the middle.
    let k = smoothstep(0.0, 1.0, p);
    let half = mix(0.12, 0.5, k);
    let q = (uv - vec2<f32>(0.5)) / (2.0 * half) + vec2<f32>(0.5);
    let d = max(abs(uv.x - 0.5), abs(uv.y - 0.5));
    let inside = 1.0 - smoothstep(half - 0.002, half, d);
    let rim = (1.0 - smoothstep(half, half + 0.012 * (1.0 - k), d)) - inside;
    let behind = from_at(uv);
    let back = vec4<f32>(behind.rgb * (1.0 - 0.4 * k), behind.a);
    let shown = mix(back, to_at(clamp(q, vec2<f32>(0.0), vec2<f32>(1.0))), inside);
    return vec4<f32>(mix(shown.rgb, vec3<f32>(1.0), clamp(rim, 0.0, 1.0)), shown.a);
}
