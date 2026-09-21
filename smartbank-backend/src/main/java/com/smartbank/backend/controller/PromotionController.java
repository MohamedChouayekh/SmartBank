package com.smartbank.backend.controller;

import com.smartbank.backend.service.PromotionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/promotions")
public class PromotionController {

    private final PromotionService promotionService;

    public PromotionController(
            PromotionService promotionService) {

        this.promotionService =
                promotionService;
    }

    // =========================================================
    // ENVOYER UNE PROMOTION À UN CLIENT
    // =========================================================
    //
    // POST /api/admin/promotions/user
    //
    // Body :
    // {
    //     "userId": 11,
    //     "title": "Offre spéciale SmartBank",
    //     "message": "Profitez de notre nouvelle offre."
    // }
    // =========================================================

    @PostMapping("/user")
    public ResponseEntity<?> sendToUser(
            @RequestBody Map<String, Object> request) {

        try {

            if (request.get("userId") == null) {

                throw new RuntimeException(
                        "Utilisateur obligatoire."
                );
            }

            Long userId =
                    Long.valueOf(
                            request.get("userId")
                                    .toString()
                    );

            String title =
                    request.get("title") != null
                            ? request.get("title")
                            .toString()
                            : null;

            String message =
                    request.get("message") != null
                            ? request.get("message")
                            .toString()
                            : null;

            promotionService.sendToUser(
                    userId,
                    title,
                    message
            );

            return ResponseEntity.ok(
                    Map.of(
                            "message",
                            "Promotion envoyée avec succès."
                    )
            );

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(
                            Map.of(
                                    "message",
                                    e.getMessage()
                            )
                    );
        }
    }

    // =========================================================
    // ENVOYER UNE PROMOTION À TOUS LES CLIENTS
    // =========================================================
    //
    // POST /api/admin/promotions/all
    //
    // Body :
    // {
    //     "title": "Offre spéciale SmartBank",
    //     "message": "Découvrez notre nouvelle offre."
    // }
    // =========================================================

    @PostMapping("/all")
    public ResponseEntity<?> sendToAllClients(
            @RequestBody Map<String, Object> request) {

        try {

            String title =
                    request.get("title") != null
                            ? request.get("title")
                            .toString()
                            : null;

            String message =
                    request.get("message") != null
                            ? request.get("message")
                            .toString()
                            : null;

            int sentCount =
                    promotionService.sendToAllClients(
                            title,
                            message
                    );

            return ResponseEntity.ok(
                    Map.of(
                            "message",
                            "Promotion envoyée à tous les clients actifs.",

                            "sentCount",
                            sentCount
                    )
            );

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(
                            Map.of(
                                    "message",
                                    e.getMessage()
                            )
                    );
        }
    }
}