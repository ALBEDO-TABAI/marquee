fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let edge = uv.x;
    let m = smoothstep(progress - 0.020, progress + 0.020, edge);
    return mix(to_at(uv), from_at(uv), m);
}
