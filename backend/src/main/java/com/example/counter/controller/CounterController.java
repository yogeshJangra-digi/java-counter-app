package com.example.counter.controller;

import com.example.counter.model.CounterResponse;
import com.example.counter.service.CounterService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/counter")
@CrossOrigin(origins = "*") // Allow all origins for testing
public class CounterController {

    @Autowired
    private CounterService counterService;

    @GetMapping
    public CounterResponse getCounter() {
        return new CounterResponse(counterService.getCurrentValue());
    }

    @PostMapping("/increment")
    public CounterResponse incrementCounter() {
        return new CounterResponse(counterService.increment());
    }

    @PostMapping("/decrement")
    public CounterResponse decrementCounter() {
        return new CounterResponse(counterService.decrement());
    }

    @PostMapping("/reset")
    public CounterResponse resetCounter() {
        return new CounterResponse(counterService.reset());
    }
}
