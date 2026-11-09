struct Params { amount: f32 }
// 胶片框: a film strip's sprocketed bands.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    // A strip of film: dark bands top and bottom, sprocket holes in them.
    let band = 0.11;
    let edge = min(uv.y, 1.0 - uv.y);
    let in_band = 1.0 - smoothstep(band - 0.004, band + 0.004, edge);
    let pitch = 0.075 / aspect;
    let hx = abs(fract(uv.x / pitch) - 0.5) * pitch * aspect;
    let hy = abs(edge - band * 0.5);
    let hole = (1.0 - smoothstep(0.016, 0.02, hx)) * (1.0 - smoothstep(0.022, 0.026, hy));
    let strip = mix(vec3<f32>(0.05, 0.04, 0.03), vec3<f32>(0.92, 0.9, 0.84), hole);
    let look = mix(c.rgb * vec3<f32>(1.03, 1.0, 0.94), strip, in_band);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
