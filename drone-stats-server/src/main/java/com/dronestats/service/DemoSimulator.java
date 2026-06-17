package com.dronestats.service;

import com.dronestats.dto.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class DemoSimulator {

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Autowired
    private StatsService statsService;

    private List<ZoneStats> zones;
    private List<DroneDetail> drones;
    private int step = 0;
    private final int MAX_STEPS = 120;
    private boolean finished = false;
    private boolean normalConstructionFinished = false; // все, кроме сборочного автомата
    private boolean assemblerBuilt = false;

    private Map<String, ChestDetail> chestMap = new ConcurrentHashMap<>();

    @PostConstruct
    public void init() {
        buildInitialState();
        sendSnapshot();
    }

    private void buildInitialState() {
        zones = new ArrayList<>();
        drones = new ArrayList<>();
        chestMap.clear();

        // ---------- ОБЛАСТЬ А ----------
        ZoneStats zoneA = new ZoneStats();
        zoneA.setId("zone_a");
        zoneA.setName("Область А");
        zoneA.setPriority(100);
        zoneA.setWidth(9);
        zoneA.setHeight(6);
        zoneA.setChests(new ArrayList<>());
        zoneA.setGhosts(new ArrayList<>());
        zoneA.setTasks(new ArrayList<>());
        zoneA.setLinks(new ArrayList<>());
        zoneA.setResourcesInTransit(new HashMap<>());

        // Призраки
        List<GhostDetail> ghostsA = new ArrayList<>();
        ghostsA.add(new GhostDetail("Транспортная лента", 6, "belt"));
        ghostsA.add(new GhostDetail("Манипулятор", 2, "inserter"));
        ghostsA.add(new GhostDetail("Сборочный автомат", 1, "assembler"));
        zoneA.setGhosts(ghostsA);

        // Сундуки
        ChestDetail chest1 = createStorageChest("1", zoneA.getId(), 200, 200, 400);
        ChestDetail chest2 = createStorageChest("2", zoneA.getId(), 200, 200, 400);
        ChestDetail chest3 = createStorageChest("3", zoneA.getId(), 200, 200, 400);
        ChestDetail chestBuild = createStorageChest("строительный", zoneA.getId(), 0, 0, 0);
        chestBuild.getContents().put("transport-belt", 100);
        chestBuild.getContents().put("inserter", 50);

        zoneA.getChests().addAll(List.of(chest1, chest2, chest3, chestBuild));
        chestMap.put("A_chest_1", chest1);
        chestMap.put("A_chest_2", chest2);
        chestMap.put("A_chest_3", chest3);
        chestMap.put("A_chest_build", chestBuild);

        // Задачи
        TaskDetail taskIron = createTask("task_iron", "Поставка железа", "logistic", zoneA.getId(), true, 1, List.of("link_iron"));
        TaskDetail taskGear = createTask("task_gear", "Поставка шестерён", "logistic", zoneA.getId(), true, 1, List.of("link_gear"));
        TaskDetail taskCircuit = createTask("task_circuit", "Поставка микросхем", "logistic", zoneA.getId(), true, 1, List.of("link_circuit"));
        zoneA.getTasks().addAll(List.of(taskIron, taskGear, taskCircuit));

        // Связи
        zoneA.getLinks().add(new LinkDetail("A_chest_1", "B_chest_iron", "iron-plate"));
        zoneA.getLinks().add(new LinkDetail("A_chest_2", "B_chest_gear", "gear"));
        zoneA.getLinks().add(new LinkDetail("A_chest_3", "B_chest_circuit", "circuit"));

        zones.add(zoneA);

        // ---------- ОБЛАСТЬ Б ----------
        ZoneStats zoneB = new ZoneStats();
        zoneB.setId("zone_b");
        zoneB.setName("Область Б");
        zoneB.setPriority(100);
        zoneB.setWidth(8);
        zoneB.setHeight(6);
        zoneB.setChests(new ArrayList<>());
        zoneB.setGhosts(new ArrayList<>());
        zoneB.setTasks(new ArrayList<>());
        zoneB.setLinks(new ArrayList<>());
        zoneB.setResourcesInTransit(new HashMap<>());

        ChestDetail bufferChest = new ChestDetail();
        bufferChest.setName("сборочный автомат");
        bufferChest.setType("buffer");
        bufferChest.setContents(new HashMap<>());
        bufferChest.getContents().put("assembling-machine-1", 1); // сразу дадим один, чтобы дрон мог взять
        bufferChest.setLinkedZone(zoneB.getId());
        zoneB.getChests().add(bufferChest);
        chestMap.put("B_chest_buffer", bufferChest);

        ChestDetail reqIron = createRequesterChest("железо", zoneB.getId(), "iron-plate", 500);
        ChestDetail reqGear = createRequesterChest("шестерёнка", zoneB.getId(), "gear", 300);
        ChestDetail reqCircuit = createRequesterChest("микросхема", zoneB.getId(), "circuit", 600);
        zoneB.getChests().addAll(List.of(reqIron, reqGear, reqCircuit));
        chestMap.put("B_chest_iron", reqIron);
        chestMap.put("B_chest_gear", reqGear);
        chestMap.put("B_chest_circuit", reqCircuit);

        zones.add(zoneB);

        // ---------- ДРОНЫ ----------
        // Строительный дрон 1 (строит ленты и манипуляторы)
        DroneDetail droneConstr1 = new DroneDetail();
        droneConstr1.setId(1);
        droneConstr1.setType("construction");
        droneConstr1.setCharge(0.9);
        droneConstr1.setStatus("idle");
        droneConstr1.setCurrentTaskId("build_normal");
        droneConstr1.setZoneId("zone_a");
        drones.add(droneConstr1);

        // Строительный дрон 2 (берёт сборочный автомат из области Б)
        DroneDetail droneConstr2 = new DroneDetail();
        droneConstr2.setId(2);
        droneConstr2.setType("construction");
        droneConstr2.setCharge(0.85);
        droneConstr2.setStatus("idle");
        droneConstr2.setCurrentTaskId("build_assembler");
        droneConstr2.setZoneId("zone_b");
        drones.add(droneConstr2);

        // Логистические дроны
        DroneDetail droneLog1 = createLogisticDrone(3, "task_iron", "zone_a", 0.95);
        DroneDetail droneLog2 = createLogisticDrone(4, "task_gear", "zone_a", 0.95);
        DroneDetail droneLog3 = createLogisticDrone(5, "task_circuit", "zone_a", 0.95);
        drones.addAll(List.of(droneLog1, droneLog2, droneLog3));
    }

    private ChestDetail createStorageChest(String name, String zoneId, int iron, int gear, int circuit) {
        ChestDetail chest = new ChestDetail();
        chest.setName(name);
        chest.setType("storage");
        Map<String, Integer> cont = new LinkedHashMap<>();
        if (iron > 0) cont.put("iron-plate", iron);
        if (gear > 0) cont.put("gear", gear);
        if (circuit > 0) cont.put("circuit", circuit);
        chest.setContents(cont);
        chest.setLinkedZone(zoneId);
        return chest;
    }

    private ChestDetail createRequesterChest(String name, String zoneId, String requestItem, int requestAmount) {
        ChestDetail chest = new ChestDetail();
        chest.setName(name);
        chest.setType("requester");
        chest.setContents(new HashMap<>());
        Map<String, Integer> req = new HashMap<>();
        req.put(requestItem, requestAmount);
        chest.setRequests(req);
        chest.setLinkedZone(zoneId);
        return chest;
    }

    private TaskDetail createTask(String id, String name, String type, String zoneId, boolean enabled, int droneCount, List<String> links) {
        TaskDetail task = new TaskDetail();
        task.setId(id);
        task.setName(name);
        task.setType(type);
        task.setZoneId(zoneId);
        task.setEnabled(enabled);
        task.setDroneCount(droneCount);
        task.setLinks(links);
        return task;
    }

    private DroneDetail createLogisticDrone(long id, String taskId, String zoneId, double charge) {
        DroneDetail drone = new DroneDetail();
        drone.setId(id);
        drone.setType("logistic");
        drone.setCharge(charge);
        drone.setStatus("idle");
        drone.setCurrentTaskId(taskId);
        drone.setZoneId(zoneId);
        return drone;
    }

    @Scheduled(fixedDelay = 1000)
    public void generateAndSend() {
        if (finished) return;
        step++;
        if (step > MAX_STEPS) {
            finished = true;
            finishSimulation();
            sendSnapshot();
            return;
        }

        // 1. Строительство обычных объектов (ленты, манипуляторы) — только дрон №1
        if (!normalConstructionFinished) {
            boolean done = buildNormalGhosts();
            if (done) {
                normalConstructionFinished = true;
                System.out.println("Обычные объекты построены на шаге " + step);
            }
        }

        // 2. Строительство сборочного автомата — только после завершения обычного, только дрон №2
        if (normalConstructionFinished && !assemblerBuilt) {
            buildAssembler();
        }

        // 3. Логистика (перевозка ресурсов) — логистические дроны
        transferResourcesWithRandomness();

        // 4. Обновление заряда и статуса всех дронов
        updateDronesState();

        // 5. Отправка данных
        StatsSnapshot snapshot = buildSnapshot();
        statsService.updateSnapshot(snapshot);
        messagingTemplate.convertAndSend("/topic/snapshot", snapshot);
    }

    private boolean buildNormalGhosts() {
        ZoneStats zoneA = zones.stream().filter(z -> "zone_a".equals(z.getId())).findFirst().orElse(null);
        if (zoneA == null) return true;
        ChestDetail buildChest = chestMap.get("A_chest_build");
        if (buildChest == null) return true;

        DroneDetail drone1 = drones.get(0); // строительный дрон №1
        boolean allBuilt = true;
        Random rand = new Random();

        for (GhostDetail ghost : zoneA.getGhosts()) {
            if (ghost.getName().contains("Сборочный автомат")) continue;
            if (ghost.getBuilt() >= ghost.getCount()) continue;
            allBuilt = false;

            // Дрон может работать только если заряд > 0.3 и статус working
            if (!drone1.getStatus().equals("working") || drone1.getCharge() <= 0.3) continue;

            String neededItem = ghost.getName().contains("Транспортная лента") ? "transport-belt" : "inserter";
            int available = buildChest.getContents().getOrDefault(neededItem, 0);
            if (available > 0) {
                int toBuild = rand.nextInt(3); // 0,1,2
                toBuild = Math.min(toBuild, ghost.getCount() - ghost.getBuilt());
                toBuild = Math.min(toBuild, available);
                if (toBuild > 0) {
                    buildChest.getContents().put(neededItem, available - toBuild);
                    ghost.setBuilt(ghost.getBuilt() + toBuild);
                }
            }
        }
        return allBuilt;
    }

    private void buildAssembler() {
        ZoneStats zoneA = zones.stream().filter(z -> "zone_a".equals(z.getId())).findFirst().orElse(null);
        if (zoneA == null) return;
        GhostDetail assemblerGhost = zoneA.getGhosts().stream()
                .filter(g -> g.getName().equals("Сборочный автомат")).findFirst().orElse(null);
        if (assemblerGhost == null || assemblerGhost.getBuilt() >= assemblerGhost.getCount()) {
            assemblerBuilt = true;
            return;
        }

        ChestDetail bufferChest = chestMap.get("B_chest_buffer");
        if (bufferChest == null) return;

        DroneDetail drone2 = drones.get(1); // строительный дрон №2
        if (drone2.getStatus().equals("working") && drone2.getCharge() > 0.3) {
            int available = bufferChest.getContents().getOrDefault("assembling-machine-1", 0);
            if (available > 0) {
                bufferChest.getContents().put("assembling-machine-1", available - 1);
                assemblerGhost.setBuilt(assemblerGhost.getBuilt() + 1);
                assemblerBuilt = true;
                System.out.println("Сборочный автомат построен на шаге " + step);
            }
        }

        // Имитация пополнения буфера (раз в 3-4 шага, чтобы дрон не ждал вечно)
        if (!assemblerBuilt && step % 4 == 0 && bufferChest.getContents().getOrDefault("assembling-machine-1", 0) == 0) {
            bufferChest.getContents().put("assembling-machine-1", 1);
        }
    }

    private void transferResourcesWithRandomness() {
        ChestDetail src1 = chestMap.get("A_chest_1");
        ChestDetail src2 = chestMap.get("A_chest_2");
        ChestDetail src3 = chestMap.get("A_chest_3");
        ChestDetail dstIron = chestMap.get("B_chest_iron");
        ChestDetail dstGear = chestMap.get("B_chest_gear");
        ChestDetail dstCircuit = chestMap.get("B_chest_circuit");
        if (src1 == null || src2 == null || src3 == null) return;
        if (dstIron == null || dstGear == null || dstCircuit == null) return;

        Random rand = new Random();
        transfer(src1, dstIron, "iron-plate", rand.nextInt(21));
        transfer(src2, dstGear, "gear", rand.nextInt(21));
        transfer(src3, dstCircuit, "circuit", rand.nextInt(26));
    }

    private void transfer(ChestDetail from, ChestDetail to, String item, int amount) {
        Map<String, Integer> fromCont = from.getContents();
        Map<String, Integer> toCont = to.getContents();
        if (fromCont == null || toCont == null) return;
        int available = fromCont.getOrDefault(item, 0);
        if (available <= 0) return;
        int transfer = Math.min(amount, available);
        fromCont.put(item, available - transfer);
        toCont.put(item, toCont.getOrDefault(item, 0) + transfer);
    }

    private void updateDronesState() {
        Random rand = new Random();
        boolean hasLogisticWork = checkLogisticWorkRemaining();
        boolean hasConstructionWork = !normalConstructionFinished || !assemblerBuilt;

        for (DroneDetail drone : drones) {
            boolean hasWork = false;
            if (drone.getType().equals("construction")) {
                if (drone.getId() == 1) hasWork = !normalConstructionFinished;
                else if (drone.getId() == 2) hasWork = (normalConstructionFinished && !assemblerBuilt);
                hasWork = hasWork && hasConstructionWork;
            } else {
                hasWork = hasLogisticWork;
            }

            if (!hasWork) {
                // Нет задач — дрон отдыхает и медленно заряжается
                drone.setStatus("idle");
                drone.setCharge(Math.min(1.0, drone.getCharge() + 0.05));
                continue;
            }

            // Поведение в зависимости от статуса
            if (drone.getStatus().equals("working")) {
                double newCharge = drone.getCharge() - 0.04 - rand.nextDouble() * 0.03;
                drone.setCharge(Math.max(0, newCharge));
                if (drone.getCharge() <= 0.2) {
                    drone.setStatus("charging");
                } else if (rand.nextDouble() < 0.1) {
                    drone.setStatus("idle");
                }
            } else if (drone.getStatus().equals("charging")) {
                double newCharge = drone.getCharge() + 0.08 + rand.nextDouble() * 0.05;
                drone.setCharge(Math.min(1.0, newCharge));
                if (drone.getCharge() >= 0.85) {
                    drone.setStatus("working");
                }
            } else { // idle
                if (rand.nextDouble() < 0.5) {
                    drone.setStatus("working");
                } else {
                    drone.setCharge(Math.min(1.0, drone.getCharge() + 0.02));
                }
            }
        }
    }

    private boolean checkLogisticWorkRemaining() {
        ChestDetail src1 = chestMap.get("A_chest_1");
        ChestDetail src2 = chestMap.get("A_chest_2");
        ChestDetail src3 = chestMap.get("A_chest_3");
        int total = 0;
        if (src1 != null) total += src1.getContents().values().stream().mapToInt(i -> i).sum();
        if (src2 != null) total += src2.getContents().values().stream().mapToInt(i -> i).sum();
        if (src3 != null) total += src3.getContents().values().stream().mapToInt(i -> i).sum();
        return total > 0;
    }

    private void finishSimulation() {
        for (ZoneStats zone : zones) {
            for (GhostDetail ghost : zone.getGhosts()) ghost.setBuilt(ghost.getCount());
        }
        ChestDetail src1 = chestMap.get("A_chest_1");
        ChestDetail src2 = chestMap.get("A_chest_2");
        ChestDetail src3 = chestMap.get("A_chest_3");
        if (src1 != null) src1.getContents().clear();
        if (src2 != null) src2.getContents().clear();
        if (src3 != null) src3.getContents().clear();

        ChestDetail dstIron = chestMap.get("B_chest_iron");
        ChestDetail dstGear = chestMap.get("B_chest_gear");
        ChestDetail dstCircuit = chestMap.get("B_chest_circuit");
        if (dstIron != null) dstIron.getContents().put("iron-plate", 500);
        if (dstGear != null) dstGear.getContents().put("gear", 300);
        if (dstCircuit != null) dstCircuit.getContents().put("circuit", 600);
    }

    private StatsSnapshot buildSnapshot() {
        StatsSnapshot snapshot = new StatsSnapshot();
        snapshot.setTimestamp(System.currentTimeMillis());
        snapshot.setZones(zones);
        snapshot.setDroneDetails(drones);

        DronesStats dronesStats = new DronesStats();
        int logistic = (int) drones.stream().filter(d -> "logistic".equals(d.getType())).count();
        int construction = (int) drones.stream().filter(d -> "construction".equals(d.getType())).count();
        double avgCharge = drones.stream().mapToDouble(DroneDetail::getCharge).average().orElse(0);
        dronesStats.setTotal(logistic + construction);
        dronesStats.setLogistic(logistic);
        dronesStats.setConstruction(construction);
        dronesStats.setAvgCharge(avgCharge);
        snapshot.setDrones(dronesStats);

        Map<String, Integer> tasksByZone = new HashMap<>();
        for (ZoneStats zone : zones) tasksByZone.put(zone.getName(), zone.getTasks().size());
        snapshot.setTasksByZone(tasksByZone);

        Map<String, Integer> allChestContents = new LinkedHashMap<>();
        for (ZoneStats zone : zones) {
            for (ChestDetail chest : zone.getChests()) {
                if (chest.getContents() != null) {
                    for (Map.Entry<String, Integer> e : chest.getContents().entrySet()) {
                        allChestContents.merge(e.getKey(), e.getValue(), Integer::sum);
                    }
                }
            }
        }
        snapshot.setChestContents(allChestContents);

        snapshot.setCombinatorsActive(1);
        double totalGhosts = zones.stream().flatMap(z -> z.getGhosts().stream()).mapToInt(g -> g.getCount()).sum();
        double builtGhosts = zones.stream().flatMap(z -> z.getGhosts().stream()).mapToInt(g -> g.getBuilt()).sum();
        snapshot.setEfficiency(totalGhosts == 0 ? 0 : builtGhosts / totalGhosts);
        return snapshot;
    }

    private void sendSnapshot() {
        StatsSnapshot snapshot = buildSnapshot();
        statsService.updateSnapshot(snapshot);
        messagingTemplate.convertAndSend("/topic/snapshot", snapshot);
    }
}