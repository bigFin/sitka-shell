.pragma library

// Linux includes guest time in user/nice already: sum only through steal.
// Fold iowait into idle for the shared percentage calculator.
function parse(text) {
    const line = text.match(/^cpu\s+(.+)$/m);
    if (!line)
        return null;
    const fields = line[1].trim().split(/\s+/);
    if (fields.length < 4 || fields.some(value => !/^\d+$/.test(value)))
        return null;
    const stats = fields.slice(0, 8).map(Number);
    if (stats.some(value => !Number.isSafeInteger(value)))
        return null;
    stats[3] += stats[4] || 0;
    if (stats.length > 4)
        stats[4] = 0;
    return stats;
}

function sample(text, previous, now, calculate) {
    const stats = parse(text);
    if (!stats)
        return { previous: null, usage: null };
    const next = { stats: stats, time: now };
    // Rebaseline on activation, suspend gaps, clock jumps and counter resets.
    if (!previous || now <= previous.time || now - previous.time > 6000 || stats.some((value, i) => value < previous.stats[i]))
        return { previous: next, usage: null };
    const total = stats.reduce((a, b) => a + b, 0);
    const lastTotal = previous.stats.reduce((a, b) => a + b, 0);
    if (total <= lastTotal)
        return { previous: next, usage: null };
    return { previous: next, usage: calculate(stats, previous.stats) / 100 };
}
