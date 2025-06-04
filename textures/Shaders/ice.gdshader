// from: https://godotshaders.com/shader/2d-reflective-ice/

shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D Tile;


void fragment() {
// Texture:2
	vec4 ref = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, 1.0 - SCREEN_UV.y - 0.13));
	vec4 ice = texture(Tile, UV.xy);

// Output:0
	COLOR = ice/2.0 + ref/2.0;
}