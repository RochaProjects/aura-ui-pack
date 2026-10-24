#version 330

layout(std140) uniform DynamicTransforms {
mat4 ModelViewMat;
vec4 ColorModulator;
vec3 ModelOffset;
mat4 TextureMat;
};

uniform sampler2D Sampler0;

in vec2 texCoord0;
in vec4 vertexColor;
in vec2 mcbPos;
flat in vec2 mcbSize;
flat in float mcbSeated;

out vec4 fragColor;

bool mcb_in(vec2 p, vec2 a, vec2 b) { return p.x >= a.x && p.x <= b.x && p.y >= a.y && p.y <= b.y; }
bool mcb_hud(vec2 pos, vec2 size) {
float cx = floor(size.x / 2.0);
return mcb_in(pos, vec2(cx - 122.0, size.y - 24.0), vec2(cx + 122.0, size.y))
|| mcb_in(pos, vec2(cx - 92.0, size.y - 64.0), vec2(cx + 92.0, size.y - 22.0));
}
bool mcb_crosshair(vec2 pos, vec2 size) {
vec2 c = floor(size / 2.0);
return mcb_in(pos, c - 9.0, c + 9.0);
}

void main() {
// 16x16 textures are the dimmed tiles behind menus (Esc, options): never cut.
if (mcbSeated > 0.5 && textureSize(Sampler0, 0) != ivec2(16, 16)) {
// The vignette is the only standalone 256x256 texture the HUD draws.
if (textureSize(Sampler0, 0) == ivec2(256, 256)) discard;
if (mcb_hud(mcbPos, mcbSize)) discard;
}
vec4 color = texture(Sampler0, texCoord0) * vertexColor;
// The crosshair is pure white; a menu button in the middle of the window is not.
if (mcbSeated > 0.5 && mcb_crosshair(mcbPos, mcbSize) && all(greaterThan(color.rgb, vec3(0.99)))) discard;
if (color.a == 0.0) {
discard;
}
fragColor = color * ColorModulator;
}
