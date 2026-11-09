// 漫画框切: slanted comic panels turn over one by one.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // Comic panels: three slanted panels turn over one after another, with
    // a black gutter between the old and the new.
    let band = clamp(floor((uv.x + (1.0 - uv.y) * 0.35) / 1.35 * 3.0), 0.0, 2.0);
    let start = band * 0.25;
    let local = clamp((p - start) / 0.5, 0.0, 1.0);
    let line = fract((uv.x + (1.0 - uv.y) * 0.35) / 1.35 * 3.0);
    let gutter = (1.0 - smoothstep(0.0, 0.03, line)) + smoothstep(0.97, 1.0, line);
    let c = select(from_at(uv), to_at(uv), local >= 0.5);
    let busy = sin(3.14159265 * p);
    return vec4<f32>(mix(c.rgb, vec3<f32>(0.0), clamp(gutter * busy * 1.5, 0.0, 1.0)), c.a);
}
