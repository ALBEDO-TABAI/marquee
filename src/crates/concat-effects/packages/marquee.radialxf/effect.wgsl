// 径向模糊: a radial zoom blur through the cut.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // Streaks towards the middle, longest at the cut.
    let t = smoothstep(0.0, 1.0, p);
    let toward = vec2<f32>(0.5) - uv;
    let k = 0.18 * sin(3.14159265 * p) / 8.0;
    var sum = vec4<f32>(0.0);
    for (var i: i32 = 0; i < 9; i++) {
        let q = uv + toward * (f32(i) * k);
        sum += mix(from_at(q), to_at(q), t);
    }
    return sum / 9.0;
}
