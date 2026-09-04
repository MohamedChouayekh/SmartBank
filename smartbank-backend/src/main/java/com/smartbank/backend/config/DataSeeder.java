package com.smartbank.backend.config;

import com.smartbank.backend.entity.RadarFine;
import com.smartbank.backend.repository.RadarFineRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.LocalDate;

@Configuration
public class DataSeeder {

    @Bean
    public CommandLineRunner seedRadarFines(RadarFineRepository radarFineRepository) {
        return args -> {
            if (radarFineRepository.count() == 0) {
                radarFineRepository.save(new RadarFine(
                        "GN12345678901234", "Radar Fixe", "123TUN456",
                        LocalDate.of(2018, 5, 27), 120.000, false
                ));
                radarFineRepository.save(new RadarFine(
                        "SN98765432109876", "Radar Fixe", "123TUN456",
                        LocalDate.of(2018, 4, 10), 80.000, false
                ));
                radarFineRepository.save(new RadarFine(
                        "GN55566677788899", "Radar Mobile", "236TUN1414",
                        LocalDate.of(2024, 1, 15), 60.000, false
                ));
                radarFineRepository.save(new RadarFine(
                        "GN11122233344455", "Radar Fixe", "252TUN1234",
                        LocalDate.of(2023, 9, 3), 45.500, false
                ));
            }
        };
    }
}