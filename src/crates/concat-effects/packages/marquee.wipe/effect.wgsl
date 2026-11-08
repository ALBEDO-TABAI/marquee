fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {{
    let edge = progress;
    let p = uv.x;
    let t = smoothstep(edge - 0.12, edge + 0.12, p);
    return mix(from_at(uv), to_at(uv), t);
}}
