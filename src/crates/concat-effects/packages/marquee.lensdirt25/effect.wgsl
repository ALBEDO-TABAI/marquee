struct Params { amount: f32 }
// 镜头污渍: smudges and specks on the lens, lit up where the light hits them.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let smudge = smoothstep(0.45, 0.8, fbm(p * 3.0, 80.0)) * 0.8;
    let q = p * 18.0;
    let id = floor(q);
    let f = fract(q) - vec2<f32>(0.5) - (vec2<f32>(hash(id, 81.0), hash(id, 82.0)) - vec2<f32>(0.5)) * 0.5;
    let rr = 0.06 + 0.14 * hash(id, 83.0);
    let specks = step(0.82, hash(id, 84.0)) * smoothstep(rr, rr * 0.4, length(f)) * 0.8;
    let dirt = clamp(smudge + specks, 0.0, 1.0);
    let light = soften(uv, frame.size.y / 8.0);
    let lit = max(light - vec3<f32>(0.35), vec3<f32>(0.0)) * 2.2 + vec3<f32>(0.12);
    let look = screen(c.rgb, lit * dirt * vec3<f32>(1.0, 0.95, 0.85));
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
