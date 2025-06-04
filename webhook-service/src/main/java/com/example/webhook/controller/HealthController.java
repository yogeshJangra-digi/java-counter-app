package com.example.webhook.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
public class HealthController {

    @Value("${server.port:8081}")
    private String port;

    @Value("${git.repo.path:/workspace}")
    private String repoPath;

    @Value("${git.branch:main}")
    private String gitBranch;

    @Value("${webhook.debug:false}")
    private boolean debug;

    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "ok");
        response.put("message", "Java Webhook service is running");
        
        Map<String, Object> config = new HashMap<>();
        config.put("port", port);
        config.put("repoPath", repoPath);
        config.put("gitBranch", gitBranch);
        config.put("debug", debug);
        
        response.put("config", config);
        response.put("timestamp", LocalDateTime.now().toString());
        
        return response;
    }
}
