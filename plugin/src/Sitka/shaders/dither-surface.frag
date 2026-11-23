#version 440
#extension GL_GOOGLE_include_directive : require

#include "dither.glsl"

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 baseColor;
    vec2 surfaceSize;
    vec4 cornerSizes;
    vec4 cornerStyles;
    float intensity;
    float cellSize;
    int triangle;
    bool composedFill;
    float relief;
};

float coverage(float distance) {
    float aa = max(fwidth(distance), 0.0001);
    return clamp(distance / aa + 0.5, 0.0, 1.0);
}

void main() {
    vec2 p = qt_TexCoord0 * surfaceSize;
    float mask = 1.0;
    if (triangle >= 0) {
        vec2 uv = qt_TexCoord0;
        float d = triangle == 0 ? uv.x - uv.y
                : triangle == 1 ? 1.0 - uv.x - uv.y
                : triangle == 2 ? uv.x + uv.y - 1.0
                : uv.y - uv.x;
        mask = coverage(d);
    } else {
        bool right = p.x > surfaceSize.x * 0.5;
        bool bottom = p.y > surfaceSize.y * 0.5;
        int corner = (right ? 1 : 0) + (bottom ? 2 : 0);
        float r = min(cornerSizes[corner], min(surfaceSize.x, surfaceSize.y) * 0.5);
        vec2 q = vec2(right ? surfaceSize.x - p.x : p.x,
                      bottom ? surfaceSize.y - p.y : p.y);
        int style = int(cornerStyles[corner]);
        if (r > 0.0 && q.x < r && q.y < r) {
            if (style == -2) mask = 0.0; // disabled, unfilled corner
            else if (style == 0) mask = coverage(r - length(vec2(r) - q));
            else if (style == 1) mask = coverage(q.x + q.y - r);
            else if (style == 2) {
                // Match CornerPiece's quadratic Bezier, not a circular arc.
                mask = coverage(sqrt(max(0.0, q.x / r)) + sqrt(max(0.0, q.y / r)) - 1.0);
            }
        }
    }
    // QColor uniforms arrive premultiplied. Keep the original alpha, including
    // fully transparent surfaces; only vary the unassociated RGB.
    vec3 rgb = baseColor.a > 0.0 ? baseColor.rgb / baseColor.a : vec3(0.0);
    float threshold = orderedThreshold(gl_FragCoord.xy, cellSize);
    // Balanced tones preserve the theme's mean color. Clamping the amplitude
    // symmetrically avoids a tint on saturated colors or transparent rices.
    vec3 amplitude = min(min(rgb, 1.0 - rgb), vec3(0.12 * intensity));
    if (relief == 0.0) {
        rgb += (threshold < 0.5 ? -1.0 : 1.0) * amplitude;
    } else {
        // Three ceramic tones. Ordered coverage makes the exposed edge catch
        // the light without a moving noise texture or sampling the contents.
        float tone = 1.0 + relief * (0.5 - qt_TexCoord0.y) * 1.7;
        float level = floor(tone) + step(threshold, fract(tone));
        rgb += (level - 1.0) * min(min(rgb, 1.0 - rgb), amplitude * 2.0);
    }
    float alpha = baseColor.a * mask * qt_Opacity;
    // StyledRect's legacy fill has two overlapping center bars. Preserve its
    // source-over alpha (also while fading), rather than changing transparency
    // when toggling the effect. Other surfaces have only one fill.
    float inset = cornerSizes.x;
    if (composedFill && p.x >= inset && p.x < surfaceSize.x - inset
                     && p.y >= inset && p.y < surfaceSize.y - inset)
        alpha = alpha * (2.0 - alpha);
    fragColor = vec4(rgb * alpha, alpha);
}
