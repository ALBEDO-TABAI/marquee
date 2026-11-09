struct Params { amount: f32 }
// ASCII: the picture redrawn as coloured characters on black.
fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let a = params.amount / 100.0;
    let aspect = frame.size.x / max(frame.size.y, 1.0);
    let p = vec2<f32>(uv.x * aspect, uv.y);
    let t = look_time();
    let cell = max(floor(frame.size.y / 34.0), 5.0);
    let at = floor(uv * frame.size / cell);
    let centre = (at + vec2<f32>(0.5)) * cell / frame.size;
    let s = sample(centre);
    let l = clamp(luma(s.rgb), 0.0, 1.0);
    let f = fract(uv * frame.size / cell) - vec2<f32>(0.5);
    // . : + x # @ by brightness, drawn from strokes.
    let level = floor(l * 6.0);
    let dot1 = 1.0 - smoothstep(0.08, 0.14, length(f - vec2<f32>(0.0, 0.22)));
    let dot2 = 1.0 - smoothstep(0.08, 0.14, length(f + vec2<f32>(0.0, 0.22)));
    let hbar = 1.0 - smoothstep(0.05, 0.1, abs(f.y));
    let vbar = 1.0 - smoothstep(0.05, 0.1, abs(f.x));
    let inside = step(max(abs(f.x), abs(f.y)), 0.36);
    let diag = (1.0 - smoothstep(0.05, 0.1, abs(f.x - f.y))) + (1.0 - smoothstep(0.05, 0.1, abs(f.x + f.y)));
    let grid = (1.0 - smoothstep(0.04, 0.09, abs(abs(f.x) - 0.16))) + (1.0 - smoothstep(0.04, 0.09, abs(abs(f.y) - 0.16)));
    let ring = 1.0 - smoothstep(0.05, 0.1, abs(length(f) - 0.28));
    var glyph = 0.0;
    if (level >= 5.0) { glyph = max(ring, 1.0 - smoothstep(0.08, 0.13, length(f))); }
    else if (level >= 4.0) { glyph = grid; }
    else if (level >= 3.0) { glyph = diag; }
    else if (level >= 2.0) { glyph = max(hbar, vbar); }
    else if (level >= 1.0) { glyph = max(dot1, dot2); }
    else { glyph = dot1 * 0.0; }
    glyph = clamp(glyph * inside, 0.0, 1.0);
    let ink = saturation(s.rgb, 1.3) * 1.25 + vec3<f32>(0.08);
    let look = ink * glyph + vec3<f32>(0.02) * (1.0 - glyph);
    return vec4<f32>(mix(c.rgb, look, a), c.a);
}
