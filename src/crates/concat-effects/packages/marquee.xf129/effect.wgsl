// 车票擦除: a downward wipe with a torn zigzag edge.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // A ticket tear: a downward wipe with a zigzag edge.
    let zig = abs(fract(uv.x * 18.0) - 0.5) * 0.05;
    let m = step(uv.y + zig, p * 1.06);
    return mix(from_at(uv), to_at(uv), m);
}
