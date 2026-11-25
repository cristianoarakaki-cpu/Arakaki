package br.com.onda;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.junit.Test;
import static org.junit.Assert.*;

public class MixMp3Test {
    private List<Short> render(int overlap) throws Exception {
        List<Short> left = new ArrayList<>();
        MixMp3 mix = new MixMp3((samples, frames) -> {
            for (int i = 0; i < frames * 2; i += 2) {
                assertEquals(samples[i], samples[i + 1]);
                left.add(samples[i]);
            }
        });
        short[] first = new short[8], second = new short[24];
        Arrays.fill(first, (short) 10000);
        Arrays.fill(second, (short) -10000);
        mix.begin(overlap);
        mix.pcm(first, first.length, 24000, 1);
        mix.end(24000);
        mix.begin(0);
        mix.pcm(second, second.length, 48000, 2);
        mix.end(48000);
        mix.finish();
        return left;
    }

    @Test public void straightJoinKeepsBothDurations() throws Exception {
        List<Short> result = render(0);
        assertEquals(20, result.size());
        assertEquals(10000, result.get(7).intValue());
        assertEquals(-10000, result.get(8).intValue());
    }

    @Test public void overlapMixesTheBoundaryAndShortensOutput() throws Exception {
        List<Short> result = render(3);
        assertEquals(17, result.size());
        assertEquals(10000, result.get(4).intValue());
        assertEquals(5000, result.get(5).intValue());
        assertEquals(0, result.get(6).intValue());
        assertEquals(-5000, result.get(7).intValue());
        assertEquals(-10000, result.get(8).intValue());
    }
}
