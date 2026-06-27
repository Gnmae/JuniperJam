shader_type canvas_item;
render_mode blend_mix;

uniform vec4 base_color : source_color = vec4(1.0, 0.98, 0.9, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    vec3 color = tex.rgb * base_color.rgb;
    COLOR = vec4(clamp(color, 0.0, 1.0), base_color.a * tex.a);
}