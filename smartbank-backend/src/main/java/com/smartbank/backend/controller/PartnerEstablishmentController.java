package com.smartbank.backend.controller;

import com.smartbank.backend.dto.PartnerEstablishmentResponse;
import com.smartbank.backend.service.PartnerEstablishmentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/privileges/establishments")
public class PartnerEstablishmentController {

    private final PartnerEstablishmentService establishmentService;

    public PartnerEstablishmentController(
            PartnerEstablishmentService establishmentService) {
        this.establishmentService = establishmentService;
    }

    @GetMapping
    public ResponseEntity<List<PartnerEstablishmentResponse>> getActiveEstablishments() {
        List<PartnerEstablishmentResponse> response =
                establishmentService.getActiveEstablishments()
                        .stream()
                        .map(PartnerEstablishmentResponse::new)
                        .toList();

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<PartnerEstablishmentResponse> getActiveEstablishmentById(
            @PathVariable Long id) {
        return establishmentService.getActiveEstablishmentById(id)
                .map(PartnerEstablishmentResponse::new)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}