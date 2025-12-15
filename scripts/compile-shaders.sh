#!/usr/bin/env bash
# Compile GLSL shaders to Qt Shader Bundle (.qsb) format
# Requires qt6.qtshadertools (qsb command)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHADER_DIR="${SCRIPT_DIR}/../assets/shaders"

# Check if qsb is available
if ! command -v qsb &> /dev/null; then
    echo "qsb not found. Trying with nix-shell..."
    QSB="nix-shell -p qt6.qtshadertools --run qsb"
else
    QSB="qsb"
fi

echo "Compiling shaders in ${SHADER_DIR}..."

for shader in "${SHADER_DIR}"/*.frag; do
    if [ -f "$shader" ]; then
        output="${shader}.qsb"
        echo "  Compiling $(basename "$shader") -> $(basename "$output")"
        $QSB --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$output" "$shader"
    fi
done

echo "Done!"
