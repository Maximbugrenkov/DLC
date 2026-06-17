package com.dronestats.dto;

public class DroneDetail {
    private long id;
    private String type;       // "logistic", "construction"
    private double charge;
    private String status;     // "idle", "working", "charging", "moving"
    private String currentTaskId;
    private String zoneId;

    // getters / setters
    public long getId() { return id; }
    public void setId(long id) { this.id = id; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public double getCharge() { return charge; }
    public void setCharge(double charge) { this.charge = charge; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getCurrentTaskId() { return currentTaskId; }
    public void setCurrentTaskId(String currentTaskId) { this.currentTaskId = currentTaskId; }
    public String getZoneId() { return zoneId; }
    public void setZoneId(String zoneId) { this.zoneId = zoneId; }
}