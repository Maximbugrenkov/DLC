package com.dronestats.dto;

public class DronesStats {
    private int total;
    private int logistic;
    private int construction;
    private double avgCharge;

    // getters and setters
    public int getTotal() { return total; }
    public void setTotal(int total) { this.total = total; }
    public int getLogistic() { return logistic; }
    public void setLogistic(int logistic) { this.logistic = logistic; }
    public int getConstruction() { return construction; }
    public void setConstruction(int construction) { this.construction = construction; }
    public double getAvgCharge() { return avgCharge; }
    public void setAvgCharge(double avgCharge) { this.avgCharge = avgCharge; }
}