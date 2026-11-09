struct Params { amount: f32 }
// 网点: a printed halftone - ink dots sized by the shade, on paper.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let cell = max(frame.size.y / 55.0, 3.0);
    let k = 0.7071;
    let r = vec2<f32>(uv.x * k + uv.y * k, -uv.x * k + uv.y * k) * frame.size / cell;
    let id = floor(r) + vec2<f32>(0.5);
    let back = vec2<f32>(id.x * k - id.y * k, id.x * k + id.y * k) * cell / frame.size;
    let s = sample(back);
    let dark = 1.0 - clamp(luma(s.rgb), 0.0, 1.0);
    let f = fract(r) - vec2<f32>(0.5);
    let radius = sqrt(dark) * 0.62;
    let dot = 1.0 - smoothstep(radius - 0.06, radius + 0.06, length(f));
    let ink = saturation(s.rgb, 1.3) * 0.75;
    let paper = vec3<f32>(0.97, 0.95, 0.88);
    let look = mix(paper, ink, dot);
    let over = max(c.rgb - vec3<f32>(1.0), vec3<f32>(0.0));
    return vec4<f32>(mix(c.rgb, look + over, a), c.a);
}
