package com.dronestats.model;

import java.util.Map;

public class Zone {
    private long id;
    private String name;
    private int basePriority;
    private int currentPriority;
    private int pendingTasks;
    private Map<String, Integer> tasksByType; // "construction", "logistic" -> count

    public Zone() {}

    // getters and setters
    public long getId() { return id; }
    public void setId(long id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public int getBasePriority() { return basePriority; }
    public void setBasePriority(int basePriority) { this.basePriority = basePriority; }
    public int getCurrentPriority() { return currentPriority; }
    public void setCurrentPriority(int currentPriority) { this.currentPriority = currentPriority; }
    public int getPendingTasks() { return pendingTasks; }
    public void setPendingTasks(int pendingTasks) { this.pendingTasks = pendingTasks; }
    public Map<String, Integer> getTasksByType() { return tasksByType; }
    public void setTasksByType(Map<String, Integer> tasksByType) { this.tasksByType = tasksByType; }
}