// 画中画互换: one picture shrinks away as the other grows in.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // Picture in picture swapped: the incoming picture grows from the
    // bottom right corner as the outgoing one shrinks into the top left.
    let s = smoothstep(0.0, 1.0, p);
    let small = mix(1.0, 0.0, s);
    let q0 = uv / max(small, 1e-4);
    let a = from_at(q0);
    let in_a = all(q0 <= vec2<f32>(1.0));
    let big = s;
    let q1 = (uv - vec2<f32>(1.0 - big)) / max(big, 1e-4);
    let in_b = all(q1 >= vec2<f32>(0.0));
    let b = to_at(q1);
    let under = to_at(uv);
    let dim = vec4<f32>(under.rgb * 0.35, under.a);
    return select(select(dim, a, in_a), b, in_b);
}
