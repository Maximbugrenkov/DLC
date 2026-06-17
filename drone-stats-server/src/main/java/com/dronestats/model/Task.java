package com.dronestats.model;

public class Task {
    private long id;
    private String type;          // "construction", "logistic", "repair"
    private String item;          // item name (e.g. "iron-plate", "wall")
    private long zoneId;
    private double x, y;
    private long waitTime;        // seconds task has been pending
    private int priorityOverride; // 0 = use zone priority

    public Task() {}

    // getters and setters (omitted for brevity, generate all)
    public long getId() { return id; }
    public void setId(long id) { this.id = id; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public String getItem() { return item; }
    public void setItem(String item) { this.item = item; }
    public long getZoneId() { return zoneId; }
    public void setZoneId(long zoneId) { this.zoneId = zoneId; }
    public double getX() { return x; }
    public void setX(double x) { this.x = x; }
    public double getY() { return y; }
    public void setY(double y) { this.y = y; }
    public long getWaitTime() { return waitTime; }
    public void setWaitTime(long waitTime) { this.waitTime = waitTime; }
    public int getPriorityOverride() { return priorityOverride; }
    public void setPriorityOverride(int priorityOverride) { this.priorityOverride = priorityOverride; }
}