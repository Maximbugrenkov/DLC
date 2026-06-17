package com.dronestats.service;

import com.dronestats.dto.StatsSnapshot;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.CopyOnWriteArrayList;

@Service
public class StatsService {
    private StatsSnapshot currentSnapshot;
    private final Queue<StatsSnapshot> history = new LinkedList<>();
    private static final int HISTORY_SIZE = 100;

    public synchronized void updateSnapshot(StatsSnapshot snapshot) {
        this.currentSnapshot = snapshot;
        history.add(snapshot);
        if (history.size() > HISTORY_SIZE) {
            history.poll();
        }
    }

    public synchronized StatsSnapshot getCurrentSnapshot() {
        return currentSnapshot;
    }

    public synchronized List<StatsSnapshot> getHistory() {
        return new ArrayList<>(history);
    }
}