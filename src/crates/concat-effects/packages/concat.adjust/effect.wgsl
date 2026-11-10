struct Params {
    exposure: f32,
    brightness: f32,
    contrast: f32,
    saturation: f32,
    temperature: f32,
    tint: f32,
    shadows: f32,
    highlights: f32,
    whites: f32,
    blacks: f32,
    sharpen: f32,
    vignette: f32,
    fade: f32,
    light: f32,
    grain: f32,
    hue_red: f32,
    sat_red: f32,
    lum_red: f32,
    hue_orange: f32,
    sat_orange: f32,
    lum_orange: f32,
    hue_yellow: f32,
    sat_yellow: f32,
    lum_yellow: f32,
    hue_green: f32,
    sat_green: f32,
    lum_green: f32,
    hue_cyan: f32,
    sat_cyan: f32,
    lum_cyan: f32,
    hue_blue: f32,
    sat_blue: f32,
    lum_blue: f32,
    hue_purple: f32,
    sat_purple: f32,
    lum_purple: f32,
    hue_magenta: f32,
    sat_magenta: f32,
    lum_magenta: f32,
    lift: vec3<f32>,
    gamma: vec3<f32>,
    gain: vec3<f32>,
    luma: array<vec4<f32>, 8>,
    red: array<vec4<f32>, 8>,
    green: array<vec4<f32>, 8>,
    blue: array<vec4<f32>, 8>,
}

// The manual colour panel, in the order a colourist works: exposure and
// balance, then tone, then the edge and the frame. What a lens or a lamp
// does is done in light - exposure in stops, the white balance, the
// vignette - and contrast in stops about middle grey; what an eye judges
// on the picture - brightness, saturation, the four tonal bands, the fade,
// the wheels and curves, sharpness - in the display encoding its sliders
// were drawn in, which here is never clipped: a highlight past white is
// carried on past it. Every knob at its default is the picture as it came.

/// `by` added to a display-encoded colour, as far down as black and no
/// further: a channel that is lit is not taken below nothing.
fn lifted(encoded: vec3<f32>, by: f32) -> vec3<f32> {
    let moved = encoded + vec3<f32>(by);
    return select(moved, max(moved, vec3<f32>(0.0)), encoded >= vec3<f32>(0.0));
}

/// Hue in degrees, 0..360, of a display-encoded colour; 0 for a grey.
fn hue_degrees(rgb: vec3<f32>) -> f32 {
    let mx = max(max(rgb.r, rgb.g), rgb.b);
    let mn = min(min(rgb.r, rgb.g), rgb.b);
    let d = mx - mn;
    if (d < 0.0001) {
        return 0.0;
    }
    var h: f32;
    if (mx == rgb.r) {
        h = (rgb.g - rgb.b) / d;
    } else if (mx == rgb.g) {
        h = 2.0 + (rgb.b - rgb.r) / d;
    } else {
        h = 4.0 + (rgb.r - rgb.g) / d;
    }
    return fract(h / 6.0) * 360.0;
}

/// Every hue turned by `degrees` about the colour's own luma, in the YIQ
/// plane: a turn of nothing is the colour it was.
fn turn_hue(rgb: vec3<f32>, degrees: f32) -> vec3<f32> {
    let a = radians(degrees);
    let y = dot(rgb, vec3<f32>(0.299, 0.587, 0.114));
    let i = dot(rgb, vec3<f32>(0.596, -0.274, -0.322));
    let q = dot(rgb, vec3<f32>(0.211, -0.523, 0.312));
    let i2 = i * cos(a) - q * sin(a);
    let q2 = i * sin(a) + q * cos(a);
    return vec3<f32>(
        y + 0.956 * i2 + 0.621 * q2,
        y - 0.272 * i2 - 0.647 * q2,
        y - 1.106 * i2 + 1.703 * q2,
    );
}

/// The HSL panel: what the bands either side of the colour's hue ask for,
/// read between the two by how near it is to each, and given only as far
/// as the colour is a colour - a grey takes none of it.
fn hsl_bands(d: vec3<f32>) -> vec3<f32> {
    // The eight bands' centres, in degrees round the hue circle: red,
    // orange, yellow, green, cyan, blue, purple, magenta, and red again.
    var centres = array<f32, 9>(0.0, 30.0, 60.0, 120.0, 180.0, 240.0, 280.0, 320.0, 360.0);
    var hues = array<f32, 9>(params.hue_red, params.hue_orange, params.hue_yellow,
        params.hue_green, params.hue_cyan, params.hue_blue, params.hue_purple,
        params.hue_magenta, params.hue_red);
    var sats = array<f32, 9>(params.sat_red, params.sat_orange, params.sat_yellow,
        params.sat_green, params.sat_cyan, params.sat_blue, params.sat_purple,
        params.sat_magenta, params.sat_red);
    var lums = array<f32, 9>(params.lum_red, params.lum_orange, params.lum_yellow,
        params.lum_green, params.lum_cyan, params.lum_blue, params.lum_purple,
        params.lum_magenta, params.lum_red);
    let c = clamp(d, vec3<f32>(0.0), vec3<f32>(1.0));
    let chroma = max(max(c.r, c.g), c.b) - min(min(c.r, c.g), c.b);
    let weight = smoothstep(0.02, 0.2, chroma);
    if (weight <= 0.0) {
        return d;
    }
    // A red a hair under zero wraps to a fract of 1.0, a full 360: held
    // inside the last band, which is red again.
    let h = clamp(hue_degrees(c), 0.0, 359.99);
    var dh = 0.0;
    var ds = 0.0;
    var dl = 0.0;
    for (var n: i32 = 0; n < 8; n++) {
        let lo = centres[n];
        let hi = centres[n + 1];
        if (h >= lo && h < hi) {
            let t = (h - lo) / (hi - lo);
            dh = mix(hues[n], hues[n + 1], t);
            ds = mix(sats[n], sats[n + 1], t);
            dl = mix(lums[n], lums[n + 1], t);
            break;
        }
    }
    // A positive turn walks a band toward the next one up the circle, red
    // toward orange, as the other editors' HSL panels do; the YIQ turn goes
    // the other way round, so it is asked for the negative.
    var out = turn_hue(d, -dh / 100.0 * 30.0 * weight);
    let l = luma(out);
    out = vec3<f32>(l) + (out - vec3<f32>(l)) * max(1.0 + ds / 100.0 * weight, 0.0);
    out = out * (1.0 + dl / 100.0 * 0.5 * weight);
    return out;
}

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let t = texel();
    let src = sample(uv);

    // Exposure in stops, then brightness as a lift of the display level.
    var c = exposure(src.rgb, params.exposure);
    c = from_display(lifted(to_display(c), params.brightness / 100.0 * 0.5));

    // White balance about daylight, and green to magenta.
    c = white_balance(c, params.temperature, params.tint);

    // Contrast in stops about middle grey.
    c = contrast(c, 1.0 + params.contrast / 100.0);

    // Saturation about luminance, by the display level: a push richer by
    // up to three times, a pull greyer to none at all.
    var d = to_display(c);
    let s = params.saturation / 100.0;
    d = saturation(d, select((1.0 + s) * (1.0 + s), 1.0 + 2.0 * s, s > 0.0));

    // The HSL bands, on the colour as the saturation left it.
    if (any(vec4<f32>(abs(params.hue_red) + abs(params.sat_red) + abs(params.lum_red),
        abs(params.hue_orange) + abs(params.sat_orange) + abs(params.lum_orange),
        abs(params.hue_yellow) + abs(params.sat_yellow) + abs(params.lum_yellow),
        abs(params.hue_green) + abs(params.sat_green) + abs(params.lum_green)) > vec4<f32>(0.0))
        || any(vec4<f32>(abs(params.hue_cyan) + abs(params.sat_cyan) + abs(params.lum_cyan),
        abs(params.hue_blue) + abs(params.sat_blue) + abs(params.lum_blue),
        abs(params.hue_purple) + abs(params.sat_purple) + abs(params.lum_purple),
        abs(params.hue_magenta) + abs(params.sat_magenta) + abs(params.lum_magenta)) > vec4<f32>(0.0))) {
        d = hsl_bands(d);
    }

    // Light (光感): the midtones bent up or down, black and white held, a
    // level past white carried on past it.
    if (params.light != 0.0) {
        let below = clamp(d, vec3<f32>(0.0), vec3<f32>(1.0));
        d = pow(below, vec3<f32>(exp2(-params.light / 100.0 * 0.7))) + (d - below);
    }

    // Shadows and highlights lift or crush their half of the range, blacks
    // and whites the extreme quarter of each, by the display level; fade
    // lifts the black and carries a level past white on past it.
    let l = luma(clamp(d, vec3<f32>(0.0), vec3<f32>(1.0)));
    let low = (1.0 - smoothstep(0.0, 0.5, l)) * params.shadows / 100.0 * 0.18;
    let high = smoothstep(0.5, 1.0, l) * params.highlights / 100.0 * 0.18;
    let black = (1.0 - smoothstep(0.0, 0.25, l)) * params.blacks / 100.0 * 0.1;
    let white = smoothstep(0.75, 1.0, l) * params.whites / 100.0 * 0.1;
    d = lifted(d, low + high + black + white);
    let matte = params.fade / 100.0 * 0.25;
    let below = min(d, vec3<f32>(1.0));
    d = below * (1.0 - matte) + vec3<f32>(matte) + (d - below);

    // The wheels, then the curves, on the display level too.
    d = grade_wheels(d, params.lift, params.gamma, params.gain);
    d = grade_curves(d, params.luma, params.red, params.green, params.blue);

    // Sharpen: the picture's difference from a small blur of it, scaled.
    if (params.sharpen > 0.0) {
        var blur = vec3<f32>(0.0);
        for (var y: i32 = -1; y <= 1; y++) {
            for (var x: i32 = -1; x <= 1; x++) {
                blur += to_display(sample(uv + vec2<f32>(f32(x), f32(y)) * t).rgb);
            }
        }
        blur /= 9.0;
        d = d + (to_display(src.rgb) - blur) * params.sharpen / 100.0 * 2.0;
    }
    c = from_display(d);

    // Vignette: the light falling off towards the corners, as a lens's does.
    if (params.vignette > 0.0) {
        let r = length((uv - vec2<f32>(0.5)) * vec2<f32>(2.0));
        let v = params.vignette / 100.0;
        let fall = smoothstep(1.4 - v * 0.9, 1.6 - v * 0.3, r);
        c = c * pow(1.0 - fall * (0.4 + 0.6 * v), 2.4);
    }

    // Grain: every pixel moved up or down by a little, most in the
    // midtones, new each frame. Laid on a grid of 1080 lines whatever the
    // layer's size, so the preview and the export draw the same grain.
    if (params.grain > 0.0) {
        let cell = floor(uv * vec2<f32>(frame.size.x / max(frame.size.y, 1.0), 1.0) * 1080.0);
        let n = hash(cell, fract(frame.time * 7.31)) - 0.5;
        var g = to_display(c);
        let l = clamp(luma(g), 0.0, 1.0);
        g = g + vec3<f32>(n * params.grain / 100.0 * 0.18 * (0.35 + 2.6 * l * (1.0 - l)));
        c = from_display(g);
    }

    return vec4<f32>(c, src.a);
}
