package com.dronestats.model;

public class Combinator {
    private long id;
    private long linkedZoneId;
    private String condition;    // e.g. "iron-plate < 1000"
    private int truePriority;
    private boolean active;

    public Combinator() {}

    // getters and setters
    public long getId() { return id; }
    public void setId(long id) { this.id = id; }
    public long getLinkedZoneId() { return linkedZoneId; }
    public void setLinkedZoneId(long linkedZoneId) { this.linkedZoneId = linkedZoneId; }
    public String getCondition() { return condition; }
    public void setCondition(String condition) { this.condition = condition; }
    public int getTruePriority() { return truePriority; }
    public void setTruePriority(int truePriority) { this.truePriority = truePriority; }
    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
}