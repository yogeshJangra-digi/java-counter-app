package com.example.counter.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
public class HealthController {

    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "ok");
        response.put("message", "Java Counter Backend is running!");
        response.put("timestamp", LocalDateTime.now().toString());
        response.put("service", "counter-backend");
        return response;
    }

    @GetMapping("/info")
    public Map<String, Object> info() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "ok");
        response.put("service", "counter-backend");
        response.put("version", "1.0.0");
        response.put("environment", System.getProperty("spring.profiles.active", "default"));
        response.put("java.version", System.getProperty("java.version"));
        return response;
    }
}
