struct Params { amount: f32 }
// 抖动色阶: an ordered-dither print in a handful of colours.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let cell = max(floor(frame.size.y / 110.0), 2.0);
    let pix = floor(uv * frame.size / cell);
    let x = u32(pix.x) % 4u;
    let y = u32(pix.y) % 4u;
    // A 4x4 Bayer threshold from its two 2x2 halves.
    let m2a = ((x & 1u) ^ (y & 1u)) * 2u + (y & 1u);
    let m2b = (((x >> 1u) & 1u) ^ ((y >> 1u) & 1u)) * 2u + ((y >> 1u) & 1u);
    let thr = (f32(m2a * 4u + m2b) + 0.5) / 16.0;
    let s = sample((pix + vec2<f32>(0.5)) * cell / frame.size);
    let levels = 2.0;
    let v = clamp(s.rgb, vec3<f32>(0.0), vec3<f32>(1.0)) * levels;
    let look = (floor(v) + step(vec3<f32>(thr), fract(v))) / levels;
    let over = max(c.rgb - vec3<f32>(1.0), vec3<f32>(0.0));
    return vec4<f32>(mix(c.rgb, look + over, a), c.a);
}
