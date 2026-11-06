package com.example.demo.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/health")
@Tag(name = "Health API", description = "Endpoints for monitoring system health")
public class HealthController {

    @Value("${spring.application.name:eks-demo}")
    private String appName;
    
    @GetMapping
    @Operation(summary = "Check health status", description = "Returns health status of the application")
    public Map<String, Object> healthCheck() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "UP");
        health.put("service", appName);
        health.put("timestamp", System.currentTimeMillis());
        
        Map<String, String> system = new HashMap<>();
        system.put("javaVersion", System.getProperty("java.version"));
        system.put("javaVendor", System.getProperty("java.vendor"));
        system.put("osName", System.getProperty("os.name"));
        system.put("availableProcessors", String.valueOf(Runtime.getRuntime().availableProcessors()));
        health.put("system", system);
        
        return health;
    }
}
