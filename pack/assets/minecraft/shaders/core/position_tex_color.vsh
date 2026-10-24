#version 330
#extension GL_ARB_separate_shader_objects : require

layout(std140) uniform DynamicTransforms {
mat4 ModelViewMat;
mat4 TextureMat;
vec4 ColorModulator;
vec3 ModelOffset;
};
layout(std140) uniform Projection {
mat4 ProjMat;
};
layout(std140) uniform Globals {
ivec3 CameraBlockPos;
float GlintAlpha;
vec3 CameraOffset;
float GameTime;
vec2 ScreenSize;
int MenuBlurRadius;
int UseRgss;
};

layout(location = 0) in vec3 Position;
layout(location = 1) in vec2 UV0;
layout(location = 2) in vec4 Color;

layout(location = 0) out vec2 texCoord0;
layout(location = 1) out vec4 vertexColor;
layout(location = 2) out vec2 mcbPos;
layout(location = 3) flat out vec2 mcbSize;
layout(location = 4) flat out float mcbSeated;

bool mcb_near(float v, float t) { return abs(v - t) < 0.0001; }
bool mcb_grid(float v) { return mcb_near(v, 0.0) || mcb_near(v, 0.5) || mcb_near(v, 1.0); }
float mcb_flag(float v) { return abs(fract(v * 16.0) - 0.375000) < 0.002 ? 1.0 : 0.0; }
// Seated cameras sit at a flagged fraction of a block along one horizontal axis and on the half-block
// grid on the other two: 0 for x, 2 for z. An overlay's camera is the player's own eye with all three
// flagged (each moved at most 1/32 of a block): 1. -1 when this camera is not seated.
int mcb_flag_axis() {
vec3 f = -CameraOffset;
if (mcb_flag(f.x) > 0.0 && mcb_flag(f.y) > 0.0 && mcb_flag(f.z) > 0.0) return 1;
if (!mcb_grid(f.y)) return -1;
if (mcb_grid(f.z) && mcb_flag(f.x) > 0.0) return 0;
if (mcb_grid(f.x) && mcb_flag(f.z) > 0.0) return 2;
return -1;
}
float mcb_seated_flag() { return mcb_flag_axis() >= 0 ? 1.0 : 0.0; }
// Only orthographic (GUI) draws: perspective projections have ProjMat[3][3] == 0.
float mcb_seated_now() { return ProjMat[3][3] != 1.0 ? 0.0 : mcb_seated_flag(); }
vec2 mcb_gui_size() { return vec2(2.0 / abs(ProjMat[0][0]), 2.0 / abs(ProjMat[1][1])); }
// Reversed depth (near 1, far 0) has ProjMat[2][2] near 0; OpenGL's classic has it near -1.
float mcb_reversed() { return ProjMat[2][2] > -0.5 ? 1.0 : 0.0; }

void main() {
gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
texCoord0 = UV0;
vertexColor = Color;
mcbPos = (ModelViewMat * vec4(Position, 1.0)).xy;
mcbSize = mcb_gui_size();
mcbSeated = mcb_seated_now();
}
