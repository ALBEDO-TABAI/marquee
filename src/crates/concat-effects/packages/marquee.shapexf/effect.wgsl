fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {{
    let r = length(uv - vec2<f32>(0.5));
    let t = smoothstep(progress - 0.08, progress + 0.08, 0.75 - r);
    return mix(from_at(uv), to_at(uv), t);
}}
