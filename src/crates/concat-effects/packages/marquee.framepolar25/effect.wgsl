struct Params { amount: f32 }
// 拍立得框: a white instant-print border.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    // An instant print's white border, deeper at the foot.
    let side = 0.06;
    let x = min(uv.x, 1.0 - uv.x) * aspect;
    let inside = smoothstep(side - 0.003, side + 0.003, x)
        * smoothstep(side - 0.003, side + 0.003, uv.y)
        * smoothstep(0.2 - 0.003, 0.2 + 0.003, 1.0 - uv.y);
    let look = mix(vec3<f32>(0.97, 0.97, 0.95), c.rgb, inside);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
