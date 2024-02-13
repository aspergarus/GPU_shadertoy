#version 330

uniform int iTime;
uniform vec2 iResolution;

void main() {
    vec2 uv = (2 * gl_FragCoord.xy - iResolution) / iResolution;
    uv.x *= iResolution.x / iResolution.y;

    vec3 baseCol = vec3(0.3, 0.6, 0.9);

    float d = length(uv);

    d = sin(d * 8.0 + iTime / 20.) / 1.0; // -1.0 .. 1.0

    d = abs(d); // 0.0 .. 1.0

    if (d <= 0.02) d = 0.02; // 0.02 .. 1.0
    d = 0.02 / d; // 1 .. 0.02

    vec3 col = baseCol * d;

    gl_FragColor = vec4(col, 1.0);
}
