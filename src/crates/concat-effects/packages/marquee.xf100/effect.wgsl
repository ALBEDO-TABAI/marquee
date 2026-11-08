fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = clamp(progress, 0.0, 1.0);
    let cell = floor(uv * 12.0);
    let n = fract(sin(dot(cell, vec2<f32>(12.1, 78.2))) * 43758.5);
    let m = select(0.0, 1.0, n < t);
    return mix(from_at(uv), to_at(uv), m);
}
