struct Params { strength: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let s = params.strength / 100.0;
    let o = 0.0035 + 0.004 * s;
    let bloom = (
        sample(uv + vec2<f32>(o, 0.0)).rgb +
        sample(uv - vec2<f32>(o, 0.0)).rgb +
        sample(uv + vec2<f32>(0.0, o)).rgb +
        sample(uv - vec2<f32>(0.0, o)).rgb
    ) * 0.25;
    let rim = max(bloom - c.rgb, vec3<f32>(0.0));
    return vec4<f32>(clamp(c.rgb + rim * (0.55 + 0.9 * s), vec3<f32>(0.0), vec3<f32>(1.0)), c.a);
}
