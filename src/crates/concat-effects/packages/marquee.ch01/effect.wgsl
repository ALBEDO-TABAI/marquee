struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let a = params.amount / 100.0;
    var p = uv * 2.0 - vec2<f32>(1.0);
    let wobble = 1.0 + 0.03 * sin(frame.clip_time * 4.0 + f32(1));
    p = p / wobble;
    let boxp = abs(p - vec2<f32>(0.0, 0.06)) - vec2<f32>(0.62, 0.32);
    let bubble = length(max(boxp, vec2<f32>(0.0))) + min(max(boxp.x, boxp.y), 0.0) - 0.14;
    // A short tail under the bubble (uv runs down), not a wedge to the edge.
    let tail = max(abs(p.x + 0.18) - (0.80 - p.y) * 0.45, 0.42 - p.y);
    let d = min(bubble, tail);
    let shape = 1.0 - smoothstep(-0.015, 0.02, d);
    let col = vec3<f32>(0.004, 0.725, 0.776);
    let over = mix(src.rgb, col, shape * 0.9);
    return vec4<f32>(mix(src.rgb, over, a), max(src.a, shape * a));
}
