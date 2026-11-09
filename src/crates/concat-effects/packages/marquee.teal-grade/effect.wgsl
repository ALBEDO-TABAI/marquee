struct Params { amount: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let graded = vec3<f32>(
        c.r * (1.0 - 0.14 * a),
        c.g * (1.0 + 0.05 * a),
        c.b * (1.0 + 0.20 * a),
    );
    return vec4<f32>(mix(c.rgb, max(graded, vec3<f32>(0.0)), a), c.a);
}
