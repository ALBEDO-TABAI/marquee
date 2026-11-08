fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {{
    let d = (uv - vec2<f32>(0.5)) * (1.0 + progress * 0.45) + vec2<f32>(0.5);
    let a = from_at(clamp(d, vec2<f32>(0.0), vec2<f32>(1.0)));
    return mix(a, to_at(uv), smoothstep(0.15, 0.95, progress));
}}
