struct Params { amount: f32 }
// 画中画: the picture framed small in the middle over a blurred, dimmed copy.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let float_y = sin(t * 1.5) * 0.006;
    let scale = mix(1.0, 0.68, a);
    let q = (uv - vec2<f32>(0.5, 0.5 + float_y)) / scale + vec2<f32>(0.5);
    let inside = step(0.0, q.x) * step(q.x, 1.0) * step(0.0, q.y) * step(q.y, 1.0);
    let border_px = 4.0 / (frame.size.y * scale);
    let border = step(-border_px, q.x) * step(q.x, 1.0 + border_px) * step(-border_px * aspect, q.y) * step(q.y, 1.0 + border_px * aspect);
    let back = soften(uv, frame.size.y / 18.0) * 0.55;
    let sh = (uv - vec2<f32>(0.5, 0.5 + float_y)) / scale + vec2<f32>(0.5) - vec2<f32>(0.015, 0.02);
    let shadow = step(0.0, sh.x) * step(sh.x, 1.0) * step(0.0, sh.y) * step(sh.y, 1.0);
    var look = back * (1.0 - shadow * 0.4);
    look = mix(look, vec3<f32>(1.0), border);
    look = mix(look, sample(q).rgb, inside);
    return vec4<f32>(look, c.a);
}
