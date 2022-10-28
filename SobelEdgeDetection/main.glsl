#iChannel0 "file://0.png"

#iUniform float size = 3.0 in { 0.0, 5.0 }
#iUniform float angle = 0.0 in { 0.0, 360.0 }

float edgeSobel(sampler2D tex, float stepX, float stepY, vec2 center) {
    // Samples around the pixel.
    vec4 tleft  = texture(tex, center + vec2(-stepX, stepY));
    vec4 left   = texture(tex, center + vec2(-stepX, 0.0));
    vec4 bleft  = texture(tex, center + vec2(-stepX, -stepY));
    vec4 top    = texture(tex, center + vec2(0.0, stepY));
    vec4 bottom = texture(tex, center + vec2(0.0, -stepY));
    vec4 tright = texture(tex, center + vec2(stepX, stepY));
    vec4 right  = texture(tex, center + vec2(stepX, 0.0));
    vec4 bright = texture(tex, center + vec2(stepX, -stepY));

    // Sobel masks (see http://en.wikipedia.org/wiki/Sobel_operator)
    //        1 0 -1     -1 -2 -1
    //    X = 2 0 -2  Y = 0  0  0
    //        1 0 -1      1  2  1

    // You could also use Scharr operator:
    //        3 0 -3        3 10   3
    //    X = 10 0 -10  Y = 0  0   0
    //        3 0 -3        -3 -10 -3

    vec4 x =  tleft + 2.0 * left + bleft  - tright - 2.0 * right  - bright;
    vec4 y = -tleft - 2.0 * top  - tright + bleft  + 2.0 * bottom + bright;

    return sqrt(dot(x, x) + dot(y, y));
}

float deg2rad(float deg) {
    return deg / 180.0 * 3.1415926;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    float stepX = 0.001 * size * cos(deg2rad(angle));
    float stepY = 0.001 * size * sin(deg2rad(angle));

    float alpha = edgeSobel(iChannel0, stepX, stepY, uv);

    fragColor = vec4(alpha);
}
