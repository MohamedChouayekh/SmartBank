package com.smartbank.backend.controller;

import com.smartbank.backend.entity.Atm;
import com.smartbank.backend.service.AtmService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/atms")
public class AtmController {

    private final AtmService atmService;

    public AtmController(AtmService atmService) {
        this.atmService = atmService;
    }

    // =========================================================
    // LISTE DES DAB
    // =========================================================

    @GetMapping
    public ResponseEntity<?> getAllAtms() {

        try {

            List<Atm> atms = atmService.getAllAtms();

            List<Map<String, Object>> response =
                    atms.stream()
                            .map(atm -> Map.<String, Object>of(
                                    "id", atm.getId(),
                                    "name", atm.getName(),
                                    "city", atm.getCity(),
                                    "address", atm.getAddress(),
                                    "available24h", atm.isAvailable24h(),
                                    "withdrawalAvailable",
                                    atm.isWithdrawalAvailable(),
                                    "depositAvailable",
                                    atm.isDepositAvailable(),
                                    "available",
                                    atm.isAvailable()
                            ))
                            .toList();

            return ResponseEntity.ok(response);

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(Map.of(
                            "message",
                            e.getMessage()
                    ));
        }
    }

    // =========================================================
    // DAB PAR ID
    // =========================================================

    @GetMapping("/{atmId}")
    public ResponseEntity<?> getAtm(
            @PathVariable Long atmId) {

        try {

            Atm atm = atmService.getAtmById(atmId);

            return ResponseEntity.ok(
                    Map.of(
                            "id", atm.getId(),
                            "name", atm.getName(),
                            "city", atm.getCity(),
                            "address", atm.getAddress(),
                            "available24h", atm.isAvailable24h(),
                            "withdrawalAvailable",
                            atm.isWithdrawalAvailable(),
                            "depositAvailable",
                            atm.isDepositAvailable(),
                            "available",
                            atm.isAvailable()
                    )
            );

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(Map.of(
                            "message",
                            e.getMessage()
                    ));
        }
    }
}