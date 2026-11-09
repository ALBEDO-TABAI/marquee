// 模糊叠化: a blurred dissolve.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // Both pictures blurred towards the middle of the cut, and crossed.
    let t = smoothstep(0.0, 1.0, p);
    let r = 0.03 * sin(3.14159265 * p) / 3.0;
    var sum = vec4<f32>(0.0);
    for (var y: i32 = -3; y <= 3; y++) {
        for (var x: i32 = -3; x <= 3; x++) {
            let o = vec2<f32>(f32(x), f32(y)) * r;
            sum += mix(from_at(uv + o), to_at(uv + o), t);
        }
    }
    return sum / 49.0;
}
