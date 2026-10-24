package br.com.onda;
/** Called only on a natural end; seeking forward does not create listening time. */
final class ListeningMilestones {
    static boolean reachedEnd(long heardMs,long durationMs){return durationMs>=5000&&heardMs>=durationMs*.8;}
}
