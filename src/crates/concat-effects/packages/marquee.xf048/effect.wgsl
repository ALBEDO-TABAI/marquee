fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let edge = 1.0 - (uv.x + uv.y) * 0.5;
    let m = smoothstep(progress - 0.250, progress + 0.250, edge);
    return mix(to_at(uv), from_at(uv), m);
}
