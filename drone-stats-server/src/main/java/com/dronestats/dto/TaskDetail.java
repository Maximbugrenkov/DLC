package com.dronestats.dto;

import java.util.List;

public class TaskDetail {
    private String id;
    private String name;
    private String type;       // "logistic", "construction"
    private String zoneId;
    private boolean enabled;
    private int droneCount;
    private List<String> links; // ID задач/сундуков, с которыми есть связь

    // getters / setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public String getZoneId() { return zoneId; }
    public void setZoneId(String zoneId) { this.zoneId = zoneId; }
    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }
    public int getDroneCount() { return droneCount; }
    public void setDroneCount(int droneCount) { this.droneCount = droneCount; }
    public List<String> getLinks() { return links; }
    public void setLinks(List<String> links) { this.links = links; }
}