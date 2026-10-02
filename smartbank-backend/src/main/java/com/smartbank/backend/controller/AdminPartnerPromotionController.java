package com.smartbank.backend.controller;

import com.smartbank.backend.dto.PartnerPromotionRequest;
import com.smartbank.backend.dto.PartnerPromotionResponse;
import com.smartbank.backend.service.PartnerPromotionService;
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
@RequestMapping("/api/admin/privileges/promotions")
public class AdminPartnerPromotionController {

    private final PartnerPromotionService promotionService;

    public AdminPartnerPromotionController(
            PartnerPromotionService promotionService) {
        this.promotionService = promotionService;
    }

    @GetMapping
    public ResponseEntity<List<PartnerPromotionResponse>> getAllPromotions() {
        List<PartnerPromotionResponse> response =
                promotionService.getAllPromotions()
                        .stream()
                        .map(PartnerPromotionResponse::new)
                        .toList();

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<PartnerPromotionResponse> getPromotionById(
            @PathVariable Long id) {
        return promotionService.getPromotionById(id)
                .map(PartnerPromotionResponse::new)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<?> createPromotion(
            @RequestBody PartnerPromotionRequest request) {
        try {
            PartnerPromotionResponse response =
                    new PartnerPromotionResponse(
                            promotionService.createPromotion(request)
                    );
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updatePromotion(
            @PathVariable Long id,
            @RequestBody PartnerPromotionRequest request) {
        try {
            return promotionService.updatePromotion(id, request)
                    .map(PartnerPromotionResponse::new)
                    .<ResponseEntity<?>>map(ResponseEntity::ok)
                    .orElse(ResponseEntity.notFound().build());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deactivatePromotion(@PathVariable Long id) {
        if (!promotionService.deactivatePromotion(id)) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.noContent().build();
    }
}