package com.dronestats.model;

public class Drone {
    private long id;
    private String type;        // "logistic" or "construction"
    private double charge;      // 0.0 .. 1.0
    private String status;      // "idle", "working", "charging"
    private double x, y;

    // constructors
    public Drone() {}

    public Drone(long id, String type, double charge, String status, double x, double y) {
        this.id = id;
        this.type = type;
        this.charge = charge;
        this.status = status;
        this.x = x;
        this.y = y;
    }

    // getters and setters
    public long getId() { return id; }
    public void setId(long id) { this.id = id; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public double getCharge() { return charge; }
    public void setCharge(double charge) { this.charge = charge; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public double getX() { return x; }
    public void setX(double x) { this.x = x; }
    public double getY() { return y; }
    public void setY(double y) { this.y = y; }
}