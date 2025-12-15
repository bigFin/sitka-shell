#!/usr/bin/env bash
# Automatically port and compile GLSL shaders to Qt QSB format
# Usage: auto-port-shader.sh <input_shader_path>

LOGFILE="/tmp/sitka-shader-debug.log"
# Redirect stderr to logfile
exec 2>>"$LOGFILE"
# Enable debug tracing
set -x

echo "--- Run at $(date) ---" >> "$LOGFILE"
echo "Args: $@" >> "$LOGFILE"
echo "PATH: $PATH" >> "$LOGFILE"

WRAPPER_VERSION="v2"
INPUT_FILE="$1"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <input_shader_path>" >> "$LOGFILE"
    echo "Usage: $0 <input_shader_path>"
    exit 1
fi

# Expand home directory if needed
if [[ "$INPUT_FILE" == "~"* ]]; then
    INPUT_FILE="${HOME}${INPUT_FILE:1}"
fi

echo "Resolved input file: $INPUT_FILE" >> "$LOGFILE"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found: $INPUT_FILE" >> "$LOGFILE"
    echo "Error: Input file not found: $INPUT_FILE"
    exit 1
fi

# Setup cache directory
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/sitka/shaders"
mkdir -p "$CACHE_DIR"

FILENAME=$(basename "$INPUT_FILE")
BASENAME="${FILENAME%.*}"
OUTPUT_QSB="${CACHE_DIR}/${BASENAME}.${WRAPPER_VERSION}.frag.qsb"
WRAPPED_SRC="${CACHE_DIR}/${BASENAME}.${WRAPPER_VERSION}.frag"

echo "Output QSB: $OUTPUT_QSB" >> "$LOGFILE"

# Check if we need to recompile (source newer than qsb)
if [ -f "$OUTPUT_QSB" ] && [ "$INPUT_FILE" -ot "$OUTPUT_QSB" ]; then
    echo "Cache hit: $OUTPUT_QSB" >> "$LOGFILE"
    echo "$OUTPUT_QSB"
    exit 0
fi

# Read input content
CONTENT=$(cat "$INPUT_FILE")

# Check if it's a raw Ghostty/Shadertoy shader (has mainImage)
if echo "$CONTENT" | grep -q "void mainImage"; then
    echo "Wrapping Shadertoy shader" >> "$LOGFILE"
    cat > "$WRAPPED_SRC" <<EOF
#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float intensity;
    float iTime;
    vec2 iResolution;
    vec4 backgroundColor;
};
layout(binding = 1) uniform sampler2D source;

// Define uniforms used by Shadertoy usually mapped
#define iChannel0 source
#define iChannelTime float[](iTime, 0., 0., 0.)
#define iChannelResolution vec3[](vec3(iResolution, 0.), vec3(0.), vec3(0.), vec3(0.))
#define iMouse vec4(0.)
#define iDate vec4(0.)
#define iSampleRate 44100.

// Insert user code
$CONTENT

// Adapter main
void main() {
    vec2 fragCoord = qt_TexCoord0 * iResolution;

    // Run user shader (Shadertoy mainImage)
    mainImage(fragColor, fragCoord);

    // CRITICAL: Restore original alpha from source
    fragColor.a *= texture(source, qt_TexCoord0).a;

    fragColor *= qt_Opacity;
}
EOF
elif echo "$CONTENT" | grep -q "version 440"; then
    echo "Using existing Qt shader" >> "$LOGFILE"
    cp "$INPUT_FILE" "$WRAPPED_SRC"
else
    echo "Wrapping generic GLSL" >> "$LOGFILE"
    # Raw GLSL but no mainImage? Assume it's a fragment shader body or needs wrapping.
    if ! echo "$CONTENT" | grep -q "uniform buf"; then
    cat > "$WRAPPED_SRC" <<EOF
#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float intensity;
    float iTime;
    vec2 iResolution;
    vec4 backgroundColor;
};
layout(binding = 1) uniform sampler2D source;

$CONTENT
EOF
    else
        cp "$INPUT_FILE" "$WRAPPED_SRC"
    fi
fi

# Compile using nix shell to ensure qsb is available
echo "Compiling..." >> "$LOGFILE"
if command -v qsb >/dev/null 2>&1; then
    echo "Running qsb..." >> "$LOGFILE"
    qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$OUTPUT_QSB" "$WRAPPED_SRC" >> "$LOGFILE" 2>&1
elif command -v nix >/dev/null 2>&1; then
    echo "Running nix shell qsb..." >> "$LOGFILE"
    nix shell nixpkgs#qt6.qtshadertools -c qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$OUTPUT_QSB" "$WRAPPED_SRC" >> "$LOGFILE" 2>&1
else
    echo "Error: Neither qsb nor nix found for shader compilation" >> "$LOGFILE"
    echo "Error: Neither qsb nor nix found for shader compilation"
    exit 1
fi

echo "Compilation success" >> "$LOGFILE"
echo "$OUTPUT_QSB"



