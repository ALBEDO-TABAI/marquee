struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let a = params.amount / 100.0;
    var p = uv * 2.0 - vec2<f32>(1.0);
    let wobble = 1.0 + 0.03 * sin(frame.clip_time * 4.0 + f32(25));
    p = p / wobble;
    let corner = min(min(length(p - vec2<f32>(-0.7, -0.55)), length(p - vec2<f32>(0.7, -0.55))),
                     min(length(p - vec2<f32>(-0.7, 0.55)), length(p - vec2<f32>(0.7, 0.55)))) - 0.06;
    let bar = abs(p.y) - (0.62 - f32(0) * 0.04);
    let d = min(corner, abs(bar) - 0.018);
    let shape = 1.0 - smoothstep(-0.015, 0.02, d);
    let col = vec3<f32>(0.004, 0.725, 0.776);
    let over = mix(src.rgb, col, shape * 0.9);
    return vec4<f32>(mix(src.rgb, over, a), max(src.a, shape * a));
}
