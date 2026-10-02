package com.smartbank.backend.controller;

import com.smartbank.backend.dto.PartnerPromotionResponse;
import com.smartbank.backend.service.PartnerPromotionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/privileges/promotions")
public class PartnerPromotionController {

    private final PartnerPromotionService promotionService;

    public PartnerPromotionController(
            PartnerPromotionService promotionService) {
        this.promotionService = promotionService;
    }

    @GetMapping
    public ResponseEntity<List<PartnerPromotionResponse>> getActivePromotions() {
        List<PartnerPromotionResponse> response =
                promotionService.getCurrentlyActivePromotions()
                        .stream()
                        .map(PartnerPromotionResponse::new)
                        .toList();

        return ResponseEntity.ok(response);
    }

    @GetMapping("/establishment/{establishmentId}")
    public ResponseEntity<List<PartnerPromotionResponse>> getActivePromotionsByEstablishment(
            @PathVariable Long establishmentId) {
        List<PartnerPromotionResponse> response =
                promotionService.getCurrentlyActivePromotionsByEstablishment(
                                establishmentId
                        )
                        .stream()
                        .map(PartnerPromotionResponse::new)
                        .toList();

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<PartnerPromotionResponse> getActivePromotionById(
            @PathVariable Long id) {
        return promotionService.getCurrentlyActivePromotionById(id)
                .map(PartnerPromotionResponse::new)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}