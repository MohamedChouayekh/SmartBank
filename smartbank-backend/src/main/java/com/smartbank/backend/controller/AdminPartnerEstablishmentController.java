package com.smartbank.backend.controller;

import com.smartbank.backend.dto.PartnerEstablishmentRequest;
import com.smartbank.backend.dto.PartnerEstablishmentResponse;
import com.smartbank.backend.service.PartnerEstablishmentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/privileges/establishments")
public class AdminPartnerEstablishmentController {

    private final PartnerEstablishmentService establishmentService;

    public AdminPartnerEstablishmentController(
            PartnerEstablishmentService establishmentService) {
        this.establishmentService = establishmentService;
    }

    @GetMapping
    public ResponseEntity<List<PartnerEstablishmentResponse>> getAllEstablishments() {
        List<PartnerEstablishmentResponse> response =
                establishmentService.getAllEstablishments()
                        .stream()
                        .map(PartnerEstablishmentResponse::new)
                        .toList();

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<PartnerEstablishmentResponse> getEstablishmentById(
            @PathVariable Long id) {
        return establishmentService.getEstablishmentById(id)
                .map(PartnerEstablishmentResponse::new)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<?> createEstablishment(
            @RequestBody PartnerEstablishmentRequest request) {
        try {
            PartnerEstablishmentResponse response =
                    new PartnerEstablishmentResponse(
                            establishmentService.createEstablishment(request));
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateEstablishment(
            @PathVariable Long id,
            @RequestBody PartnerEstablishmentRequest request) {
        try {
            return establishmentService.updateEstablishment(id, request)
                    .map(PartnerEstablishmentResponse::new)
                    .<ResponseEntity<?>>map(ResponseEntity::ok)
                    .orElse(ResponseEntity.notFound().build());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deactivateEstablishment(@PathVariable Long id) {
        if (!establishmentService.deactivateEstablishment(id)) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.noContent().build();
    }
}