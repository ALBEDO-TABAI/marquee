fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = clamp(progress, 0.0, 1.0);
    let s = 0.02 * (1.0 - abs(t * 2.0 - 1.0));
    let src = mix(from_at(uv), to_at(uv), t);
    let r = mix(from_at(uv + vec2<f32>(s, 0.0)), to_at(uv + vec2<f32>(s, 0.0)), t).r;
    let b = mix(from_at(uv - vec2<f32>(s, 0.0)), to_at(uv - vec2<f32>(s, 0.0)), t).b;
    return vec4<f32>(r, src.g, b, src.a);
}
