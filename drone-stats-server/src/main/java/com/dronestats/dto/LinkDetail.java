package com.dronestats.dto;

public class LinkDetail {
    private String from;
    private String to;
    private String resourceType; // какой ресурс переносится

    public LinkDetail(String from, String to, String resourceType) {
        this.from = from;
        this.to = to;
        this.resourceType = resourceType;
    }

    // getters / setters
    public String getFrom() { return from; }
    public void setFrom(String from) { this.from = from; }
    public String getTo() { return to; }
    public void setTo(String to) { this.to = to; }
    public String getResourceType() { return resourceType; }
    public void setResourceType(String resourceType) { this.resourceType = resourceType; }
}