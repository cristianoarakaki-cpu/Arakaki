package br.com.onda;

import java.io.IOException;

/** One continuous stereo stream, with bounded buffering at each transition. */
final class MixMp3 {
    static final int RATE = 48000;
    interface Sink { void write(short[] stereo, int frames) throws IOException; }

    private final Sink sink;
    private final short[] block = new short[8192];
    private short[] previous = new short[0], tail = new short[0];
    private int mixed, cursor, filled, used;
    private long phase;
    private boolean hasSample;
    private short left, right;

    MixMp3(Sink sink) { this.sink = sink; }

    static int overlap(long firstMs, long secondMs) {
        return (int) Math.min(3000, Math.min(firstMs, secondMs) / 4) * (RATE / 1000);
    }

    void begin(int nextOverlap) {
        tail = new short[nextOverlap * 2];
        mixed = cursor = filled = 0;
        phase = 0;
        hasSample = false;
    }

    void pcm(short[] data, int count, int rate, int channels) throws IOException {
        for (int offset = 0; offset < count; offset += channels) {
            short nextLeft = data[offset], nextRight = data[offset + channels - 1];
            if (hasSample) {
                while (phase < RATE) {
                    frame(interpolate(left, nextLeft, phase), interpolate(right, nextRight, phase));
                    phase += rate;
                }
                phase -= RATE;
            }
            left = nextLeft;
            right = nextRight;
            hasSample = true;
        }
    }

    void end(int rate) throws IOException {
        if (hasSample) while (phase < RATE) {
            frame(left, right);
            phase += rate;
        }
        if (mixed < previous.length) throw new IOException("Trecho curto demais para a transição.");
        if (filled < tail.length) throw new IOException("O áudio terminou antes da transição.");
        previous = new short[tail.length];
        System.arraycopy(tail, cursor, previous, 0, tail.length - cursor);
        System.arraycopy(tail, 0, previous, tail.length - cursor, cursor);
    }

    void finish() throws IOException {
        if (used > 0) sink.write(block, used / 2);
    }

    private short interpolate(short from, short to, long distance) {
        return (short) (from + (to - from) * distance / RATE);
    }

    private void frame(short left, short right) throws IOException {
        if (mixed < previous.length) {
            long fraction = (mixed / 2L + 1) * RATE / (previous.length / 2L + 1);
            emit(interpolate(previous[mixed], left, fraction), interpolate(previous[mixed + 1], right, fraction));
            mixed += 2;
        } else if (tail.length == 0) emit(left, right);
        else {
            if (filled == tail.length) emit(tail[cursor], tail[cursor + 1]);
            else filled += 2;
            tail[cursor] = left;
            tail[cursor + 1] = right;
            cursor = (cursor + 2) % tail.length;
        }
    }

    private void emit(short left, short right) throws IOException {
        block[used++] = left;
        block[used++] = right;
        if (used == block.length) {
            sink.write(block, used / 2);
            used = 0;
        }
    }
}
