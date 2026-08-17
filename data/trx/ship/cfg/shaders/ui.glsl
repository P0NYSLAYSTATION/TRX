#include "common.glsl"

#ifdef VERTEX

layout(location = 0) in vec4 inPosition;
layout(location = 1) in vec3 inUVW;
layout(location = 2) in vec4 inTextureSize;
layout(location = 3) in uint inFlags;
layout(location = 4) in vec4 inColor;

out vec3 gNormal;
flat out uint gFlags;
flat out int gTexLayer;
out vec2 gTexUV;
flat out vec4 gAtlasSize;
out vec4 gColor;

void main(void) {
    gl_Position = uMatProj * uMatView * vec4(inPosition.xyz, 1.0);
    gFlags = inFlags;
    gAtlasSize = inTextureSize;
    gTexUV = inUVW.xy;
    gTexLayer = int(inUVW.z);
    gColor = inColor;
}

#elif defined(FRAGMENT)

uniform sampler2DArray uTexAtlas;
uniform usampler2DArray uSoftwareTexAtlas;
uniform sampler2D uSoftwarePalette;
uniform usampler3D uSoftwarePaletteLUT;

flat in uint gFlags;
flat in int gTexLayer;
in vec2 gTexUV;
flat in vec4 gAtlasSize;
in vec4 gColor;
out vec4 outColor;

vec3 softwarePaletteColor(vec3 color)
{
    const float lutMax = 63.0;
    ivec3 pos = ivec3(round(clamp(color, 0.0, 1.0) * lutMax));
    int paletteIndex = int(texelFetch(uSoftwarePaletteLUT, pos, 0).r);
    return texelFetch(uSoftwarePalette, ivec2(paletteIndex, 0), 0).rgb;
}

vec4 softwareTextureColor(vec3 texCoords)
{
    ivec3 atlasSize = textureSize(uSoftwareTexAtlas, 0);
    ivec2 texel = ivec2(floor(texCoords.xy * vec2(atlasSize.xy)));
    texel = clamp(texel, ivec2(0), atlasSize.xy - ivec2(1));
    int colorIndex =
        int(texelFetch(uSoftwareTexAtlas, ivec3(texel, gTexLayer), 0).r);
    float alpha = colorIndex == 0 ? 0.0 : 1.0;
    vec3 color =
        texelFetch(uSoftwarePalette, ivec2(colorIndex, 0), 0).rgb;
    return vec4(color, alpha);
}

void main(void) {
    vec4 texColor = gColor;

    if ((gFlags & VERT_FLAT_SHADED) == 0u && gTexLayer >= 0) {
        vec3 texCoords = vec3(gTexUV.x, gTexUV.y, gTexLayer);
        texCoords.xy = clampTexAtlas(texCoords.xy, gAtlasSize);
        if (uSoftwareRendererEnabled != 0 && uTRVersion <= 3) {
            texColor *= softwareTextureColor(texCoords);
        } else {
            texColor *= texture(uTexAtlas, texCoords);
        }
        if (texColor.a <= 0.0) {
            discard;
        }
    } else {
        texColor.rgb *= texColor.a;
    }

    texColor.rgb *= uUIBrightnessMultiplier;
    if (uSoftwareRendererEnabled != 0 && uTRVersion <= 3
        && texColor.a > 0.0) {
        texColor.rgb =
            softwarePaletteColor(texColor.rgb / texColor.a) * texColor.a;
    }
    outColor = texColor;
}

#endif
