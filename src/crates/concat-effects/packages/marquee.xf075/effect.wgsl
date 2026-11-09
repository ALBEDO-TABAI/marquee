// 左摇: a whip pan to the left - the scene rushes right, smeared, into the next.
fn strip(q: vec2<f32>, dir: vec2<f32>) -> vec4<f32> {
    // The two pictures side by side along the camera's move.
    let inside = all(q >= vec2<f32>(0.0)) && all(q <= vec2<f32>(1.0));
    return select(to_at(q - dir), from_at(q), inside);
}

fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let dir = vec2<f32>(-1.0, 0.0);
    let t = smoothstep(0.0, 1.0, progress);
    let pos = uv + dir * t;
    // A whip: the faster the move, the longer the smear along it.
    let smear = sin(progress * 3.1416) * 0.12;
    var sum = vec4<f32>(0.0);
    for (var i = 0; i < 16; i++) {
        sum += strip(pos + dir * (f32(i) / 15.0 - 0.5) * smear, dir);
    }
    return sum / 16.0;
}
