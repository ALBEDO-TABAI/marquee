struct Params { amount: f32 }
// 地点图钉: a red map pin dropping in with a bounce, a ring pulsing under it.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let fall = min(t / 0.6, 1.0);
    let bounce = abs(cos(fall * 3.1416 * 1.5)) * (1.0 - fall);
    let bob = sin(t * 3.0) * 0.008 * fall;
    let tip = vec2<f32>(0.5 * aspect, 0.58 - bounce * 0.5 + bob);
    let head = tip - vec2<f32>(0.0, 0.16);
    let q = p - head;
    let circle = length(q) - 0.07;
    let k = clamp((p.y - head.y) / 0.16, 0.0, 1.0);
    let cone = abs(q.x) - 0.07 * (1.0 - k) * step(head.y, p.y) * step(p.y, tip.y);
    let pin = min(circle, select(1.0, cone, p.y > head.y && p.y < tip.y));
    let body = 1.0 - smoothstep(-0.002, 0.002, pin);
    let hole = 1.0 - smoothstep(0.024, 0.028, length(q));
    let shade = 0.75 + 0.25 * smoothstep(0.07, -0.05, q.x + q.y);
    let ring_r = fract(t * 0.8) * 0.18;
    let sq = (p - vec2<f32>(0.5 * aspect, 0.58)) * vec2<f32>(1.0, 3.0);
    let ring = exp(-abs(length(sq) - ring_r) * 120.0) * (1.0 - fract(t * 0.8));
    let shadow = exp(-dot(sq, sq) * 400.0) * 0.45 * fall;
    var look = c.rgb * (1.0 - shadow) + vec3<f32>(1.0, 0.3, 0.3) * ring;
    look = mix(look, vec3<f32>(0.92, 0.14, 0.16) * shade, body);
    look = mix(look, vec3<f32>(1.0), hole * body);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
