package com.dronestats.model;

import java.util.Map;

public class Chest {
    private long id;
    private String type;   // "provider", "requester", "storage", "buffer"
    private Map<String, Integer> contents;   // item -> count
    private Map<String, Integer> requests;   // for requester chests

    public Chest() {}

    // getters and setters
    public long getId() { return id; }
    public void setId(long id) { this.id = id; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public Map<String, Integer> getContents() { return contents; }
    public void setContents(Map<String, Integer> contents) { this.contents = contents; }
    public Map<String, Integer> getRequests() { return requests; }
    public void setRequests(Map<String, Integer> requests) { this.requests = requests; }
}