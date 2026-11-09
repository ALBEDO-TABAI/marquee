struct Params { amount: f32 }
// 速度线: manga speed lines rushing in from the edges, flickering.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let d = (uv - vec2<f32>(0.5)) * vec2<f32>(aspect, 1.0);
    let ang = atan2(d.y, d.x);
    let tick = floor(t * 12.0);
    let n = hash(vec2<f32>(floor(ang * 38.0), tick), 170.0);
    let width = step(0.55, n) * smoothstep(0.0, 0.25, fract(ang * 38.0)) * smoothstep(1.0, 0.75, fract(ang * 38.0));
    let reach = 0.28 + 0.2 * hash(vec2<f32>(floor(ang * 38.0), tick), 171.0);
    let lines = width * smoothstep(reach, reach + 0.25, length(d));
    let look = mix(c.rgb, vec3<f32>(1.0), lines * 0.9);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
