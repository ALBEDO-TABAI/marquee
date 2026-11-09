struct Params { amount: f32 }
// 爪印: paw prints padding across the picture, one step at a time.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let ph = loop_phase(2.4);
    var over = 0.0;
    for (var i = 0; i < 6; i++) {
        let k = f32(i);
        let shown = smoothstep(k / 6.0, k / 6.0 + 0.04, ph) * (1.0 - smoothstep(0.88, 1.0, ph));
        let side = select(-1.0, 1.0, (i & 1) == 1);
        let at = vec2<f32>((0.12 + k * 0.15) * aspect, 0.8 - k * 0.12) + vec2<f32>(0.04, 0.04) * side;
        let q = (p - at) / 0.085;
        let pad = length(q * vec2<f32>(1.0, 1.25) - vec2<f32>(0.0, 0.3)) - 0.5;
        var toes = 10.0;
        for (var j = 0; j < 4; j++) {
            let ang = -2.3 + f32(j) * 0.52;
            let tc = vec2<f32>(cos(ang), sin(ang)) * 0.85;
            toes = min(toes, length(q - tc) - 0.22);
        }
        let paw = 1.0 - smoothstep(-0.04, 0.04, min(pad, toes));
        over = max(over, paw * shown);
    }
    let look = mix(c.rgb, vec3<f32>(1.0, 0.55, 0.7), over * 0.9);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
