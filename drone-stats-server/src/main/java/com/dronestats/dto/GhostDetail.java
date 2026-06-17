package com.dronestats.dto;

public class GhostDetail {
    private String name;
    private int count;
    private int built;      // сколько уже построено
    private String entityType; // "belt", "inserter", "assembler"

    public GhostDetail(String name, int count, String entityType) {
        this.name = name;
        this.count = count;
        this.built = 0;
        this.entityType = entityType;
    }

    // getters / setters
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public int getCount() { return count; }
    public void setCount(int count) { this.count = count; }
    public int getBuilt() { return built; }
    public void setBuilt(int built) { this.built = built; }
    public String getEntityType() { return entityType; }
    public void setEntityType(String entityType) { this.entityType = entityType; }
}