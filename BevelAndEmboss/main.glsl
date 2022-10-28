// Source:
// http://coding-experiments.blogspot.com/2010/07/convolution.html

#iChannel0 "file://1.png"
#iChannel1 "file://fill.png"

#define EMBOSS_WIDTH    0.0015
#define EMBOSS_HEIGHT    0.0015

#iUniform float size = 3.0 in { 0.0, 5.0 }
#iUniform float angle = 0.0 in { 0.0, 360.0 }
#iUniform float altitude = 20.0 in { 0.0, 90.0 }
#iUniform float test = 0.5 in { 0.0, 10.0 }

#iUniform color3 fill_color = color3(1.0, 1.0, 1.0)

#iUniform color3 highlight_color = color3(1.0, 1.0, 1.0)
#iUniform float highlight_opacity = 1.0 in { 0.0, 1.0 }

#iUniform color3 shadow_color = color3(0.0, 0.0, 0.0)
#iUniform float shadow_opacity = 1.0 in { 0.0, 1.0 }

float deg2rad(float deg) {
    return deg / 180.0 * 3.1415926;
}

// Samples a pixel centerd at "uv" and with offset of (dx, dy).
vec4 sample_pixel(in vec2 uv, in float dx, in float dy) {
    return texture(iChannel0, uv + vec2(dx, dy));
}

// Convolves a SINGLE channel of the input color matrix.
float convolve(in float[9] kernel, in vec4[9] color_matrix) {
   float res = 0.0;
   for (int i = 0; i < 9; i++) {
      res += kernel[i] * color_matrix[i].a;
   }
   return clamp(res + 0.5, 0.0, 1.0);
}

// Builds a 3x3 color matrix centerd at "uv".
void build_color_matrix(in vec2 uv, out vec4[9] color_matrix) {
    // To comply with AE.
    float adjusted_size = size;
    float adjusted_angle = deg2rad(angle);

    float dx = EMBOSS_WIDTH * adjusted_size * cos(adjusted_angle);
    float dy = EMBOSS_HEIGHT * adjusted_size * sin(adjusted_angle);

    color_matrix[0].rgb = sample_pixel(uv, -dx, -dy).rgb;
    color_matrix[1].rgb = sample_pixel(uv, -dx, 0.0).rgb;
    color_matrix[2].rgb = sample_pixel(uv, -dx, dy).rgb;

    color_matrix[3].rgb = sample_pixel(uv, 0.0, -dy).rgb;
    color_matrix[4].rgb = sample_pixel(uv, 0.0, 0.0).rgb;
    color_matrix[5].rgb = sample_pixel(uv, 0.0, dy).rgb;
    
    color_matrix[6].rgb = sample_pixel(uv, dx, -dy).rgb;
    color_matrix[7].rgb = sample_pixel(uv, dx, 0.0).rgb;
    color_matrix[8].rgb = sample_pixel(uv, dx, dy).rgb;
}

// Builds a mean color matrix (off of .rgb of input).
// NOTE: Stores the output in alpha channel.
void build_mean_matrix(inout vec4[9] color_matrix) {
    float adjusted_altitude = deg2rad(altitude) * 30.0;

    for (int i = 0; i < 9; i++) {
        color_matrix[i].a = (color_matrix[i].r + color_matrix[i].g + color_matrix[i].b) / adjusted_altitude;
    }
}

vec4 process(in vec4 color, in vec2 uv) {
    /*
    Convolution kernel.
    2.    0.     0.
    0.    -1.    0.
    0.    0.    -1.
    */
    float kernel[9];
    kernel[0] = 2.0;
    kernel[1] = 0.0;
    kernel[2] = 0.0;
    kernel[3] = 0.0;
    kernel[4] = -1.;
    kernel[5] = 0.0;
    kernel[6] = 0.0;
    kernel[7] = 0.0;
    kernel[8] = -1.;
    
    vec4 color_matrix[9];
    
    build_color_matrix(uv, color_matrix);
    build_mean_matrix(color_matrix);
    
    // Light part is close to 1.0, dark part is close to 0.0.
    float convolved = convolve(kernel, color_matrix);

    // For visual debugging.
    vec3 emboss_color = vec3(convolved);

    float adjusted_altitude = cos(deg2rad(altitude));

    // Factors used to detect highlight and shadow areas.
    float highlight_factor = clamp(convolved - 0.5, 0.0, 1.0) * 2.0;

    float shadow_factor = 1.0 - convolved;
    shadow_factor = clamp(shadow_factor - 0.5, 0.0, 1.0) * 2.0;

    // Base color.
    vec3 out_color = color.rgb;

    // Mix highlight color.
    out_color = mix(out_color, highlight_color, highlight_factor * highlight_opacity);
    
    // Mix shadow color.
    out_color = mix(out_color, shadow_color, shadow_factor * shadow_opacity);

    // out_color = highlight_color * highlight_factor + shadow_color * shadow_factor;

    // Test.
    {
        // Show highlight and shadow areas.
        // out_color = emboss_color;
        // Show highlight area as white.
        //out_color = vec3(highlight_factor);
        // Show shadow area as white.
        // out_color = vec3(shadow_factor);
    }

    return vec4(out_color, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    vec4 fill = vec4(fill_color, 1.0);

    fragColor = process(fill, uv);

    // Consider opacity.
    fragColor *= texture(iChannel0, uv).a;
}
