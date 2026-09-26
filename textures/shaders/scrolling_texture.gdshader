// Thanks to: https://godotshaders.com/shader/panning/

shader_type canvas_item;

// --- Uniforms --- //
uniform vec2 speed = vec2(1.0, 0.0);

// --- Functions --- //
void fragment() {
	COLOR = texture(TEXTURE, mod(UV + TIME * speed, 0.10) + vec2(0.1, 0.6));
}