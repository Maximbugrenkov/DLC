// Глобальные объекты
let droneChart, zonePieChart, priorityChart, chestChart;
let logisticHistory = [], constructionHistory = [], timeLabels = [];
let stompClient = null;

// Вспомогательные функции
function updateGauge(elementId, percent) {
    const fill = document.getElementById(elementId);
    if (fill) fill.style.width = (percent * 100) + '%';
}

function initCharts() {
    const droneCtx = document.getElementById('droneChart').getContext('2d');
    droneChart = new Chart(droneCtx, {
        type: 'line',
        data: { labels: [], datasets: [
            { label: 'Логистические дроны', borderColor: '#42a5f5', backgroundColor: 'rgba(66,165,245,0.1)', data: [], tension: 0.2, fill: true },
            { label: 'Строительные дроны', borderColor: '#66bb6a', backgroundColor: 'rgba(102,187,106,0.1)', data: [], tension: 0.2, fill: true }
        ]},
        options: { responsive: true, maintainAspectRatio: true }
    });
    const pieCtx = document.getElementById('zonePieChart').getContext('2d');
    zonePieChart = new Chart(pieCtx, {
        type: 'pie',
        data: { labels: [], datasets: [{ data: [], backgroundColor: ['#ff6384','#36a2eb','#ffce56','#4bc0c0','#9966ff','#ff9f40'] }] },
        options: { responsive: true, maintainAspectRatio: true }
    });
    const priorityCtx = document.getElementById('priorityChart').getContext('2d');
    priorityChart = new Chart(priorityCtx, {
        type: 'bar',
        data: { labels: [], datasets: [{ label: 'Приоритет', data: [], backgroundColor: '#ffa726' }] },
        options: { responsive: true, maintainAspectRatio: true, indexAxis: 'y' }
    });
    const chestCtx = document.getElementById('chestChart').getContext('2d');
    chestChart = new Chart(chestCtx, {
        type: 'bar',
        data: { labels: [], datasets: [{ label: 'Количество (тыс.)', data: [], backgroundColor: '#66bb6a' }] },
        options: { responsive: true, maintainAspectRatio: true, scales: { y: { beginAtZero: true, ticks: { callback: v => (v/1000).toFixed(0)+'k' } } } }
    });
}

function updateUI(snapshot) {
    // Общие метрики
    document.getElementById('chargeValue').innerText = Math.round(snapshot.drones.avgCharge * 100) + '%';
    updateGauge('chargeFill', snapshot.drones.avgCharge);
    document.getElementById('efficiencyValue').innerText = Math.round(snapshot.efficiency * 100) + '%';
    updateGauge('efficiencyFill', snapshot.efficiency);
    document.getElementById('combinatorCount').innerText = snapshot.combinatorsActive;

    // История дронов
    logisticHistory.push(snapshot.drones.logistic);
    constructionHistory.push(snapshot.drones.construction);
    if (logisticHistory.length > 30) logisticHistory.shift();
    if (constructionHistory.length > 30) constructionHistory.shift();
    const labels = logisticHistory.map((_, idx) => idx * 2 + 's ago');
    droneChart.data.labels = labels;
    droneChart.data.datasets[0].data = [...logisticHistory];
    droneChart.data.datasets[1].data = [...constructionHistory];
    droneChart.update();

    // Круговая диаграмма задач по зонам
    const zoneNames = Object.keys(snapshot.tasksByZone);
    const tasksCounts = Object.values(snapshot.tasksByZone);
    zonePieChart.data.labels = zoneNames;
    zonePieChart.data.datasets[0].data = tasksCounts;
    zonePieChart.update();

    // Приоритеты зон
    if (snapshot.zones) {
        const priorityNames = snapshot.zones.map(z => z.name);
        const priorities = snapshot.zones.map(z => z.priority);
        priorityChart.data.labels = priorityNames;
        priorityChart.data.datasets[0].data = priorities;
        priorityChart.update();
    }

    // Содержимое сундуков (общее)
    const items = Object.keys(snapshot.chestContents);
    const counts = Object.values(snapshot.chestContents);
    chestChart.data.labels = items;
    chestChart.data.datasets[0].data = counts;
    chestChart.update();

    // Детализация по зонам, сундукам, дронам, связям
    renderZonesDetails(snapshot.zones);
    renderDronesDetails(snapshot.droneDetails);
    renderChestsDetails(snapshot.zones);
    renderLinksDetails(snapshot.zones);
}

function renderZonesDetails(zones) {
    const container = document.getElementById('zonesDetails');
    if (!zones || zones.length === 0) {
        container.innerHTML = '<p>Нет данных о зонах</p>';
        return;
    }
    let html = '';
    for (const zone of zones) {
        html += `<div class="zone-block">
            <h3>${zone.name} (${zone.width}x${zone.height})</h3>
            <p><strong>Приоритет:</strong> ${zone.priority}</p>
            <p><strong>Призраки:</strong></p>
            <ul>`;
        for (const ghost of zone.ghosts || []) {
            html += `<li>${ghost.name}: ${ghost.built}/${ghost.count} построено</li>`;
        }
        html += `</ul>
            <p><strong>Задачи:</strong></p>
            <ul>`;
        for (const task of zone.tasks || []) {
            html += `<li>${task.name} (${task.type}) - дронов: ${task.droneCount}, активна: ${task.enabled}</li>`;
        }
        html += `</ul></div>`;
    }
    container.innerHTML = html;
}

function renderDronesDetails(drones) {
    const container = document.getElementById('dronesDetails');
    if (!drones || drones.length === 0) {
        container.innerHTML = '<p>Нет данных о дронах</p>';
        return;
    }
    let html = '<ul>';
    for (const drone of drones) {
        html += `<li>Дрон #${drone.id} (${drone.type}): заряд ${Math.round(drone.charge*100)}%, статус: ${drone.status}, задача: ${drone.currentTaskId || 'нет'}</li>`;
    }
    html += '</ul>';
    container.innerHTML = html;
}

function renderChestsDetails(zones) {
    const container = document.getElementById('chestsDetails');
    if (!zones || zones.length === 0) {
        container.innerHTML = '<p>Нет данных о сундуках</p>';
        return;
    }
    let html = '';
    for (const zone of zones) {
        html += `<div><h3>${zone.name}</h3>`;
        for (const chest of zone.chests || []) {
            html += `<div class="chest-item"><strong>${chest.name}</strong> (${chest.type})<br>Содержимое: `;
            if (chest.contents) {
                const items = Object.entries(chest.contents).map(([k,v]) => `${k}: ${v}`).join(', ');
                html += items;
            }
            if (chest.requests) {
                html += `<br>Запросы: ` + Object.entries(chest.requests).map(([k,v]) => `${k}: ${v}`).join(', ');
            }
            html += `</div>`;
        }
        html += `</div>`;
    }
    container.innerHTML = html;
}

function renderLinksDetails(zones) {
    const container = document.getElementById('linksDetails');
    if (!zones || zones.length === 0) {
        container.innerHTML = '<p>Нет связей</p>';
        return;
    }
    let html = '';
    for (const zone of zones) {
        if (zone.links && zone.links.length) {
            html += `<div><h3>${zone.name}</h3><ul>`;
            for (const link of zone.links) {
                html += `<li>${link.from} → ${link.to} (ресурс: ${link.resourceType})</li>`;
            }
            html += `</ul></div>`;
        }
    }
    if (html === '') html = '<p>Нет связей между зонами</p>';
    container.innerHTML = html;
}

function connectWebSocket() {
    const socket = new SockJS('/ws');
    stompClient = Stomp.over(socket);
    stompClient.connect({}, function() {
        stompClient.subscribe('/topic/snapshot', function(message) {
            const snapshot = JSON.parse(message.body);
            updateUI(snapshot);
        });
        stompClient.send('/app/requestSnapshot', {}, {});
    });
}

// Ручное обновление (через REST)
async function refreshData() {
    try {
        const response = await fetch('/api/stats/latest');
        if (response.ok) {
            const snapshot = await response.json();
            updateUI(snapshot);
        }
    } catch (err) {
        console.error('Ошибка при обновлении данных', err);
    }
}

// Пример редактирования приоритетов (открываем модальное окно)
function editPriorities() {
    alert('Функция редактирования приоритетов зон будет реализована в следующей версии.\nСейчас можно менять приоритеты через API: POST /api/zone/{id}/priority');
}

window.onload = () => {
    initCharts();
    connectWebSocket();
    document.getElementById('refreshDataBtn').addEventListener('click', refreshData);
    document.getElementById('editPrioritiesBtn').addEventListener('click', editPriorities);
};