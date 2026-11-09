// 旋转变焦: a spinning zoom through the cut.
fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let p = clamp(progress, 0.0, 1.0);
    // Spun half a turn out of the first picture and back into the second.
    let after = p >= 0.5;
    let ang = select(p, p - 1.0, after) * 3.14159265;
    // Zoomed in as far as the turn needs, so the frame stays covered.
    let zoom = 1.0 + sin(3.14159265 * p);
    let q0 = (uv - vec2<f32>(0.5)) / zoom;
    let q = vec2<f32>(q0.x * cos(ang) - q0.y * sin(ang), q0.x * sin(ang) + q0.y * cos(ang)) + vec2<f32>(0.5);
    let qc = clamp(q, vec2<f32>(0.0), vec2<f32>(1.0));
    return select(from_at(qc), to_at(qc), after);
}
