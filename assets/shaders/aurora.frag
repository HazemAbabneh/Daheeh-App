#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_touch;

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / u_resolution;
    
    vec2 p = uv * 3.0 - vec2(1.5);
    
    // Add touch interaction (bend space based on distance to touch)
    if (u_touch.x > 0.0 && u_touch.y > 0.0) {
        vec2 touchDir = fragCoord - u_touch;
        float dist = length(touchDir) / length(u_resolution);
        p += normalize(touchDir) * exp(-dist * 8.0) * 0.3;
    }

    vec2 i = p;
    float c = 1.0;
    float inten = .05;

    for (int n = 0; n < 4; n++) {
        float t = u_time * (1.0 - (3.5 / float(n+1)));
        i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
        c += 1.0/length(vec2(p.x / (sin(i.x+t)/inten),p.y / (cos(i.y+t)/inten)));
    }
    
    c /= float(4);
    c = 1.17 - pow(c, 1.4);
    
    // Deep blue base
    vec3 color = vec3(pow(abs(c), 8.0));
    color = clamp(color + vec3(0.05, 0.10, 0.16), 0.0, 1.0); 
    
    // Gold highlights (#E0A96D approx)
    color += vec3(c*0.88, c*0.66, c*0.42) * 1.5;

    fragColor = vec4(color, 1.0);
}
