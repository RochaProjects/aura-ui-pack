#version 330

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
#moj_import <minecraft:fog.glsl>
#endif

#moj_import <minecraft:dynamictransforms.glsl>

uniform sampler2D Sampler0;

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
in float sphericalVertexDistance;
in float cylindricalVertexDistance;
#endif

in vec4 vertexColor;
in vec2 texCoord0;
in vec2 mcbPos;
flat in vec2 mcbSize;
flat in float mcbSeated;
flat in float mcbPointer;
flat in float mcbReversed;
flat in vec2 mcbMapInfo;
flat in vec4 mcbViewTint;

out vec4 fragColor;

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

// A seated player's own view and pointer win over any block between them and the camera,
// so no blocks need clearing. Scaling depth towards "near" puts both in front of anything
// more than a few centimetres from the eye, and the pointer (more) in front of the picture.
float mcb_in_front(float k) {
return mcbReversed > 0.5 ? min(gl_FragCoord.z * k, 1.0) : gl_FragCoord.z / k;
}

// The screen is almost never drawn at one map pixel per window pixel. Instead of the
// nearest pixel (uneven, shimmering text), average the map pixels under this window
// pixel's footprint, weighted by overlap. Averaging in YCbCr is exact: the conversion to
// RGB is linear. Pixels come in 2x2 blocks that share one chroma value; a footprint at most
// two pixels across touches at most 2x2 of them. The first [info] + 1 blocks of the top row
// hold data, not picture (the marker, a view's size and place, its tint, a blurred view's
// panel): they show the block right of them, or each the block below it, as [fillRight] says
// (mcb_fill_right). A transparent block (map colours 0-3, alpha 0) adds no colour: alpha is how
// much of the footprint the opaque blocks cover, so a picture's edge against the world is smooth.
vec4 mcb_sample(vec2 t, vec2 fw, int info, bool fillRight) {
vec2 halfFw = clamp(fw, vec2(0.02), vec2(2.0)) * 0.5;
vec2 lo = clamp(t - halfFw, vec2(0.0), vec2(128.0));
vec2 hi = clamp(t + halfFw, vec2(0.0), vec2(128.0));
ivec2 b0 = clamp(ivec2(floor(lo * 0.5)), ivec2(0), ivec2(63));
ivec2 b1 = clamp(ivec2(floor((hi - 0.0001) * 0.5)), ivec2(0), ivec2(63));
vec3 acc = vec3(0.0);
float total = 0.0;
float covered = 0.0;
for (int i = 0; i < 4; i++) {
ivec2 b = b0 + ivec2(i & 1, i >> 1);
if (b.x > b1.x || b.y > b1.y) continue;
ivec2 base = b * 2;
vec2 p0 = vec2(base);
vec2 ov0 = max(min(hi, p0 + 1.0) - max(lo, p0), 0.0);
vec2 ov1 = max(min(hi, p0 + 2.0) - max(lo, p0 + 1.0), 0.0);
vec4 w = vec4(ov0.x * ov0.y, ov1.x * ov0.y, ov0.x * ov1.y, ov1.x * ov1.y);
float ws = w.x + w.y + w.z + w.w;
total += ws;
ivec2 src = b.y > 0 || b.x > info ? base : fillRight ? ivec2(2 * info + 2, 0) : ivec2(base.x, 2);
vec4 c00 = texelFetch(Sampler0, src, 0);
if (c00.a < 0.5) continue;
ivec4 s = ivec4(mcb_symbol_of(c00.rgb), mcb_symbol(src + ivec2(1, 0)),
mcb_symbol(src + ivec2(0, 1)), mcb_symbol(src + ivec2(1, 1)));
vec4 luma = vec4(s >> 3) / 29.0;
ivec4 digit = s & 7;
vec2 chroma = vec2(float(digit.x * 8 + digit.y - 32), float(digit.z * 8 + digit.w - 32)) / 63.0;
acc += vec3(dot(w, luma), chroma * ws);
covered += ws;
}
if (covered <= 0.0) return vec4(0.0);
vec3 ycc = acc / covered;
return vec4(clamp(vec3(ycc.x + 1.402 * ycc.z, ycc.x - 0.344136 * ycc.y - 0.714136 * ycc.z, ycc.x + 1.772 * ycc.y), 0.0, 1.0),
covered / max(total, 1e-6));
}

// An overlay's signature, for the post effect that keeps the world round its panel (Shaders.overlayChain),
// written as the window's four bottom-left pixels: a check, the view's tint, its alpha and the flags (the
// signature map's own, Palette.markSignature, and whether depth is reversed), and a second check.
vec3 mcb_signature(int i) {
ivec4 t = ivec4(round(clamp(mcbViewTint, 0.0, 1.0) * 255.0));
int flags = mcb_symbol(ivec2(6, 0)) | (mcbReversed > 0.5 ? 4 : 0);
ivec3 c = i == 0 ? ivec3(90,195,150) : i == 1 ? t.rgb : i == 2 ? ivec3(t.a, flags, 0) : ivec3(0, 0, 105);
return vec3(c) / 255.0;
}
// ---- end decoder ----

bool mcb_in(vec2 p, vec2 a, vec2 b) { return p.x >= a.x && p.x <= b.x && p.y >= a.y && p.y <= b.y; }

ivec3 mcb_code(ivec2 p) {
uint h = uint(p.x) * 0x9E3779B1u ^ uint(p.y) * 0x85EBCA77u;
h ^= h >> 15;
h *= 0x2C1B3C6Du;
h ^= h >> 12;
int e = int(h >> 26);
return ivec3(e & 3, (e >> 2) & 3, (e >> 4) & 3);
}

vec3 mcb_pointer_code(vec3 rgb) {
ivec3 c = ivec3(round(clamp(rgb, 0.0, 1.0) * 255.0));
return vec3((c & ~3) | mcb_code(ivec2(gl_FragCoord.xy))) / 255.0;
}

void main() {
// Derivatives before any branch or discard.
vec2 mcbFootprint = fwidth(texCoord0 * 128.0);
float mcbDepth = gl_FragCoord.z;
#ifndef IS_GUI
// The client-placed pointer is as near as depth goes, in front of the picture and of everything.
if (mcbSeated > 0.5 && mcbPointer > 1.5) mcbDepth = mcbReversed > 0.5 ? 1.0 : 0.0;
else if (mcbSeated > 0.5 && mcbPointer > 0.5) mcbDepth = mcb_in_front(128.0);
// A shader that writes gl_FragDepth anywhere must write it on every path.
gl_FragDepth = mcbDepth;
#endif
#ifdef IS_GUI
// The XP level over the hotbar, hidden while seated like the rest of the HUD.
if (mcbSeated > 0.5) {
float cx = floor(mcbSize.x / 2.0);
if (mcb_in(mcbPos, vec2(cx - 40.0, mcbSize.y - 40.0), vec2(cx + 40.0, mcbSize.y - 22.0))) discard;
}
#endif
#ifndef IS_GRAYSCALE
int mcbMap = int(mcbMapInfo.x + 0.5);
if (mcbMap > 0) {
vec4 mcbColor;
if (mcbMap == 5) {
if (gl_FragCoord.y >= 1.0 || gl_FragCoord.x >= 4.0) discard;
mcbColor = vec4(mcb_signature(int(gl_FragCoord.x)), 1.0);
} else {
// A hover layer (7) shows only while text.vsh places it, and never its top two rows, its
// data: there, and wherever it is transparent, the view under it shows.
if (mcbMap == 7 && (mcbMapInfo.y < 0.5 || texCoord0.y < 2.0 / 128.0)) discard;
// A screen emits its own light: no lightmap, tint or fog, so colours are exact day and night.
vec4 mcbPicture = mcb_sample(texCoord0 * 128.0, mcbFootprint, mcb_info(mcbMap), mcbMap != 7 && mcbMapInfo.y > 0.5);
// An overlay's panel (6) is there or not, never blended with the world behind it: round it the
// post effect shows the world as it was, tinted there. A hover layer likewise over its view.
if (mcbMap >= 6) mcbPicture = mcbPicture.a < 0.5 ? vec4(0.0) : vec4(mcbPicture.rgb, 1.0);
// Where the picture is transparent the world behind shows, on someone's own view under its
// tint: the picture over the tint over the world, as one colour blended over the world.
vec4 mcbTint = mcbMap >= 2 && mcbMap < 6 && mcbPicture.a < 1.0 ? mcbViewTint : vec4(0.0);
float mcbAlpha = 1.0 - (1.0 - mcbPicture.a) * (1.0 - mcbTint.a);
if (mcbAlpha < 0.002) discard;
mcbColor = vec4((mcbPicture.rgb * mcbPicture.a + mcbTint.rgb * (mcbTint.a * (1.0 - mcbPicture.a))) / max(mcbAlpha, 0.002), mcbAlpha);
}
#ifndef IS_GUI
if (mcbMap >= 2 && mcbSeated > 0.5) {
// A view the client places (3, 6) is just behind its pointer, in front of all else: its
// frames are at the camera, so its own depth means nothing. A signature (5) is nearest. A
// hover layer (7) is a step or more in front of its view, the higher its priority (mcbMapInfo.y,
// which is that plus one) the nearer, and still behind the pointer, whichever is drawn first.
float mcbStep = mcbMap == 7 ? mcbMapInfo.y * 1.2e-7 : 0.0;
mcbDepth = mcbMap == 5 ? (mcbReversed > 0.5 ? 1.0 : 0.0)
: mcbMap == 3 || mcbMap >= 6 ? (mcbReversed > 0.5 ? 0.99999 + mcbStep : 0.00001 - mcbStep) : mcb_in_front(64.0);
gl_FragDepth = mcbDepth;
}
#endif
fragColor = mcbColor;
return;
}
#endif

#ifdef IS_GRAYSCALE
vec4 texColor = texture(Sampler0, texCoord0).rrrr;
#else
vec4 texColor = texture(Sampler0, texCoord0);
#endif
#ifdef IS_SEE_THROUGH
vec4 color = texColor * vertexColor;
#else
vec4 color = texColor * vertexColor * ColorModulator;
#endif
if (color.a < 0.1) {
discard;
}
#ifdef IS_SEE_THROUGH
fragColor = color * ColorModulator;
#elif defined(IS_GUI)
fragColor = color;
#else
fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
#endif
#ifndef IS_GUI
// The pointer carries a code the menu blur finds it by, to take it out (menuBlurChain).
if (mcbPointer > 0.5 && fragColor.a > 0.99) fragColor.rgb = mcb_pointer_code(fragColor.rgb);
#endif
}
