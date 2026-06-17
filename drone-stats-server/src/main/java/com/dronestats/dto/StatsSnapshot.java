package com.dronestats.dto;

import java.util.List;
import java.util.Map;

public class StatsSnapshot {
    private long timestamp;
    private DronesStats drones;
    private List<ZoneStats> zones;
    private List<DroneDetail> droneDetails;   // детали по каждому дрону
    private Map<String, Integer> tasksByZone;
    private Map<String, Integer> chestContents;
    private int combinatorsActive;
    private double efficiency;

    // getters / setters (все поля)
    public long getTimestamp() { return timestamp; }
    public void setTimestamp(long timestamp) { this.timestamp = timestamp; }
    public DronesStats getDrones() { return drones; }
    public void setDrones(DronesStats drones) { this.drones = drones; }
    public List<ZoneStats> getZones() { return zones; }
    public void setZones(List<ZoneStats> zones) { this.zones = zones; }
    public List<DroneDetail> getDroneDetails() { return droneDetails; }
    public void setDroneDetails(List<DroneDetail> droneDetails) { this.droneDetails = droneDetails; }
    public Map<String, Integer> getTasksByZone() { return tasksByZone; }
    public void setTasksByZone(Map<String, Integer> tasksByZone) { this.tasksByZone = tasksByZone; }
    public Map<String, Integer> getChestContents() { return chestContents; }
    public void setChestContents(Map<String, Integer> chestContents) { this.chestContents = chestContents; }
    public int getCombinatorsActive() { return combinatorsActive; }
    public void setCombinatorsActive(int combinatorsActive) { this.combinatorsActive = combinatorsActive; }
    public double getEfficiency() { return efficiency; }
    public void setEfficiency(double efficiency) { this.efficiency = efficiency; }
}