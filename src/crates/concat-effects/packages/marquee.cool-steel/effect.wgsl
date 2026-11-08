struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let luma = dot(c.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));
    let contrasted = mix(vec3<f32>(luma), c.rgb, 1.0 + 0.35 * a);
    let cooled = contrasted * vec3<f32>(0.92, 0.98, 1.08);
    return vec4<f32>(mix(c.rgb, clamp(cooled, vec3<f32>(0.0), vec3<f32>(1.0)), a), c.a);
}
