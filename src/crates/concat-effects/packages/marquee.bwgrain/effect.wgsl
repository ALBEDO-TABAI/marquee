struct Params { amount: f32 }
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let luma = dot(c.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));
    let tint = vec3<f32>(0.8445098039215686, 0.8445098039215686, 0.8445098039215686);
    let graded = mix(vec3<f32>(luma), c.rgb, 1.05) * tint + vec3<f32>(0.02);
    let contrasted = (graded - vec3<f32>(0.5)) * 1.08 + vec3<f32>(0.5);
    return vec4<f32>(mix(c.rgb, clamp(contrasted, vec3<f32>(0.0), vec3<f32>(1.0)), a), c.a);
}
