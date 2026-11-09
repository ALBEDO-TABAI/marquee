fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = clamp(progress, 0.0, 1.0);
    // The old shot irises down to black, the new one irises up out of it.
    let r = 0.75 * abs(t * 2.0 - 1.0);
    let inside = 1.0 - smoothstep(r - 0.01, r + 0.01, length(uv - vec2<f32>(0.5)));
    var shot = from_at(uv);
    if (t >= 0.5) {
        shot = to_at(uv);
    }
    return vec4<f32>(shot.rgb * inside, 1.0);
}
