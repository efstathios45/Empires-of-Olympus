// Stylized billboard grass — web / GL Compatibility (WebGL2) safe.
//
// Ports the look of Dylearn's "3D Pixel Art Grass" (MIT code, CC BY 4.0 art —
// "Grass assets by Dylearn") into a Compatibility-safe shader. The original
// uses a custom light() function + LIGHT_VERTEX, which the web renderer does
// NOT support, so all lighting is done manually here with `unshaded`:
//   - heterogeneity: world-position noise picks between grass color patches
//   - accent leaves: a % of instances (by INSTANCE_ID) use a taller accent sprite
//   - wind: per-clump noise drives tip sway + a "fake perspective" UV squash
//   - toon: manual sun diffuse, banded, varied across the field by moving
//           cloud-shadow noise (the global-cloud-shadow trick)
//   - Y-billboard so the card always faces the camera, distance-fade LOD
//
// Mesh UV contract: UV.y = 1 at the BASE, UV.y = 0 at the TIP.

shader_type spatial;
render_mode cull_disabled, unshaded, depth_draw_opaque;

group_uniforms textures;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap;
uniform sampler2D accent_tex : source_color, filter_linear_mipmap;
uniform sampler2D patch_noise : filter_linear, repeat_enable;
uniform sampler2D wind_noise : filter_linear, repeat_enable;
uniform sampler2D cloud_noise : filter_linear, repeat_enable;

group_uniforms color;
uniform vec3 grass_color : source_color = vec3(0.42, 0.66, 0.24);
uniform vec3 patch_color2 : source_color = vec3(0.30, 0.52, 0.18);
uniform vec3 patch_color3 : source_color = vec3(0.58, 0.74, 0.30);
uniform float patch_scale = 0.02;
uniform float patch2_threshold = 0.58;
uniform float patch3_threshold = 0.72;
uniform vec3 accent_color : source_color = vec3(0.92, 0.86, 0.36);
uniform float accent_freq : hint_range(0.0, 0.3) = 0.07;
uniform float base_darken : hint_range(0.0, 1.0) = 0.45;

group_uniforms lighting;
uniform vec3 sun_dir = vec3(0.5, -0.72, 0.45);          // direction the light travels
uniform vec3 sun_color : source_color = vec3(1.0, 0.96, 0.86);
uniform vec3 ambient_color : source_color = vec3(0.42, 0.48, 0.52);
uniform float toon_cuts : hint_range(1.0, 6.0) = 3.0;
uniform float toon_softness : hint_range(0.0, 1.0) = 0.25;

group_uniforms clouds;
uniform bool clouds_on = true;
uniform float cloud_scale = 0.012;
uniform float cloud_speed = 0.01;
uniform float cloud_strength : hint_range(0.0, 1.0) = 0.5;
uniform int cloud_pattern : hint_range(0, 24) = 0;   // 25 scroll/wave patterns (see fragment)
uniform float wind_angle = 0.61;                     // shadow scroll direction (radians)
uniform float wave_freq = 0.12;                      // sine wavelength (sine mode)
uniform float wave_amount : hint_range(0.0, 1.0) = 0.45;  // sine vs noise blend (sine mode)
// Green gradient the noise drives: shaded green (low) -> sunlit green (high),
// multiplied over the base so the scrolling noise reads as green dappling.
uniform vec3 cloud_grad_low : source_color = vec3(0.38, 0.52, 0.20);   // shaded -> darker GREEN
uniform vec3 cloud_grad_high : source_color = vec3(1.05, 1.10, 0.85);  // sunlit -> brighter green

group_uniforms shape;
uniform float height_scale : hint_range(0.2, 1.6) = 1.0;
uniform float width_scale : hint_range(0.2, 2.0) = 1.0;

group_uniforms animation;
uniform bool wind_on = true;
uniform float wind_strength : hint_range(0.0, 1.0) = 0.22;
uniform float wind_speed : hint_range(0.0, 1.0) = 0.07;
uniform float wind_scale : hint_range(0.0, 0.2) = 0.05;
// Dynamic wind field: low-freq zones (some calm, some windy), per-region
// direction, and a travelling gust front. All web-safe (2 noise fetches).
uniform float wind_zone_scale = 0.012;                       // smaller = larger zones
uniform float wind_calm_thresh : hint_range(0.0, 1.0) = 0.34; // below this a zone is dead-calm
uniform float wind_gust_freq = 0.03;                         // gust wavelength
uniform float wind_gust_speed = 1.1;                         // gust travel speed
uniform float wind_gust_amount : hint_range(0.0, 1.0) = 0.6; // how strongly gusts pulse

group_uniforms interaction;
// Player parting: blades within player_radius of player_position bend away from
// the character and press down. player_position is pushed in each frame.
uniform vec3 player_position = vec3(99999.0, 0.0, 99999.0);
uniform float player_radius = 2.0;
uniform float player_push = 0.7;

group_uniforms lod;
uniform bool fade_on = true;
uniform float view_fade_start = 28.0;
uniform float view_fade_end = 46.0;
uniform float alpha_clip : hint_range(0.0, 1.0) = 0.4;
// Some billboard textures (the "binbun" set) store a dark-grey background in the
// RGB of their transparent pixels. After sRGB->linear that grey is ~0.026 — near
// black — and linear/mipmap filtering bleeds it into the alpha-cut blade edges,
// producing dark "black background" halos. When bg_key_clip > 0 we colour-key it
// out: any pixel whose brightest channel is below the clip is treated as
// background and discarded. 0 = off (clean alpha-only textures, e.g. pixel art).
uniform float bg_key_clip : hint_range(0.0, 0.3) = 0.0;

group_uniforms mode;
uniform bool use_texture = true;   // false = procedural geometry (no alpha cutout)
uniform bool billboard_on = true;  // false = use the mesh's own orientation (procedural clusters)

varying vec3 v_origin;
varying float v_accent;
varying float v_wind;

float rnd(float n) { return fract(sin(n * 12.9898) * 43758.5453); }

void vertex() {
	v_origin = MODEL_MATRIX[3].xyz;
	float id = float(INSTANCE_ID);
	v_accent = rnd(id) < accent_freq ? 1.0 : 0.0;
	float tip = 1.0 - UV.y;
	VERTEX.y *= height_scale;
	VERTEX.x *= width_scale;
	VERTEX.z *= width_scale;
	if (v_accent > 0.5) {
		VERTEX.y *= 1.5;  // accent leaves are taller
	}

	// ── Dynamic wind: spatial zones + per-region direction + travelling gusts ──
	// One low-freq field sample gives BOTH the per-zone strength (some areas are
	// dead calm, some windy) and the per-region blow direction; a moving gust
	// front pulses the windy zones; a high-freq flutter sample adds the lively
	// out-of-phase detail. Only one extra noise fetch vs. the old global sway.
	float w = 0.0;
	if (wind_on) {
		vec2 wp = v_origin.xz;
		float field = texture(wind_noise, wp * wind_zone_scale + vec2(2.3, 7.1)).r;
		float zone = smoothstep(wind_calm_thresh, 0.85, field);   // 0 in calm zones
		float ang = field * 6.2831 + wind_angle;                  // direction per region
		vec2 wdir = vec2(cos(ang), sin(ang));
		float gust = 0.5 + 0.5 * sin(dot(wp, wdir) * wind_gust_freq - TIME * wind_gust_speed);
		gust = mix(1.0, gust, wind_gust_amount);
		vec2 fuv = wp * wind_scale + vec2(TIME * wind_speed, TIME * wind_speed * 0.7);
		float flutter = (texture(wind_noise, fuv).r - 0.5) * 2.0;
		float amp = wind_strength * zone * gust;
		// Steady directional lean + lively flutter, both fading to 0 at the base.
		vec2 sway = wdir * (amp * 0.5 + flutter * amp);
		VERTEX.x += sway.x * tip;
		VERTEX.z += sway.y * tip;
		w = flutter * zone * gust;
	}
	v_wind = w;

	// ── Player parting: blades near the character bend away from him and the
	// tips press down, so you can see where the player is walking. ──
	{
		vec2 to_blade = v_origin.xz - player_position.xz;
		float pdist = length(to_blade);
		float infl = 1.0 - smoothstep(player_radius * 0.35, player_radius, pdist);
		if (infl > 0.0) {
			vec2 pdir = pdist > 0.001 ? to_blade / pdist : vec2(0.0, 1.0);
			VERTEX.x += pdir.x * player_push * tip * infl;
			VERTEX.z += pdir.y * player_push * tip * infl;
			VERTEX.y -= player_push * 0.55 * tip * infl;
		}
	}

	// Cheap LOD: collapse far clusters to a point (kills horizon overdraw).
	if (fade_on) {
		float d = length(v_origin.xz - CAMERA_POSITION_WORLD.xz);
		VERTEX *= 1.0 - smoothstep(view_fade_start, view_fade_end, d);
	}

	// Adaptive billboard: upright (Y-billboard) at eye level, blending toward
	// a full camera-facing billboard as the view tilts down — so from above
	// the cards present their face instead of converging edge-on ("pinwheel").
	// Procedural clusters (billboard_on = false) keep their own orientation.
	if (billboard_on) {
		float sx = length(MODEL_MATRIX[0].xyz);
		float sy = length(MODEL_MATRIX[1].xyz);
		vec3 to_view = INV_VIEW_MATRIX[2].xyz;             // world dir toward the camera
		float downness = clamp(to_view.y, 0.0, 1.0);       // 0 = level, 1 = straight down
		vec3 up = normalize(mix(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[1].xyz, downness));
		vec3 right = normalize(cross(up, to_view));
		vec3 normal = normalize(cross(right, up));
		// Per-instance depth nudge ALONG THE VIEW RAY: billboards all face the
		// camera (coplanar), so without a unique depth per card the depth test
		// ties and far blades bleed/flicker THROUGH the nearer ones (the slope
		// "see-through" — worse on hills because neighbouring blades sit at very
		// different altitudes yet project to nearly equal depth). Offsetting each
		// card toward the camera by a well-spread per-instance amount gives every
		// blade a distinct, stable depth so the test never ties. Because the
		// offset is along the line of sight it changes depth only, NOT the blade's
		// projected screen position, so it is invisible. Two decorrelated hashes
		// over a wider range make ties between overlapping neighbours vanishingly
		// rare even on steep slopes.
		// CRITICAL: the nudge must be TINY up close and only grow with distance.
		// A flat (distance-independent) nudge of e.g. 0.4 m pulls FAR blades up to
		// 0.4 m toward the camera — and up close, where neighbouring blades sit
		// only ~0.1-0.3 m apart, that reorders them so a blade that should be
		// hidden BEHIND a nearer one pops in FRONT of it. That is exactly the
		// "see through layers / far blades not occluded" artifact. Z-fighting
		// (equal-depth ties) only happens at mid/far range where blade spacing is
		// large, so scale the nudge by camera distance: ~0 up close (true depth
		// order preserved, near fully occludes far) ramping to a few cm far away
		// (enough to break ties). Always along the view ray, so depth-only.
		vec3 origin = MODEL_MATRIX[3].xyz;
		vec3 cam_delta = CAMERA_POSITION_WORLD - origin;
		float cam_dist = length(cam_delta);
		vec3 to_cam = cam_dist > 0.001 ? cam_delta / cam_dist : vec3(0.0, 0.0, 1.0);
		float jitter = rnd(id + 3.0) * 0.7 + rnd(id * 0.0137 + 5.1) * 0.3;
		float nudge = jitter * clamp(cam_dist * 0.008, 0.0, 0.35);
		origin += to_cam * nudge;
		mat4 bb = mat4(
			vec4(right * sx, 0.0),
			vec4(up * sy, 0.0),
			vec4(normal, 0.0),
			vec4(origin, 1.0)
		);
		MODELVIEW_MATRIX = VIEW_MATRIX * bb;
	}
}

void fragment() {
	float tip = 1.0 - UV.y;

	// Fake perspective: squash UV.x toward the tip by the wind amount.
	vec2 uv = UV;
	uv.x = (uv.x - 0.5) * (1.0 + tip * v_wind * 0.3) + 0.5;
	uv.x = clamp(uv.x, 0.0, 1.0);

	vec4 tex = vec4(1.0);
	if (use_texture) {
		tex = v_accent > 0.5 ? texture(accent_tex, uv) : texture(grass_tex, uv);
		if (tex.a < alpha_clip) {
			discard;
		}
		// Colour-key out the dark-grey background bleed (see bg_key_clip above).
		// The background/fringe is dark AND grey (r≈g≈b); blades are green-
		// dominant even where dark. So only discard pixels that are both dark
		// (brightest channel below the clip) AND not green — this lets the clip
		// sit above the background grey without ever erasing dark blade pixels.
		if (bg_key_clip > 0.0) {
			float mx = max(tex.r, max(tex.g, tex.b));
			float greenness = tex.g - max(tex.r, tex.b);
			if (mx < bg_key_clip && greenness < 0.012) {
				discard;
			}
		}
	}

	// Heterogeneity: world-position noise selects a color patch.
	vec3 base = grass_color;
	float pn = texture(patch_noise, v_origin.xz * patch_scale).r;
	if (pn > patch3_threshold) {
		base = patch_color3;
	} else if (pn > patch2_threshold) {
		base = patch_color2;
	}
	if (v_accent > 0.5) {
		base = accent_color;
	}
	vec3 albedo = base * tex.rgb;
	// Vertical depth gradient — darker at the base.
	albedo *= mix(base_darken, 1.0, tip);

	// Manual toon diffuse (unshaded). Up-facing normal -> consistent field
	// lighting; moving cloud-shadow noise varies it so toon bands read.
	float nl = clamp(dot(vec3(0.0, 1.0, 0.0), -normalize(sun_dir)), 0.0, 1.0);
	float shade = max(nl, 0.15);
	float cloud_v = 0.5;   // noise intensity -> drives the green gradient below
	if (clouds_on) {
		// 25 selectable shadow patterns. Shared knobs: wind_angle (direction),
		// cloud_speed (pace), cloud_scale (size), wave_freq (wavelength),
		// wave_amount (sine/noise blend), cloud_strength (darkness).
		vec2 wdir = vec2(cos(wind_angle), sin(wind_angle));
		vec2 perpd = vec2(-wdir.y, wdir.x);
		vec2 wp = v_origin.xz;
		vec2 base = wp * cloud_scale;
		vec2 scroll = wdir * (TIME * cloud_speed);
		float at = TIME * cloud_speed * 50.0;   // sine animation time (Speed-driven)
		float ph = dot(wp, wdir);
		float pp = dot(wp, perpd);
		float c = 0.5;

		if (cloud_pattern == 0) {
			vec2 cuv = base + scroll + perpd * (sin(ph * wave_freq * 1.5 - at) * 0.06);
			float n = texture(cloud_noise, cuv).r;
			float wave = 0.5 + 0.5 * sin(ph * wave_freq - at);
			c = smoothstep(0.35, 0.78, mix(n, wave, wave_amount));
		} else if (cloud_pattern == 1) {
			float n1 = texture(cloud_noise, base + scroll).r;
			float n2 = texture(cloud_noise, base * 1.7 + scroll * 1.7).r;
			c = n1 * 0.6 + n2 * 0.4;
		} else if (cloud_pattern == 2) {
			c = texture(cloud_noise, base + scroll).r;
		} else if (cloud_pattern == 3) {
			c = (0.5 + 0.5 * sin(ph * wave_freq - at)) * (0.5 + 0.5 * sin(pp * wave_freq - at * 0.8));
		} else if (cloud_pattern == 4) {
			c = 0.5 + 0.5 * sin(length(wp) * wave_freq - at);
		} else if (cloud_pattern == 5) {
			c = texture(cloud_noise, vec2(ph * cloud_scale * 0.35, pp * cloud_scale * 2.2) + vec2(0.0, at * 0.02)).r;
		} else if (cloud_pattern == 6) {
			float w = texture(cloud_noise, base * 0.5 + scroll * 0.5).r;
			c = texture(cloud_noise, base + vec2(w) * 0.3 + scroll).r;
		} else if (cloud_pattern == 7) {
			c = abs(texture(cloud_noise, base + scroll).r - 0.5) * 2.0;
		} else if (cloud_pattern == 8) {
			c = smoothstep(0.45, 0.55, 0.5 + 0.5 * sin(ph * wave_freq - at));
		} else if (cloud_pattern == 9) {
			c = 0.5 + 0.5 * sin(ph * wave_freq + texture(cloud_noise, base * 2.0).r * 6.283 - at);
		} else if (cloud_pattern == 10) {
			c = texture(cloud_noise, base + scroll).r * (0.6 + 0.4 * sin(at));
		} else if (cloud_pattern == 11) {
			c = 0.5 + 0.5 * sin(ph * wave_freq - at) * sin(ph * wave_freq * 1.12 - at * 0.9);
		} else if (cloud_pattern == 12) {
			c = 0.5 + 0.5 * sin(pp * wave_freq - at);
		} else if (cloud_pattern == 13) {
			c = texture(cloud_noise, base + scroll).r * texture(cloud_noise, base * 1.3 + perpd * (TIME * cloud_speed)).r;
		} else if (cloud_pattern == 14) {
			float ang = length(wp) * 0.05;
			mat2 rot = mat2(vec2(cos(ang), -sin(ang)), vec2(sin(ang), cos(ang)));
			c = texture(cloud_noise, rot * base + scroll).r;
		} else if (cloud_pattern == 15) {
			c = 0.5 + 0.5 * sin(texture(cloud_noise, base + scroll).r * 6.283 * max(wave_freq * 6.0, 1.0) - at);
		} else if (cloud_pattern == 16) {
			float band = fract(ph * cloud_scale * 2.0 - at * 0.05);
			c = smoothstep(0.0, 0.5, band) * smoothstep(1.0, 0.5, band);
		} else if (cloud_pattern == 17) {
			vec2 ctr = vec2(sin(at * 0.3), cos(at * 0.27)) * 20.0;
			c = 0.5 + 0.5 * sin(length(wp - ctr) * wave_freq - at);
		} else if (cloud_pattern == 18) {
			c = (0.5 + 0.5 * sin(ph * wave_freq - at)) * texture(cloud_noise, base + scroll).r;
		} else if (cloud_pattern == 19) {
			c = 0.5 + 0.5 * sin(wp.x * wave_freq - at);
		} else if (cloud_pattern == 20) {
			c = 0.5 + 0.5 * sin(wp.y * wave_freq - at);
		} else if (cloud_pattern == 21) {
			float a = atan(pp, ph);
			c = 0.5 + 0.5 * sin(length(wp) * wave_freq + a * 3.0 - at);
		} else if (cloud_pattern == 22) {
			float s = sin(ph * wave_freq - at)
				+ sin((ph * 0.5 + pp * 0.866) * wave_freq - at)
				+ sin((ph * 0.5 - pp * 0.866) * wave_freq - at);
			c = 0.5 + 0.16 * s;
		} else if (cloud_pattern == 23) {
			c = texture(cloud_noise, base + scroll).r * 0.5 + texture(cloud_noise, base * 1.9 - scroll * 0.7).r * 0.5;
		} else {
			c = smoothstep(wave_amount - 0.08, wave_amount + 0.08, texture(cloud_noise, base + scroll).r);
		}

		cloud_v = clamp(c, 0.0, 1.0);
	}
	float cuts = max(toon_cuts, 1.0);
	float banded = floor(shade * cuts + 0.5) / cuts;
	banded = mix(banded, shade, toon_softness);

	ALBEDO = albedo * (ambient_color + sun_color * banded);
	// Green-gradient dappling: the scrolling noise picks a green between a
	// shaded and a sunlit tone, multiplied over the base color.
	if (clouds_on) {
		vec3 cgrad = mix(cloud_grad_low, cloud_grad_high, cloud_v);
		ALBEDO *= mix(vec3(1.0), cgrad, cloud_strength);
	}
	// IMPORTANT: do NOT write ALPHA. In Godot 4 any write to ALPHA — even a
	// constant 1.0 — flags the material as TRANSPARENT, which routes it to the
	// transparent pipeline where `depth_draw_opaque` means it writes NO depth.
	// With no depth writes the blades can't occlude each other, so you see
	// straight through the grass mass to whatever is behind it. By leaving ALPHA
	// unwritten the shader stays OPAQUE: it renders in the opaque pass with depth
	// write + depth test, and the `discard` above gives the hard alpha cutout.
	// Near blades now correctly occlude everything behind them.
}
