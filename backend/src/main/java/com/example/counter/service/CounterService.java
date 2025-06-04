package com.example.counter.service;

import org.springframework.stereotype.Service;

@Service
public class CounterService {

    private int counter = 0;

    public int getCurrentValue() {
        return counter;
    }

    public int increment() {
        counter += 11;
        return counter;
    }

    public int decrement() {
        counter -= 1;
        return counter;
    }

    public int reset() {
        counter = 0;
        return counter;
    }
}
