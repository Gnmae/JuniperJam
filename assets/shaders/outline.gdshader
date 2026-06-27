shader_type canvas_item;
uniform bool enabled = false;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_size : hint_range(0.0, 20.0) = 4.0;

uniform bool pulse_enabled = true;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;
uniform float pulse_min_size : hint_range(0.0, 20.0) = 1.0;
uniform float pulse_max_size : hint_range(0.0, 20.0) = 6.0;
uniform float pulse_alpha_min : hint_range(0.0, 1.0) = 0.4;
uniform float pulse_alpha_max : hint_range(0.0, 1.0) = 1.0;
// Tint
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 current = texture(TEXTURE, UV);

    // Apply tint by multiplying RGB, preserve alpha
    vec4 tinted = vec4(current.rgb * tint_color.rgb, current.a);
    current = mix(current, tinted, tint_strength);

    if (!enabled) {
        COLOR = current;
    } else {
        float current_size = outline_size;
        float current_alpha = outline_color.a;
        
        if (pulse_enabled) {
            float pulse = (sin(TIME * pulse_speed) + 1.0) / 2.0;
            current_size = mix(pulse_min_size, pulse_max_size, pulse);
            current_alpha = mix(pulse_alpha_min, pulse_alpha_max, pulse);
        }
        
        vec2 size = current_size * TEXTURE_PIXEL_SIZE;
        
        float outline_alpha = 0.0;
        int steps = 8;
        for (int i = 0; i < steps; i++) {
            float angle = float(i) * (TAU / float(steps));
            vec2 offset = vec2(cos(angle), sin(angle)) * size;
            outline_alpha = max(outline_alpha, texture(TEXTURE, UV + offset).a);
        }
        
        outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(size.x, 0.0)).a);
        outline_alpha = max(outline_alpha, texture(TEXTURE, UV - vec2(size.x, 0.0)).a);
        outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(0.0, size.y)).a);
        outline_alpha = max(outline_alpha, texture(TEXTURE, UV - vec2(0.0, size.y)).a);
        
        outline_alpha *= (1.0 - current.a);
        
        vec4 outline = vec4(outline_color.rgb, current_alpha * outline_alpha);
        COLOR = mix(current, outline, outline_alpha);
    }
}