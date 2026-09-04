package com.smartbank.backend.controller;

import com.smartbank.backend.entity.RadarFine;
import com.smartbank.backend.service.RadarFineService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

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
    public ResponseEntity<?> payFine(@PathVariable String reference) {

        boolean paid = radarFineService.payFine(reference);

        if (!paid) {
            return ResponseEntity.status(404).body("Amende introuvable ou déjà payée.");
        }

        return ResponseEntity.ok("Amende payée avec succès.");
    }
}