#version 330

uniform int iTime;
uniform vec2 iResolution;

vec3 palette(float t) {
    vec3 a = vec3(.5); 
    vec3 b = vec3(.5);
    vec3 c = vec3(1., 1., 1.);
    vec3 d = vec3(.263, .416, .557);

    return a + b*cos(6.28318 * (c*t + d));
}

void main() {
    vec2 uv = (2.0 * gl_FragCoord.xy - iResolution) / iResolution.y;
    vec2 uv0 = uv;
    vec3 finalColor = vec3(0.0);

    for (float i = 0.0; i < 4; i++) {
        uv = fract(1.5 * uv) - 0.5;

        float d = length(uv) * exp(-length(uv0));

        vec3 col = palette(length(uv0) + i * 0.4 + iTime / 100.);

        d = sin(d * 8.0 + iTime / 50.) / 8.0;
        d = abs(d);

        // if (d <= 0.02) d = 0.02;
        d = pow(0.01 / d, 1.2);

        finalColor += col * d;
    }

    gl_FragColor = vec4(finalColor, 1.0);
}
