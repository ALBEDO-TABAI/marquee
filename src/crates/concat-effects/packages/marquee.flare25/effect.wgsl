struct Params { amount: f32 }
// 光斑: a lens flare - a bright source, its rays and a chain of ghosts.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let src = vec2<f32>((0.22 + 0.06 * sin(t * 0.5)) * aspect, 0.2 + 0.03 * cos(t * 0.4));
    let mid = vec2<f32>(0.5 * aspect, 0.5);
    let d = p - src;
    let ang = atan2(d.y, d.x);
    let glow = exp(-length(d) * 7.0) * 1.2 + exp(-length(d) * 30.0);
    let rays = pow(abs(sin(ang * 6.0 + t * 0.3)), 30.0) * exp(-length(d) * 4.0) * 0.6;
    var ghosts = vec3<f32>(0.0);
    for (var i = 1; i <= 5; i++) {
        let k = f32(i);
        let at = src + (mid - src) * (0.5 + k * 0.35);
        let r = 0.02 + 0.025 * fract(k * 0.618);
        let g = smoothstep(r, r * 0.6, length(p - at)) * 0.35;
        let tint = vec3<f32>(0.5) + 0.5 * cos(6.2832 * (vec3<f32>(0.0, 0.33, 0.67) + k * 0.21));
        ghosts += tint * g;
    }
    let look = screen(c.rgb, max(vec3<f32>(1.0, 0.9, 0.75) * (glow + rays) + ghosts, vec3<f32>(0.0)));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
