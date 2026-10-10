package com.smartbank.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
public class SmartbankBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(SmartbankBackendApplication.class, args);
    }

}

