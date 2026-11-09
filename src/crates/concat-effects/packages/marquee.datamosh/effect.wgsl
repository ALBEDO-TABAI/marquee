struct Params { amount: f32 }
// 数据马赛克: blocks of the picture smeared and stuck, the compression broken.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let tick = floor(t * 7.0);
    let bs = max(floor(frame.size.y / 14.0), 4.0);
    let blk = floor(uv * frame.size / bs);
    let pick = hash(blk + vec2<f32>(tick * 3.0), 220.0);
    var q = uv;
    if (pick < 0.32 * a) {
        // Stuck: the block reads a slab from beside it, smeared down.
        let mv = (vec2<f32>(hash(blk, 221.0 + tick), hash(blk, 222.0 + tick)) - vec2<f32>(0.5)) * 0.12;
        q = (blk * bs + vec2<f32>(bs * 0.5, fract(uv.y * frame.size.y / bs) * bs * 0.2)) / frame.size + mv;
    }
    let s = sample(q);
    let crush = floor(s.rgb * 6.0 + vec3<f32>(0.5)) / 6.0;
    let mosh = select(s.rgb, crush * vec3<f32>(1.05, 0.95, 1.1), pick < 0.32 * a);
    return vec4<f32>(mosh, c.a);
}
