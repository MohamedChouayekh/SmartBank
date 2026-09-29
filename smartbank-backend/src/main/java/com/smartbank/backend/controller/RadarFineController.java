package com.smartbank.backend.controller;

import com.smartbank.backend.entity.RadarFine;
import com.smartbank.backend.service.RadarFineService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/amendes")
public class RadarFineController {

    private final RadarFineService radarFineService;

    public RadarFineController(RadarFineService radarFineService) {
        this.radarFineService = radarFineService;
    }

    @GetMapping
    public ResponseEntity<?> getFines(@RequestParam String immatriculation) {

        if (immatriculation == null || immatriculation.trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Immatriculation obligatoire.");
        }

        List<RadarFine> fines = radarFineService.findUnpaidByImmatriculation(
                immatriculation.trim().toUpperCase()
        );

        return ResponseEntity.ok(fines);
    }

    @PostMapping("/{reference}/payer")
    public ResponseEntity<?> payFine(
            @PathVariable String reference,
            @RequestBody Map<String, Object> request) {

        try {

            if (request.get("accountNumber") == null) {
                return ResponseEntity.badRequest()
                        .body(Map.of(
                                "message",
                                "Le compte est obligatoire."
                        ));
            }

            String accountNumber =
                    request.get("accountNumber")
                            .toString()
                            .trim();

            boolean paid = radarFineService.payFine(
                    reference,
                    accountNumber
            );

            if (!paid) {
                return ResponseEntity.status(404)
                        .body(Map.of(
                                "message",
                                "Amende introuvable ou déjà payée."
                        ));
            }

            return ResponseEntity.ok(
                    Map.of(
                            "message",
                            "Amende payée avec succès."
                    )
            );

        } catch (RuntimeException e) {

            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "message",
                            e.getMessage() != null
                                    ? e.getMessage()
                                    : "Erreur lors du paiement de l'amende."
                    ));
        }
    }
}