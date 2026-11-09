struct Params { amount: f32 }
// 油画: thick painted strokes on canvas.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    // Kuwahara: each pixel takes the calmest of the four quarters around it.
    let r = max(frame.size.y / 240.0, 1.0) * (0.4 + 0.6 * a);
    var best = vec3<f32>(0.0);
    var least = 1e9;
    for (var qd = 0; qd < 4; qd++) {
        let sx = select(-1.0, 1.0, (qd & 1) == 1);
        let sy = select(-1.0, 1.0, (qd & 2) == 2);
        var sum = vec3<f32>(0.0);
        var sq = vec3<f32>(0.0);
        for (var j = 0; j < 4; j++) {
            for (var i = 0; i < 4; i++) {
                let o = vec2<f32>(sx * f32(i), sy * f32(j)) * r / frame.size;
                let s = sample(uv + o).rgb;
                sum += s;
                sq += s * s;
            }
        }
        let mean = sum / 16.0;
        let v = sq / 16.0 - mean * mean;
        let spread = v.r + v.g + v.b;
        if (spread < least) { least = spread; best = mean; }
    }
    let canvas = (value_noise(uv * frame.size / 2.0, 110.0) - 0.5) * 0.06 + (step(0.5, fract(uv.x * frame.size.x / 3.0)) - 0.5) * 0.02;
    let look = saturation(best, 1.15) + vec3<f32>(canvas);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
