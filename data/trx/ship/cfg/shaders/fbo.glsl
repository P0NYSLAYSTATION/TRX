#ifdef VERTEX

layout(location = 0) in vec2 inPosition;

out vec2 vertTexCoords;

void main(void) {
    vertTexCoords = inPosition;
    gl_Position = vec4(vertTexCoords * vec2(2.0, 2.0) + vec2(-1.0, -1.0), 0.0, 1.0);
}

#elif defined(FRAGMENT)

uniform sampler2D uTex0;
uniform int uSupersample;

in vec2 vertTexCoords;
out vec4 outColor;

// Average the block of source texels the output pixel covers. The block is
// aligned to the output grid rather than centered on the sample point, so the
// result is the exact box average the supersampled image was rendered for.
vec4 resolve(vec2 uv)
{
    ivec2 base = ivec2(uv * vec2(textureSize(uTex0, 0)));
    base -= base % uSupersample;
    vec4 sum = vec4(0.0);
    for (int y = 0; y < uSupersample; y++) {
        for (int x = 0; x < uSupersample; x++) {
            sum += texelFetch(uTex0, base + ivec2(x, y), 0);
        }
    }
    return sum / float(uSupersample * uSupersample);
}

void main(void) {
    outColor = uSupersample > 1 ? resolve(vertTexCoords)
                                : texture(uTex0, vertTexCoords);
}

#endif
