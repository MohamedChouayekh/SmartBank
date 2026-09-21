package com.smartbank.backend.controller;

import com.smartbank.backend.entity.SupportRequest;
import com.smartbank.backend.service.SupportService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/support")
public class SupportController {

    private final SupportService supportService;

    public SupportController(SupportService supportService) {
        this.supportService = supportService;
    }

    // =========================================================
    // CRÉER UNE DEMANDE DE SUPPORT
    // =========================================================

    @PostMapping
    public ResponseEntity<?> createRequest(
            @RequestBody Map<String, Object> request) {

        try {

            if (request.get("userId") == null) {
                throw new RuntimeException(
                        "Utilisateur obligatoire."
                );
            }

            Long userId = Long.valueOf(
                    request.get("userId").toString()
            );

            String category =
                    request.get("category") != null
                            ? request.get("category").toString()
                            : null;

            String subject =
                    request.get("subject") != null
                            ? request.get("subject").toString()
                            : null;

            String message =
                    request.get("message") != null
                            ? request.get("message").toString()
                            : null;

            SupportRequest supportRequest =
                    supportService.createRequest(
                            userId,
                            category,
                            subject,
                            message
                    );

            return ResponseEntity.ok(
                    toResponse(supportRequest)
            );

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(Map.of(
                            "message",
                            e.getMessage() != null
                                    ? e.getMessage()
                                    : "Erreur lors de la création de la demande."
                    ));
        }
    }

    // =========================================================
    // RÉCUPÉRER LES DEMANDES D'UN UTILISATEUR
    // =========================================================

    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getUserRequests(
            @PathVariable Long userId) {

        try {

            List<SupportRequest> requests =
                    supportService.getUserRequests(userId);

            List<Map<String, Object>> response =
                    requests.stream()
                            .map(this::toResponse)
                            .toList();

            return ResponseEntity.ok(response);

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(Map.of(
                            "message",
                            e.getMessage() != null
                                    ? e.getMessage()
                                    : "Erreur lors de la récupération des demandes."
                    ));
        }
    }

    // =========================================================
    // ADMIN : RÉCUPÉRER TOUTES LES DEMANDES
    // =========================================================

    @GetMapping("/admin")
    public ResponseEntity<?> getAllRequests() {

        try {

            List<SupportRequest> requests =
                    supportService.getAllRequests();

            List<Map<String, Object>> response =
                    requests.stream()
                            .map(this::toAdminResponse)
                            .toList();

            return ResponseEntity.ok(response);

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(Map.of(
                            "message",
                            e.getMessage() != null
                                    ? e.getMessage()
                                    : "Erreur lors de la récupération des demandes."
                    ));
        }
    }

    // =========================================================
    // ADMIN : RÉCUPÉRER UNE DEMANDE
    // =========================================================

    @GetMapping("/admin/{requestId}")
    public ResponseEntity<?> getRequest(
            @PathVariable Long requestId) {

        try {

            SupportRequest request =
                    supportService.getRequest(requestId);

            return ResponseEntity.ok(
                    toAdminResponse(request)
            );

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(Map.of(
                            "message",
                            e.getMessage() != null
                                    ? e.getMessage()
                                    : "Demande introuvable."
                    ));
        }
    }

    // =========================================================
    // ADMIN : RÉPONDRE À UNE DEMANDE
    // =========================================================

    @PutMapping("/admin/{requestId}/reply")
    public ResponseEntity<?> replyToRequest(
            @PathVariable Long requestId,
            @RequestBody Map<String, Object> request) {

        try {

            String response =
                    request.get("response") != null
                            ? request.get("response").toString()
                            : null;

            SupportRequest updatedRequest =
                    supportService.replyToRequest(
                            requestId,
                            response
                    );

            return ResponseEntity.ok(
                    toAdminResponse(updatedRequest)
            );

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(Map.of(
                            "message",
                            e.getMessage() != null
                                    ? e.getMessage()
                                    : "Erreur lors de l'envoi de la réponse."
                    ));
        }
    }

    // =========================================================
    // ADMIN : MODIFIER LE STATUT
    // =========================================================

    @PutMapping("/admin/{requestId}/status")
    public ResponseEntity<?> updateStatus(
            @PathVariable Long requestId,
            @RequestBody Map<String, Object> request) {

        try {

            String status =
                    request.get("status") != null
                            ? request.get("status").toString()
                            : null;

            SupportRequest updatedRequest =
                    supportService.updateStatus(
                            requestId,
                            status
                    );

            return ResponseEntity.ok(
                    toAdminResponse(updatedRequest)
            );

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(Map.of(
                            "message",
                            e.getMessage() != null
                                    ? e.getMessage()
                                    : "Erreur lors de la modification du statut."
                    ));
        }
    }

    // =========================================================
    // RÉPONSE UTILISATEUR
    // =========================================================

    private Map<String, Object> toResponse(
            SupportRequest request) {

        return Map.of(
                "id",
                request.getId(),

                "userId",
                request.getUser().getId(),

                "category",
                request.getCategory(),

                "subject",
                request.getSubject(),

                "message",
                request.getMessage(),

                "adminResponse",
                request.getAdminResponse() != null
                        ? request.getAdminResponse()
                        : "",

                "status",
                request.getStatus(),

                "createdAt",
                request.getCreatedAt(),

                "updatedAt",
                request.getUpdatedAt()
        );
    }

    // =========================================================
    // RÉPONSE ADMIN
    // =========================================================

    private Map<String, Object> toAdminResponse(
            SupportRequest request) {

        Map<String, Object> response =
                new HashMap<>();

        response.put(
                "id",
                request.getId()
        );

        response.put(
                "userId",
                request.getUser().getId()
        );

        response.put(
                "username",
                request.getUser().getUsername()
        );

        response.put(
                "fullName",
                request.getUser().getFullName()
        );

        response.put(
                "email",
                request.getUser().getEmail()
        );

        response.put(
                "category",
                request.getCategory()
        );

        response.put(
                "subject",
                request.getSubject()
        );

        response.put(
                "message",
                request.getMessage()
        );

        response.put(
                "adminResponse",
                request.getAdminResponse() != null
                        ? request.getAdminResponse()
                        : ""
        );

        response.put(
                "status",
                request.getStatus()
        );

        response.put(
                "createdAt",
                request.getCreatedAt()
        );

        response.put(
                "updatedAt",
                request.getUpdatedAt()
        );

        return response;
    }
}