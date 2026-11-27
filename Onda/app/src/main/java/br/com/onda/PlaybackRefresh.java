package br.com.onda;

import android.text.TextUtils;
import android.widget.TextView;

final class PlaybackRefresh {
    private PlaybackRefresh() {}

    /** Schedule the chapter marker around the next media boundary, accounting for speed. */
    static long untilBoundary(long position, long boundary, float speed) {
        return Math.max(50L, (long) Math.ceil((boundary - position) / (double) speed));
    }

    static void text(TextView view, CharSequence value) {
        if (!TextUtils.equals(view.getText(), value)) view.setText(value);
    }
}
