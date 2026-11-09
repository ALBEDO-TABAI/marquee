// 运镜切: a whip pan from one picture to the next.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // A whip pan: both pictures slide left in one move, streaked.
    let s = smoothstep(0.0, 1.0, p);
    let blur = 0.06 * sin(3.14159265 * p) / 6.0;
    var sum = vec4<f32>(0.0);
    for (var i: i32 = -3; i <= 3; i++) {
        let x = uv.x + s + f32(i) * blur;
        let from_c = from_at(vec2<f32>(clamp(x, 0.0, 1.0), uv.y));
        let to_c = to_at(vec2<f32>(clamp(x - 1.0, 0.0, 1.0), uv.y));
        sum += select(to_c, from_c, x < 1.0);
    }
    return sum / 7.0;
}
