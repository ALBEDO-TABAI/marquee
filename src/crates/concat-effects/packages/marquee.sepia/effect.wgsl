struct Params { amount: f32 }
// 褐色: the classic sepia print.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let r = dot(c.rgb, vec3<f32>(0.393, 0.769, 0.189));
    let g = dot(c.rgb, vec3<f32>(0.349, 0.686, 0.168));
    let b = dot(c.rgb, vec3<f32>(0.272, 0.534, 0.131));
    let look = min(vec3<f32>(r, g, b), vec3<f32>(1.0));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
