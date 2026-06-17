package com.dronestats.controller;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

@Controller
public class WebSocketController {

    // Client can request a snapshot on demand
    @MessageMapping("/requestSnapshot")
    @SendTo("/topic/snapshot")
    public String requestSnapshot() {
        // The actual snapshot is sent by DataSimulator periodically.
        // This method just triggers a new broadcast, but we rely on scheduled sending.
        return "Request received";
    }
}