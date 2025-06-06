// From: https://godotshaders.com/shader/holographic-disc-pattern/

shader_type canvas_item;
render_mode unshaded;

uniform float scale = 1.0;
uniform float gradient_power = 10.;
uniform vec3 color_base:source_color;
uniform vec3 color_shine_a:source_color;
uniform vec3 color_shine_b:source_color;
uniform float gradient_rotation:hint_range(0, 3.141592654);
uniform sampler2D hue_shift_map:hint_default_black;
uniform float hue_shift_strength:hint_range(-1.,1.);
uniform bool screen_uv = false;

const vec2 POSITIONS[] = {
	vec2(0, .5),
	vec2(.5,0),
	vec2(-.5,0),
	vec2(0, -.5)
};

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float circle(vec2 uv) {
	return 1.0 - step(.5, distance(uv, vec2(.5)));
}

float radial_gradient(vec2 uv, float target_angle) {
	float angle_to_center = atan(.5 - uv.y, .5 - uv.x);
	target_angle += gradient_rotation;
	float distance_to_angle = max(
		sin(angle_to_center + target_angle),
		sin(angle_to_center + target_angle + PI)
	);
	distance_to_angle = pow(distance_to_angle, gradient_power);
	return distance_to_angle;
}

void fragment() {
	vec2 base_uv = UV;
	if (screen_uv) {
		
		float aspect = SCREEN_PIXEL_SIZE.y/SCREEN_PIXEL_SIZE.x;
		base_uv = vec2(SCREEN_UV.x, SCREEN_UV.y*aspect);
	}
	vec2 uv = base_uv * scale;
	uv = fract(uv);

	vec3 color;
	for (int i = 0; i < POSITIONS.length(); i++) {
		vec2 offset_uv = uv + POSITIONS[i];

		vec3 circle_color = color_base;
		circle_color = mix(circle_color, color_shine_a,  radial_gradient(offset_uv, 0.0));
		circle_color = mix(circle_color, color_shine_b,  radial_gradient(offset_uv, PI/2.));

		color = mix(color, circle_color, circle(offset_uv));
	}

	float shift = texture(hue_shift_map, base_uv).r;
	vec3 hsv = rgb2hsv(color);
	hsv.r += shift * hue_shift_strength;
	color = hsv2rgb(hsv);

	//COLOR.b = color.b;
	//COLOR.r = color.r;
	//COLOR.g = color.g;
	COLOR = vec4(color.r, color.g, color.b, 1);	
}