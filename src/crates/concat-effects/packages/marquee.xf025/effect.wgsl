fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let t = clamp(progress, 0.0, 1.0);
    // A camera flash rather than a dip: both shots blow out towards the
    // cut, the highlights first, and the incoming one settles back.
    let k = pow(1.0 - abs(t * 2.0 - 1.0), 1.5);
    let pic = mix(from_at(uv), to_at(uv), smoothstep(0.45, 0.55, t));
    let lum = dot(pic.rgb, vec3<f32>(0.299, 0.587, 0.114));
    let blown = pic.rgb * (1.0 + 2.5 * k) + vec3<f32>(k * k) * (0.6 + 0.4 * lum);
    return vec4<f32>(min(mix(pic.rgb, blown, k), vec3<f32>(1.0)), pic.a);
}
