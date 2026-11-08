struct Params { strength: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let d = length((uv - vec2<f32>(0.5)) * vec2<f32>(1.85, 1.0));
    let s = params.strength / 100.0;
    let mask = smoothstep(0.35, 1.15 - 0.25 * s, d) * s;
    return vec4<f32>(c.rgb * (1.0 - mask * 0.72), c.a);
}
