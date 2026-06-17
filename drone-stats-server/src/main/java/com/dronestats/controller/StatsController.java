package com.dronestats.controller;

import com.dronestats.dto.StatsSnapshot;
import com.dronestats.dto.ZoneStats;
import com.dronestats.dto.DroneDetail;
import com.dronestats.service.StatsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class StatsController {

    @Autowired
    private StatsService statsService;

    @PostMapping("/stats")
    public ResponseEntity<String> receiveStats(@RequestBody StatsSnapshot snapshot) {
        statsService.updateSnapshot(snapshot);
        return ResponseEntity.ok("OK");
    }

    @GetMapping("/stats/latest")
    public ResponseEntity<StatsSnapshot> getLatest() {
        StatsSnapshot latest = statsService.getCurrentSnapshot();
        if (latest == null) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(latest);
    }

    // Новый метод для получения списка зон
    @GetMapping("/zones")
    public ResponseEntity<List<ZoneStats>> getZones() {
        StatsSnapshot latest = statsService.getCurrentSnapshot();
        if (latest == null || latest.getZones() == null) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(latest.getZones());
    }

    // Новый метод для получения списка дронов
    @GetMapping("/drones")
    public ResponseEntity<List<DroneDetail>> getDrones() {
        StatsSnapshot latest = statsService.getCurrentSnapshot();
        if (latest == null || latest.getDroneDetails() == null) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(latest.getDroneDetails());
    }
}