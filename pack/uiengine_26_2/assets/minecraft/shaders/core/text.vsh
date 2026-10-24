#version 330

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:sample_lightmap.glsl>
#endif

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:globals.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
in ivec2 UV2;
#endif

uniform sampler2D Sampler0;

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
uniform sampler2D Sampler2;
out float sphericalVertexDistance;
out float cylindricalVertexDistance;
#endif

out vec4 vertexColor;
out vec2 texCoord0;
out vec2 mcbPos;
flat out vec2 mcbSize;
flat out float mcbSeated;
flat out float mcbPointer;
flat out float mcbReversed;
// Which of our maps this is (mcb_screen_map) and how its data blocks are filled (mcb_fill_right), and
// for someone's own view its tint: worked out here once per vertex rather than in every pixel.
flat out vec2 mcbMapInfo;
flat out vec4 mcbViewTint;

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

// ---- MC GUI hi-colour map decoder ----
// Colour -> symbol in one table read: a perfect hash into 4096 byte slots, four to a uint, each
// holding its symbol plus one (SymbolHash builds the table).
const uint MCB_T[1024] = uint[1024](0u,0u,0u,251658240u,0u,0u,0u,0u,101u,0u,0u,4390912u,0u,0u,0u,0u,0u,0u,15104u,0u,0u,0u,0u,0u,201326592u,0u,12976128u,4009754624u,0u,0u,0u,0u,0u,41984u,0u,0u,0u,0u,10092544u,18887u,0u,0u,0u,553648128u,0u,0u,0u,204u,1644167168u,0u,0u,0u,0u,33554432u,7536640u,0u,0u,0u,0u,26368u,0u,0u,4096u,0u,0u,45056u,184549376u,3892314209u,0u,0u,0u,0u,14286848u,0u,0u,0u,0u,0u,3187671040u,20480u,181u,0u,0u,0u,0u,0u,51968u,0u,0u,0u,0u,620756992u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,21760u,0u,0u,0u,0u,0u,0u,0u,2080374784u,0u,0u,0u,107u,4456448u,0u,0u,0u,0u,0u,0u,0u,0u,0u,2785017856u,0u,0u,220u,0u,0u,0u,57344u,0u,34816u,0u,4718826u,155u,14352384u,0u,5632u,0u,0u,2348810240u,13828096u,2969567232u,0u,0u,0u,113u,207u,0u,0u,0u,0u,0u,0u,1090519040u,0u,0u,0u,0u,0u,0u,44544u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,29u,0u,0u,0u,0u,0u,0u,192u,1358954496u,0u,0u,0u,0u,0u,0u,0u,0u,1879048192u,0u,42752u,0u,0u,0u,0u,0u,0u,0u,0u,1536u,3942645760u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,79u,0u,0u,0u,0u,0u,0u,0u,0u,52u,0u,0u,2550136832u,0u,0u,3607101440u,0u,71u,64u,0u,0u,0u,458096640u,0u,35584u,0u,0u,0u,0u,0u,0u,0u,0u,0u,3808428032u,0u,0u,0u,0u,0u,111u,0u,0u,0u,0u,0u,3003121664u,0u,0u,0u,0u,222u,318767104u,0u,0u,0u,3388997632u,0u,0u,0u,0u,0u,0u,0u,3640679680u,0u,0u,0u,0u,12058624u,0u,32000u,0u,0u,0u,3556810240u,0u,2949120u,8978432u,2063597568u,48896u,0u,0u,0u,0u,0u,3623878656u,11337728u,0u,3154116608u,0u,0u,0u,0u,0u,0u,39936u,0u,0u,17920u,0u,0u,0u,0u,88u,25344u,0u,120u,0u,0u,0u,0u,0u,0u,0u,0u,31u,0u,0u,0u,3909091328u,0u,0u,0u,0u,0u,0u,0u,0u,57856u,0u,0u,0u,0u,0u,0u,0u,738197504u,11796480u,0u,0u,352321536u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,132u,128u,0u,0u,6029312u,0u,956301312u,100u,0u,0u,0u,0u,0u,0u,30976u,0u,0u,0u,0u,0u,0u,0u,3439329280u,0u,0u,0u,5701632u,53504u,14483456u,0u,0u,0u,0u,0u,3328u,0u,0u,0u,0u,0u,0u,0u,0u,335544320u,0u,0u,0u,0u,0u,0u,223u,0u,0u,12800u,58624u,0u,60672u,2499805184u,0u,0u,0u,0u,9043968u,0u,0u,0u,0u,0u,19456u,162u,0u,2852126720u,0u,0u,0u,0u,225u,0u,0u,2228406u,0u,1107296256u,0u,23040u,0u,3523215360u,0u,0u,9984u,0u,0u,0u,0u,0u,52736u,0u,587202560u,0u,5888u,2415919104u,0u,10240u,0u,12386304u,0u,0u,0u,84u,0u,4026531840u,0u,67108864u,1811939328u,0u,0u,0u,0u,0u,0u,2818572288u,0u,0u,0u,0u,3825205248u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,14336u,0u,0u,0u,0u,0u,0u,0u,0u,1392508928u,0u,0u,0u,13971200u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,1375731712u,0u,0u,0u,0u,0u,0u,0u,12845056u,2566914048u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,721420288u,0u,0u,0u,0u,0u,12255232u,160u,2835349504u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,45568u,150u,0u,0u,0u,0u,0u,0u,0u,0u,0u,41728u,0u,59136u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,3992977408u,0u,109u,0u,29184u,2130706432u,13824u,0u,10496u,0u,0u,0u,10551296u,0u,3604480u,22784u,0u,0u,0u,0u,0u,0u,3120562176u,0u,0u,7208960u,0u,0u,0u,0u,147u,0u,0u,0u,0u,0u,8716288u,0u,2634022912u,118u,0u,49664u,0u,208u,256u,0u,0u,0u,301989888u,0u,0u,0u,3103784960u,0u,0u,2490368u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,1056964608u,0u,7680u,0u,0u,0u,0u,11272192u,0u,0u,165u,0u,0u,0u,143u,0u,0u,0u,0u,0u,0u,0u,28u,0u,0u,0u,0u,0u,0u,0u,0u,150994944u,0u,0u,0u,0u,0u,0u,0u,0u,1946157056u,0u,0u,230u,0u,0u,0u,0u,0u,196608u,0u,102u,0u,0u,0u,0u,0u,0u,0u,0u,0u,214u,3584u,0u,0u,0u,0u,0u,0u,0u,0u,2432696320u,0u,58u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,9240576u,0u,134u,0u,0u,0u,0u,0u,105u,0u,0u,0u,0u,0u,2752512u,0u,3997696u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,53u,0u,0u,0u,0u,0u,0u,0u,0u,0u,327680u,0u,0u,0u,22016u,0u,0u,0u,0u,0u,32256u,0u,0u,0u,8847360u,0u,0u,1638400u,7u,0u,0u,0u,0u,0u,0u,183u,0u,0u,0u,0u,0u,0u,0u,0u,236u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,3372220416u,0u,2359296u,0u,0u,0u,0u,0u,0u,0u,0u,2164260864u,0u,18944u,0u,33536u,0u,402653184u,1291845632u,0u,0u,0u,2449473536u,0u,0u,822083584u,0u,0u,6656u,0u,0u,0u,0u,0u,0u,0u,0u,0u,536870912u,6291456u,0u,2046820352u,9699328u,117u,0u,0u,0u,0u,285212672u,0u,0u,0u,0u,0u,0u,51200u,2667610624u,4063232u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,75u,0u,655360u,23296u,0u,2152u,0u,9306112u,11776u,0u,0u,0u,0u,1996488704u,0u,0u,0u,0u,0u,193u,0u,0u,0u,13056u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,805306368u,0u,4521984u,0u,3932160u,0u,0u,0u,0u,0u,175u,6946816u,0u,0u,0u,171u,0u,0u,0u,0u,12779520u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,24320u,9895936u,6160384u,0u,0u,197u,0u);

ivec3 mcb_fetch(ivec2 p) { return ivec3(round(texelFetch(Sampler0, p, 0).rgb * 255.0)); }

int mcb_symbol_of(vec3 rgb) {
uvec3 c = uvec3(round(rgb * 255.0));
uint slot = (((c.r << 16u) | (c.g << 8u) | c.b) * 2863661571u) >> 20u;
return max(int((MCB_T[slot >> 2u] >> ((slot & 3u) << 3u)) & 255u) - 1, 0);
}

int mcb_symbol(ivec2 p) { return mcb_symbol_of(texelFetch(Sampler0, p, 0).rgb); }

// 0: not ours. 1: a screen. 2: the view of whoever is seated at it (bottom markers swapped).
// 3: such a view whose pointer their client places, each map carrying its place (both the fourth).
// text.vsh then tells two kinds of 3 apart for text.fsh: 5, an overlay's signature map, and 6, a map of
// an overlay's panel. 7: a hover layer of a view as 3 (Palette.markLayer): top markers swapped too.
int mcb_screen_map() {
if (textureSize(Sampler0, 0) != ivec2(128, 128)) return 0;
ivec3 m0 = mcb_fetch(ivec2(0, 0)), m1 = mcb_fetch(ivec2(1, 0));
bool layer = m0 == ivec3(109,144,129) && m1 == ivec3(89,117,105);
if (!layer && (m0 != ivec3(89,117,105) || m1 != ivec3(109,144,129))) return 0;
ivec3 a = mcb_fetch(ivec2(0, 1));
ivec3 b = mcb_fetch(ivec2(1, 1));
if (layer) return a == ivec3(67,88,79) && b == ivec3(67,88,79) ? 7 : 0;
if (a == ivec3(127,167,150) && b == ivec3(67,88,79)) return 1;
if (a == ivec3(67,88,79) && b == ivec3(127,167,150)) return 2;
if (a == ivec3(67,88,79) && b == ivec3(67,88,79)) return 3;
return 0;
}

// What someone's own view lays over the world where it is transparent (Palette.markTint): red,
// green, blue and alpha in the 2x2 block after its size.
vec4 mcb_tint() {
return vec4(float(mcb_symbol(ivec2(4, 0))), float(mcb_symbol(ivec2(5, 0))),
float(mcb_symbol(ivec2(4, 1))), float(mcb_symbol(ivec2(5, 1)))) / 239.0;
}

// How many 2x2 blocks after the marker hold data, not picture: a view's size, place and tint (2); a
// hover layer's size, place, speed, flags and two rectangles (7, the top two rows, never shown).
int mcb_info(int kind) { return kind == 7 ? 7 : kind >= 2 ? 2 : 0; }

// A 2x2 block's mean luma and its chroma, and 1 (0 for all four when it is transparent).
vec4 mcb_block(ivec2 b) {
ivec2 p = b * 2;
if (texelFetch(Sampler0, p, 0).a < 0.5) return vec4(0.0);
ivec4 s = ivec4(mcb_symbol(p), mcb_symbol(p + ivec2(1, 0)), mcb_symbol(p + ivec2(0, 1)), mcb_symbol(p + ivec2(1, 1)));
ivec4 digit = s & 7;
return vec4(dot(vec4(s >> 3), vec4(0.25)) / 29.0, float(digit.x * 8 + digit.y - 32) / 63.0,
float(digit.z * 8 + digit.w - 32) / 63.0, 1.0);
}

// 1 if a map's data blocks (row 0, up to block [info]) are best shown as the block right of them, 0 if as
// the blocks below them: right when an edge runs between the top two block rows just past the data, so
// likely through the data too, below otherwise (nearer, and right for anything that changes along the
// row). Measured on the market pages' maps, this halves how often the fill differs visibly from the
// picture it covers, against always right or always below.
float mcb_fill_right(int info) {
vec4 a = mcb_block(ivec2(info + 1, 0)), b = mcb_block(ivec2(info + 1, 1));
if (a.w != b.w) return 1.0;
vec4 d = abs(a - b);
return d.x + 0.5 * (d.y + d.z) > 0.06 ? 1.0 : 0.0;
}

#if !defined(IS_GUI)
// A point at normalised device coordinates [ndc], one block in front of the camera: in the
// clip volume whatever the projection, at the same depth for every vertex (no perspective
// warp across a quad). The fragment shader sets the real depth.
vec4 mcb_flat(vec2 ndc) {
vec4 c = ProjMat * vec4(0.0, 0.0, -1.0, 1.0);
return vec4(ndc * c.w, c.z, c.w);
}

// Where the pointer the seated player's client places itself is on a view [size] pixels big: the
// view's centre plus [speed] (pixels per degree of turn) times how far the camera has turned from
// [ahead] (the axis towards the view), held inside the view. The server works the cursor out the
// same way from the rotations the client sends.
vec2 mcb_hot(vec2 size, vec3 ahead, float speed) {
vec3 right = vec3(-ahead.z, 0.0, ahead.x);
// ModelViewMat is the camera's rotation alone; its third row is minus the look direction.
vec3 look = normalize(-vec3(ModelViewMat[0][2], ModelViewMat[1][2], ModelViewMat[2][2]));
vec2 turn = degrees(vec2(atan(dot(look, right), dot(look, ahead)), asin(clamp(-look.y, -1.0, 1.0))));
return clamp(size * 0.5 + turn * speed, vec2(0.0), size - 1.0);
}

// The pointer the seated player's client places itself, on a view [size] pixels big. Its text
// sits ahead of the camera on the flagged axis, towards the view, 0.5 + speed / 512 blocks away
// (speed in pixels per degree of turn), square to that axis: so a vertex's offset across the axis
// is the glyph's own, from its hot pixel (mcb_hot), at 128 pixels to a block.
// On an overlay (flag 1) every axis is flagged: the text's own offset says which is ahead, as the glyph
// is far smaller than its distance.
vec2 mcb_client_pointer(vec2 size) {
int flagAxis = mcb_flag_axis();
bool alongX = flagAxis == 0 || (flagAxis == 1 && abs(Position.x) > abs(Position.z));
vec3 axis = alongX ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0);
float along = dot(Position, axis);
vec3 ahead = axis * sign(along);
vec3 right = vec3(-ahead.z, 0.0, ahead.x);
vec2 hot = mcb_hot(size, ahead, (abs(along) - 0.5) * 512.0);
vec2 px = hot + vec2(dot(Position, right), -Position.y) * 128.0;
return vec2(px.x / size.x * 2.0 - 1.0, 1.0 - px.y / size.y * 2.0);
}

// A hover layer's rectangle in canvas pixels, [left, right) x [top, bottom), from the four 2x2 blocks'
// worth of symbols from x = [at] (Palette.markLayer): each edge two symbols, high then low.
float mcb_layer_edge(int x, int y) { return float(mcb_symbol(ivec2(x, y)) * 240 + mcb_symbol(ivec2(x + 1, y))); }
vec4 mcb_layer_rect(int at) { return vec4(mcb_layer_edge(at, 0), mcb_layer_edge(at, 1), mcb_layer_edge(at + 2, 0), mcb_layer_edge(at + 2, 1)); }
bool mcb_layer_in(vec2 p, vec4 r) { return p.x >= r.x && p.y >= r.y && p.x < r.z && p.y < r.w; }

// Whether a hover layer shows now: the client's pointer, worked out as the pointer's own from the speed,
// axis and side the layer carries ([flags]: 2 for z, 1 for facing it from the positive side), is inside
// its include rectangle and outside its exclude one.
bool mcb_layer_on(vec2 size, int flags) {
float speed = float((mcb_symbol(ivec2(4, 0)) * 240 + mcb_symbol(ivec2(5, 0))) * 240 + mcb_symbol(ivec2(4, 1))) / 32768.0;
vec3 axis = (flags & 2) == 0 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0);
vec2 hot = mcb_hot(size, (flags & 1) == 1 ? -axis : axis, speed);
return mcb_layer_in(hot, mcb_layer_rect(6)) && !mcb_layer_in(hot, mcb_layer_rect(10));
}
#endif

void main() {
gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
mcbReversed = mcb_reversed();
texCoord0 = UV0;
mcbPos = (ModelViewMat * vec4(Position, 1.0)).xy;
mcbSize = mcb_gui_size();
mcbPointer = 0.0;
#ifdef IS_GRAYSCALE
int mcbMap = 0;
#else
int mcbMap = mcb_screen_map();
#endif
mcbMapInfo = vec2(float(mcbMap), mcbMap > 0 && mcbMap != 7 ? mcb_fill_right(mcb_info(mcbMap)) : 0.0);
mcbViewTint = mcbMap >= 2 && mcbMap != 7 ? mcb_tint() : vec4(0.0);
#ifdef IS_GUI
mcbSeated = mcb_seated_now();
vertexColor = Color;
#else
mcbSeated = mcb_seated_flag();
vec4 mcbTint = Color;
if (mcbSeated > 0.5) {
// The pointer: text in the pointer's red, its view's columns and rows in green and blue. Drawn white.
ivec3 mcbRgb = ivec3(round(Color.rgb * 255.0));
vec2 mcbGrid = vec2(0.0);
if (mcbRgb.r == 254 && mcbRgb.g > 0 && mcbRgb.b > 0) {
mcbPointer = 1.0;
mcbGrid = vec2(mcbRgb.gb);
mcbTint = vec4(1.0, 1.0, 1.0, Color.a);
} else if (mcbRgb.r == 253 && mcbRgb.g > 0 && mcbRgb.b > 0) {
// The pointer this client places itself, from where the camera looks.
mcbPointer = 2.0;
mcbTint = vec4(1.0, 1.0, 1.0, Color.a);
gl_Position = mcb_flat(mcb_client_pointer(vec2(mcbRgb.gb) * 128.0));
} else if (mcbMap == 2) {
// Their own view's maps carry its columns and rows next to the marker.
mcbGrid = vec2(float(mcb_symbol(ivec2(2, 0))), float(mcb_symbol(ivec2(3, 0))));
} else if (mcbMap == 3) {
// A view whose pointer this client places: each map also carries its own column and
// row, and goes to its place in the window by those and its corner (the map quad's
// texture coordinates are exactly 0 and 1), wherever its frame is and wherever the
// camera looks. An overlay sends only the maps its panel covers, so nothing is drawn
// round them.
vec2 mcbViewGrid = vec2(float(mcb_symbol(ivec2(2, 0))), float(mcb_symbol(ivec2(3, 0))));
vec2 mcbTile = vec2(float(mcb_symbol(ivec2(2, 1))), float(mcb_symbol(ivec2(3, 1))));
if (mcbTile == vec2(239.0)) {
// An overlay's signature map (Palette.markSignature): over the window's four
// bottom-left pixels, which text.fsh writes for the post effect to read.
mcbMapInfo.x = 5.0;
gl_Position = mcb_flat(vec2(-1.0) + vec2(UV0.x * 8.0, (1.0 - UV0.y) * 2.0) / ScreenSize);
} else {
if (mcb_flag_axis() == 1) mcbMapInfo.x = 6.0;
vec2 mcbAt = (mcbTile + UV0) / mcbViewGrid;
gl_Position = mcb_flat(vec2(mcbAt.x * 2.0 - 1.0, 1.0 - mcbAt.y * 2.0));
}
} else if (mcbMap == 7) {
// A hover layer (Palette.markLayer): placed by the canvas pixel its third row starts at, 128
// canvas pixels to its side, but only while this client's pointer is over its element, and
// then with its priority plus one in place of the fill flag, for text.fsh's depth. Otherwise
// it goes behind the far plane, below.
int mcbFlags = mcb_symbol(ivec2(5, 1));
vec2 mcbViewGrid = vec2(float(mcb_symbol(ivec2(2, 0))), float(mcb_symbol(ivec2(3, 0))));
if (mcb_layer_on(mcbViewGrid * 128.0, mcbFlags)) {
mcbMapInfo.y = float(mcbFlags >> 2) + 1.0;
vec2 mcbOrigin = vec2(mcb_layer_edge(2, 1), mcb_layer_edge(14, 0) - 2.0);
vec2 mcbAt = (mcbOrigin + UV0 * 128.0) / (mcbViewGrid * 128.0);
gl_Position = mcb_flat(vec2(mcbAt.x * 2.0 - 1.0, 1.0 - mcbAt.y * 2.0));
}
}
// Both fill the window whatever its shape and whatever the player's FOV. The picture is centred
// on the camera's axis and square to it, so how far a vertex is from that axis, in blocks, as a
// fraction of half the picture's size, is where it goes in the window.
if (mcbGrid.x > 0.0 && mcbGrid.y > 0.0) {
vec2 mcbBlocks = gl_Position.xy / vec2(ProjMat[0][0], ProjMat[1][1]);
gl_Position.xy = mcbBlocks / (mcbGrid * 0.5) * gl_Position.w;
}
}
// A hover layer not shown, or not seated: every vertex behind the far plane, so it draws no pixel.
if (mcbMap == 7 && mcbMapInfo.y < 0.5) gl_Position = vec4(0.0, 0.0, 2.0, 1.0);
#ifdef IS_SEE_THROUGH
vertexColor = mcbTint;
#else
sphericalVertexDistance = fog_spherical_distance(Position);
cylindricalVertexDistance = fog_cylindrical_distance(Position);
vertexColor = mcbTint * sample_lightmap(Sampler2, UV2);
#endif
#endif
}
