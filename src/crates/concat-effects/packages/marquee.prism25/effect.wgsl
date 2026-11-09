struct Params { amount: f32 }
// 棱镜: the picture split through a prism - shifted colour ghosts and a rainbow band.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let dir = normalize(vec2<f32>(1.0, 0.35));
    let o = dir * 0.02 * (0.5 + 0.5 * sin(t * 0.9));
    let r = sample(uv + o).r;
    let g = sample(uv).g;
    let b = sample(uv - o).b;
    let band_pos = dot(uv - vec2<f32>(0.5), vec2<f32>(dir.y, -dir.x)) + 0.25 * sin(t * 0.5);
    let rainbow = vec3<f32>(0.5) + 0.5 * cos(6.2832 * (vec3<f32>(0.0, 0.33, 0.67) + band_pos * 3.0));
    let band = exp(-abs(band_pos) * 9.0) * 0.45;
    let look = screen(vec3<f32>(r, g, b), rainbow * band);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
