#define PI 3.1415926538

#define WALL_L      1024
#define WIBBLE_SIZE 32
#define MAX_WIBBLE  2

#define SHADE_NEUTRAL  0x1000
#define SHADE_MAX      0x1FFF
#define SHADE_CAUSTICS 0x300

#define VERT_NO_WIBBLE         0x0001u
#define VERT_FLAT_SHADED       0x0002u
#define VERT_REFLECTIVE        0x0004u
#define VERT_NO_LIGHTING       0x0008u
#define VERT_BILLBOARD         0x0010u
#define VERT_ABS_SPRITE        0x0020u
#define VERT_NO_ALPHA_DISCARD  0x0040u
#define VERT_USE_DYNAMIC_LIGHT 0x0080u
#define VERT_USE_OBJECT_LIGHT  0x0100u
#define VERT_USE_OWN_LIGHT     0x0200u
#define VERT_MOVE              0x0400u
#define VERT_GLOW              0x0800u
#define VERT_OVERBRIGHT        0x1000u
#define VERT_ADDITIVE          0x4000u

#define LIGHTING_CONTRAST_LOW    0
#define LIGHTING_CONTRAST_MEDIUM 1
#define LIGHTING_CONTRAST_HIGH   2

#define DITHER_MODE_DISABLED          0
#define DITHER_MODE_SOFTWARE_RENDERER 1
#define DITHER_MODE_PS1               2

layout(std140) uniform Globals {
    vec4 uFogColor;
    vec2 uFogDistance; // x = fog start, y = fog end
    vec2 uViewportSize;
    vec2 uSceneSize;
    vec2 uUISize;
    float uTime;
    float uTimeInGame;
    float uBrightnessMultiplier;
    float uUIBrightnessMultiplier;
    float uGamma;
    float uSunsetDuration;
    float uMinShade;
    int uBillboardLockMode;
    int uLightingEnabled; // bool
    int uStaticLightingEnabled; // bool
    int uTrapezoidFilterEnabled; // bool
    int uReflectionsEnabled; // bool
    int uTexturesEnabled; // bool
    int uVertexSnapEnabled; // bool
    int uDitherMode;
    int uTRVersion;
    float uUVScrollTick;
};

layout(std140) uniform Matrices {
    mat4 uMatProj;
    mat4 uMatView;
};

vec2 clampTexAtlas(vec2 uv, vec4 atlasSize)
{
    float epsilon = 0.5 / 256.0;
    return clamp(uv, atlasSize.xy + epsilon, atlasSize.zw - epsilon);
}

#ifdef FRAGMENT

const int PS1_DITHER_MATRIX[16] = int[16](
    -4,  0, -3,  1,
     2, -2,  3, -1,
    -3,  1, -4,  0,
     3, -1,  2, -2);

ivec2 getPS1Pixel(vec2 rasterSize)
{
    ivec2 sceneSize = max(ivec2(uSceneSize), ivec2(1));
    vec2 raster = max(rasterSize, vec2(1.0));
    ivec2 pos = ivec2(floor(gl_FragCoord.xy * uSceneSize / raster));
    pos = clamp(pos, ivec2(0), sceneSize - 1);
    pos.y = sceneSize.y - 1 - pos.y;
    return pos;
}

vec3 ps1Quantize(vec3 color, bool dither, vec2 rasterSize)
{
    float offset = 0.0;
    if (dither) {
        ivec2 pos = getPS1Pixel(rasterSize) & 3;
        offset = float(PS1_DITHER_MATRIX[pos.y * 4 + pos.x]);
    }
    vec3 channel = clamp(color * 255.0 + offset, 0.0, 255.0);
    return floor(channel / 8.0) / 31.0;
}

vec4 ps1QuantizePremultiplied(
    vec4 color, bool dither, vec2 rasterSize)
{
    if (color.a <= 0.0) {
        return color;
    }
    color.rgb = ps1Quantize(
        clamp(color.rgb / color.a, 0.0, 1.0), dither, rasterSize) * color.a;
    return color;
}

#endif
