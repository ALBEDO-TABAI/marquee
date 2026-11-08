struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let src = sample(uv);
    let a = params.amount / 100.0;
    var p = uv * 2.0 - vec2<f32>(1.0);
    let wobble = 1.0 + 0.03 * sin(frame.clip_time * 4.0 + f32(16));
    p = p / wobble;
    let boxp = abs(p) - vec2<f32>(0.72, 0.38);
    let outer = length(max(boxp, vec2<f32>(0.0))) + min(max(boxp.x, boxp.y), 0.0) - 0.064;
    let inner = length(max(boxp + vec2<f32>(0.022), vec2<f32>(0.0))) + min(max(boxp.x + 0.022, boxp.y + 0.022), 0.0) - 0.064;
    let d = max(outer, -inner);
    let shape = 1.0 - smoothstep(-0.015, 0.02, d);
    let col = vec3<f32>(0.973, 0.980, 0.988);
    let over = mix(src.rgb, col, shape * 0.9);
    return vec4<f32>(mix(src.rgb, over, a), max(src.a, shape * a));
}
