shader_type canvas_item;

void vertex() {
	VERTEX += vec2(cos(TIME)*100.0, sin(TIME)*100.0);
}

void fragment() {
	COLOR = texture(TEXTURE, UV); // Read from texture again.
	COLOR = vec4(UV, 0.5, 1.0);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
