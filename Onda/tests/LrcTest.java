package br.com.onda;

public final class LrcTest {
    private static void check(boolean value) { if (!value) throw new AssertionError(); }
    public static void main(String[] args) {
        var lines = Lrc.parse("[ar:Example]\n[00:02.50]Second\n[00:01.2][00:03.250]Repeat\n[00:04]Hello <00:04.500>world\n[00:05.000]\nmalformed");
        check(lines.size() == 5);
        check(lines.get(0).ms == 1200 && lines.get(0).text.equals("Repeat"));
        check(lines.get(1).ms == 2500);
        check(lines.get(2).ms == 3250);
        check(lines.get(3).text.equals("Hello world"));
        check(lines.get(4).text.isEmpty());
        check(Lrc.active(lines, 0) == -1);
        check(Lrc.active(lines, 1200) == 0);
        check(Lrc.active(lines, 3249) == 1);
        check(Lrc.active(lines, 3250) == 2);
        check(Lrc.active(lines, 9000) == 4);
        check(Lrc.active(lines, 1400) == 0); // backwards seek
        check(Lrc.parse("[00:01.00]A\n[offset:-1500]").get(0).ms == 0);
        check(Lrc.parse("[offset:+100]\n[00:01:12]A").get(0).ms == 1220);
        check(Lrc.parse(null).isEmpty());
        check(Lrc.parse("plain lyrics\n[99:99.9]bad").isEmpty());
        check(Lrc.active(Lrc.parse("[00:01]A\n[00:01]B"), 1000) == 1);
        System.out.println("LRC: timestamp precision, repeated stamps, ordering, offsets, blank verses, malformed input and seek passed.");
    }
}
