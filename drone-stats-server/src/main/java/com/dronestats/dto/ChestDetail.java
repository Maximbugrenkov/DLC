package com.dronestats.dto;

import java.util.Map;

public class ChestDetail {
    private String name;
    private String type;          // "storage", "requester", "buffer", "provider"
    private Map<String, Integer> contents;
    private Map<String, Integer> requests; // для requester-сундуков
    private String linkedZone;    // зона, к которой относится сундук
    private String linkedTask;     // задача, с которой связан (опционально)

    // getters / setters
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public Map<String, Integer> getContents() { return contents; }
    public void setContents(Map<String, Integer> contents) { this.contents = contents; }
    public Map<String, Integer> getRequests() { return requests; }
    public void setRequests(Map<String, Integer> requests) { this.requests = requests; }
    public String getLinkedZone() { return linkedZone; }
    public void setLinkedZone(String linkedZone) { this.linkedZone = linkedZone; }
    public String getLinkedTask() { return linkedTask; }
    public void setLinkedTask(String linkedTask) { this.linkedTask = linkedTask; }
}