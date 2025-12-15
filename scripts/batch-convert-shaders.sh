#!/usr/bin/env bash
set -e

SHADER_DIR="assets/shaders"

# Function to wrap Ghostty/Shadertoy shader
wrap_shader() {
    local input="$1"
    local output="$2"
    local content=$(cat "$input")

    echo "Wrapping $input -> $output"

    cat > "$output" <<END_HEADER
#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float intensity;
    float iTime;
    vec2 iResolution;
};
layout(binding = 1) uniform sampler2D source;

// Define uniforms used by Shadertoy usually mapped
#define iChannel0 source
#define iChannelTime float[](iTime, 0., 0., 0.)
#define iChannelResolution vec3[](vec3(iResolution, 0.), vec3(0.), vec3(0.), vec3(0.))
#define iMouse vec4(0.)
#define iDate vec4(0.)
#define iSampleRate 44100.

END_HEADER

    echo "$content" >> "$output"

    cat >> "$output" <<END_FOOTER

// Adapter main
void main() {
    vec2 fragCoord = qt_TexCoord0 * iResolution;
    mainImage(fragColor, fragCoord);
    fragColor *= qt_Opacity;
}
END_FOOTER
}

# Process specific files requested by user
# starfield.glsl, tft.glsl, bettercrt.glsl, retro-terminal.glsl, bloom.glsl

for name in starfield tft bettercrt bloom retro-terminal; do
    if [ -f "$SHADER_DIR/$name.glsl" ]; then
        wrap_shader "$SHADER_DIR/$name.glsl" "$SHADER_DIR/$name.frag"
    else
        echo "Warning: $name.glsl not found"
    fi
done

