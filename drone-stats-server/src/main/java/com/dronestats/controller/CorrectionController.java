package com.dronestats.controller;

import org.springframework.web.bind.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import java.util.List;
import java.util.Map;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

@RestController
@RequestMapping("/api/corrections")
@CrossOrigin(origins = "*")
public class CorrectionController {

    private final JdbcTemplate jdbcTemplate;

    public CorrectionController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;

        // 1. Таблица корректировки приоритетов зон
        this.jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS corrections (" +
                "id INT AUTO_INCREMENT PRIMARY KEY, " +
                "zone_name VARCHAR(255), " +
                "corrected_priority INT, " +
                "note VARCHAR(255))");

        // 2. Лог волновой истории дронов (Транспортные и Строительные)
        this.jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS drone_history_log (" +
                "id INT AUTO_INCREMENT PRIMARY KEY, " +
                "packet_time VARCHAR(50), " +
                "total_logistic INT, " +
                "active_logistic INT, " +
                "total_construction INT, " +
                "active_construction INT, " +
                "connected_zones VARCHAR(255), " +
                "idle_duration VARCHAR(100), " +
                "operator_note VARCHAR(255))");

        // 3. Таблица логов склада сундуков для диплома
        this.jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS chest_history_log (" +
                "id INT AUTO_INCREMENT PRIMARY KEY, " +
                "packet_time VARCHAR(50), " +
                "iron_plates INT, " +
                "copper_plates INT, " +
                "gears INT, " +
                "warehouse_note VARCHAR(255))");

        // Заполнение начальными данными сундуков, если пусто
        Integer countChest = this.jdbcTemplate.queryForObject("SELECT COUNT(*) FROM chest_history_log", Integer.class);
        if (countChest == null || countChest == 0) {
            this.jdbcTemplate.update("INSERT INTO chest_history_log (packet_time, iron_plates, copper_plates, gears, warehouse_note) VALUES ('15:00:00', 250, 140, 90, 'Стабильное пополнение')");
        }
    }

    @GetMapping
    public List<Map<String, Object>> getCorrections() {
        return jdbcTemplate.queryForList("SELECT * FROM corrections");
    }

    @PostMapping
    public String addCorrection(@RequestBody Map<String, Object> payload) {
        String zoneName = (String) payload.get("zoneName");
        Integer priority = Integer.parseInt(payload.get("priority").toString());
        String note = (String) payload.get("note");
        jdbcTemplate.update("MERGE INTO corrections (zone_name, corrected_priority, note) KEY(zone_name) VALUES (?, ?, ?)", zoneName, priority, note);
        return "{\"status\":\"success\"}";
    }

    @GetMapping("/drone-log")
    public List<Map<String, Object>> getDroneLog() {
        return jdbcTemplate.queryForList("SELECT * FROM drone_history_log ORDER BY id DESC");
    }

    @PostMapping("/drone-log/add")
    public String autoAddLog(@RequestBody Map<String, Object> payload) {
        String time = LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm:ss"));
        jdbcTemplate.update("INSERT INTO drone_history_log (packet_time, total_logistic, active_logistic, total_construction, active_construction, connected_zones, idle_duration, operator_note) VALUES (?, ?, ?, ?, ?, ?, ?, '')",
                time, payload.get("logTotal"), payload.get("logActive"), payload.get("conTotal"), payload.get("conActive"), payload.get("zones"), payload.get("idle"));
        return "{\"status\":\"success\"}";
    }

    @PostMapping("/drone-log/edit")
    public String editLogNote(@RequestBody Map<String, Object> payload) {
        jdbcTemplate.update("UPDATE drone_history_log SET operator_note = ? WHERE id = ?", payload.get("note"), payload.get("id"));
        return "{\"status\":\"success\"}";
    }

    // --- НОВЫЕ МЕТОДЫ ДЛЯ ЛОГА СУНДУКОВ ---
    @GetMapping("/chest-log")
    public List<Map<String, Object>> getChestLog() {
        return jdbcTemplate.queryForList("SELECT * FROM chest_history_log ORDER BY id DESC");
    }

    @PostMapping("/chest-log/edit")
    public String editChestNote(@RequestBody Map<String, Object> payload) {
        jdbcTemplate.update("UPDATE chest_history_log SET warehouse_note = ? WHERE id = ?", payload.get("note"), payload.get("id"));
        return "{\"status\":\"success\"}";
    }
}