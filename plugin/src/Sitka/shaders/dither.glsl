// A fixed ordered pattern: no clock, random state, or repaint loop.
const int bayer4[16] = int[16](
     0,  8,  2, 10,
    12,  4, 14,  6,
     3, 11,  1,  9,
    15,  7, 13,  5
);

float orderedThreshold(vec2 position, float cellSize) {
    ivec2 cell = ivec2(mod(floor(position / max(1.0, cellSize)), 4.0));
    return (float(bayer4[cell.y * 4 + cell.x]) + 0.5) / 16.0;
}
