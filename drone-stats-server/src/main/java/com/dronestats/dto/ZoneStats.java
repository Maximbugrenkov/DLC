package com.dronestats.dto;

import java.util.List;
import java.util.Map;

public class ZoneStats {
    private String id;
    private String name;
    private int priority;
    private int width;
    private int height;
    private List<ChestDetail> chests;
    private List<GhostDetail> ghosts;
    private List<TaskDetail> tasks;
    private List<LinkDetail> links;          // связи с другими зонами/задачами
    private Map<String, Integer> resourcesInTransit; // ресурсы в пути

    // getters / setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public int getPriority() { return priority; }
    public void setPriority(int priority) { this.priority = priority; }
    public int getWidth() { return width; }
    public void setWidth(int width) { this.width = width; }
    public int getHeight() { return height; }
    public void setHeight(int height) { this.height = height; }
    public List<ChestDetail> getChests() { return chests; }
    public void setChests(List<ChestDetail> chests) { this.chests = chests; }
    public List<GhostDetail> getGhosts() { return ghosts; }
    public void setGhosts(List<GhostDetail> ghosts) { this.ghosts = ghosts; }
    public List<TaskDetail> getTasks() { return tasks; }
    public void setTasks(List<TaskDetail> tasks) { this.tasks = tasks; }
    public List<LinkDetail> getLinks() { return links; }
    public void setLinks(List<LinkDetail> links) { this.links = links; }
    public Map<String, Integer> getResourcesInTransit() { return resourcesInTransit; }
    public void setResourcesInTransit(Map<String, Integer> resourcesInTransit) { this.resourcesInTransit = resourcesInTransit; }
}