struct Params { amount: f32 }
// 胶片灼烧: hot orange burns eating in from the edges of the film.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let n = fbm(p * 2.5 + vec2<f32>(t * 0.35, -t * 0.2), 40.0);
    let edge = max(abs(uv.x - 0.5) * 2.0, abs(uv.y - 0.5) * 2.0);
    let swell = 0.5 + 0.5 * sin(t * 1.2);
    let burn = smoothstep(0.75, 1.05, n * 0.7 + edge * (0.45 + 0.2 * swell));
    let core = smoothstep(0.95, 1.15, n * 0.7 + edge * (0.45 + 0.2 * swell));
    let fire = mix(vec3<f32>(1.0, 0.35, 0.05), vec3<f32>(1.0, 0.95, 0.75), core);
    let look = screen(c.rgb * (1.0 - burn * 0.2), fire * burn * 1.3);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
