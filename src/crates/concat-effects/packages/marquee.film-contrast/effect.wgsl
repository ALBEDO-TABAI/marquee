struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let lifted = c.rgb * (1.0 - 0.08 * a) + vec3<f32>(0.04 * a);
    let s = 1.0 + 0.55 * a;
    let mid = (lifted - vec3<f32>(0.5)) * s + vec3<f32>(0.5);
    // Floored at black only: a highlight past white is carried, not clipped.
    return vec4<f32>(max(mid, vec3<f32>(0.0)), c.a);
}
