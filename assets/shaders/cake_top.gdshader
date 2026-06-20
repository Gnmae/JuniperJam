shader_type canvas_item;
render_mode blend_mix;

uniform vec4 base_color : source_color = vec4(0.95, 0.88, 0.92, 1.0);
uniform float texture_scale : hint_range(1.0, 80.0, 0.5) = 22.0;
uniform float noise_strength : hint_range(0.0, 0.4) = 0.13;
uniform float grain_strength : hint_range(0.0, 1.0) = 0.35;
uniform float sheen_strength : hint_range(0.0, 1.5) = 0.20;
uniform vec2 sheen_direction = vec2(0.65, -0.75);
uniform float saturation_variation : hint_range(0.0, 0.3) = 0.08;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 78.233);
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < octaves; i++) {
        value += amplitude * value_noise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 uv = UV * texture_scale;
    
    float low_freq = fbm(uv * 0.65, 3);
    
    float fine_grain = (value_noise(uv * 2.8) * 0.6 + value_noise(uv * 5.7) * 0.4) * grain_strength;
    
    float combined = (low_freq * 0.5 + fine_grain * 0.5) * 2.0 - 1.0;
    
    vec3 color = base_color.rgb;
    
    color *= 1.0 + combined * noise_strength;
    
    float sat_shift = combined * saturation_variation;
    color = mix(color, color * vec3(1.0, 0.96, 1.08), sat_shift);
    
    vec2 light_dir = normalize(sheen_direction);
    vec2 centered_uv = UV - 0.5;
    float NdotL = dot(normalize(centered_uv), light_dir);
    
    float specular = pow(max(NdotL * 0.5 + 0.5, 0.0), 4.0) * sheen_strength * 0.7;
    specular *= (0.7 + fine_grain * 0.6);
    
    color += specular * vec3(1.0);
    
    COLOR = vec4(clamp(color, 0.0, 1.0), base_color.a);
}