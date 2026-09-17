package com.smartbank.backend.controller;

import com.smartbank.backend.entity.CardUnblockRequest;
import com.smartbank.backend.service.CardUnblockRequestService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
public class CardUnblockRequestController {

    private final CardUnblockRequestService requestService;

    public CardUnblockRequestController(
            CardUnblockRequestService requestService) {

        this.requestService = requestService;
    }

    // =========================================================
    // DTO : DEMANDE CLIENT
    // =========================================================

    public static class UnblockRequestBody {

        private Long userId;
        private String message;

        public UnblockRequestBody() {
        }

        public Long getUserId() {
            return userId;
        }

        public void setUserId(Long userId) {
            this.userId = userId;
        }

        public String getMessage() {
            return message;
        }

        public void setMessage(String message) {
            this.message = message;
        }
    }

    // =========================================================
    // DTO : DEMANDE ADMIN
    // =========================================================

    public static class AdminRequestBody {

        private Long adminId;
        private String adminResponse;

        public AdminRequestBody() {
        }

        public Long getAdminId() {
            return adminId;
        }

        public void setAdminId(Long adminId) {
            this.adminId = adminId;
        }

        public String getAdminResponse() {
            return adminResponse;
        }

        public void setAdminResponse(String adminResponse) {
            this.adminResponse = adminResponse;
        }
    }

    // =========================================================
    // CLIENT : CRÉER UNE DEMANDE DE DÉBLOCAGE
    // =========================================================

    @PostMapping("/api/cards/{cardId}/unblock-request")
    public ResponseEntity<?> createRequest(
            @PathVariable Long cardId,
            @RequestBody UnblockRequestBody body) {

        try {

            if (body == null) {
                throw new RuntimeException(
                        "Corps de la requête obligatoire."
                );
            }

            if (body.getUserId() == null) {
                throw new RuntimeException(
                        "Utilisateur obligatoire."
                );
            }

            CardUnblockRequest created =
                    requestService.createRequest(
                            body.getUserId(),
                            cardId,
                            body.getMessage()
                    );

            return ResponseEntity.ok(
                    toResponse(created)
            );

        } catch (RuntimeException e) {

            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body(
                            Map.of(
                                    "message",
                                    e.getMessage() != null
                                            ? e.getMessage()
                                            : "Erreur lors de la création de la demande."
                            )
                    );

        } catch (Exception e) {

            e.printStackTrace();

            return ResponseEntity.internalServerError()
                    .body(
                            Map.of(
                                    "message",
                                    e.getMessage() != null
                                            ? e.getMessage()
                                            : "Erreur interne du serveur."
                            )
                    );
        }
    }

    // =========================================================
    // CLIENT : VOIR SES DEMANDES
    // =========================================================

    @GetMapping("/api/cards/unblock-requests/user/{userId}")
    public ResponseEntity<?> getUserRequests(
            @PathVariable Long userId) {

        try {

            List<CardUnblockRequest> requests =
                    requestService.getRequestsByUser(userId);

            return ResponseEntity.ok(
                    requests.stream()
                            .map(this::toResponse)
                            .toList()
            );

        } catch (RuntimeException e) {

            return ResponseEntity.badRequest()
                    .body(
                            Map.of(
                                    "message",
                                    e.getMessage()
                            )
                    );
        }
    }

    // =========================================================
    // CLIENT : VOIR UNE DEMANDE
    // =========================================================

    @GetMapping(
            "/api/cards/unblock-requests/user/{userId}/{requestId}"
    )
    public ResponseEntity<?> getUserRequest(
            @PathVariable Long userId,
            @PathVariable Long requestId) {

        try {

            CardUnblockRequest request =
                    requestService.getRequestByUser(
                            userId,
                            requestId
                    );

            return ResponseEntity.ok(
                    toResponse(request)
            );

        } catch (RuntimeException e) {

            return ResponseEntity.badRequest()
                    .body(
                            Map.of(
                                    "message",
                                    e.getMessage()
                            )
                    );
        }
    }

    // =========================================================
    // ADMIN : VOIR TOUTES LES DEMANDES
    // =========================================================

    @GetMapping("/api/admin/card-unblock-requests")
    public ResponseEntity<?> getAllRequests() {

        try {

            List<CardUnblockRequest> requests =
                    requestService.getAllRequests();

            return ResponseEntity.ok(
                    requests.stream()
                            .map(this::toResponse)
                            .toList()
            );

        } catch (RuntimeException e) {

            return ResponseEntity.badRequest()
                    .body(
                            Map.of(
                                    "message",
                                    e.getMessage()
                            )
                    );
        }
    }

    // =========================================================
    // ADMIN : APPROUVER
    // =========================================================

    @PostMapping(
            "/api/admin/card-unblock-requests/{requestId}/approve"
    )
    public ResponseEntity<?> approveRequest(
            @PathVariable Long requestId,
            @RequestBody AdminRequestBody body) {

        try {

            if (body == null ||
                    body.getAdminId() == null) {

                throw new RuntimeException(
                        "Administrateur obligatoire."
                );
            }

            CardUnblockRequest approved =
                    requestService.approveRequest(
                            requestId,
                            body.getAdminId(),
                            body.getAdminResponse()
                    );

            return ResponseEntity.ok(
                    Map.of(
                            "message",
                            "Demande approuvée. La carte est maintenant active.",
                            "request",
                            toResponse(approved)
                    )
            );

        } catch (RuntimeException e) {

            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body(
                            Map.of(
                                    "message",
                                    e.getMessage()
                            )
                    );
        }
    }

    // =========================================================
    // ADMIN : REJETER
    // =========================================================

    @PostMapping(
            "/api/admin/card-unblock-requests/{requestId}/reject"
    )
    public ResponseEntity<?> rejectRequest(
            @PathVariable Long requestId,
            @RequestBody AdminRequestBody body) {

        try {

            if (body == null ||
                    body.getAdminId() == null) {

                throw new RuntimeException(
                        "Administrateur obligatoire."
                );
            }

            CardUnblockRequest rejected =
                    requestService.rejectRequest(
                            requestId,
                            body.getAdminId(),
                            body.getAdminResponse()
                    );

            return ResponseEntity.ok(
                    Map.of(
                            "message",
                            "Demande rejetée. La carte reste bloquée.",
                            "request",
                            toResponse(rejected)
                    )
            );

        } catch (RuntimeException e) {

            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body(
                            Map.of(
                                    "message",
                                    e.getMessage()
                            )
                    );
        }
    }

    // =========================================================
    // RESPONSE DTO
    // =========================================================

    private Map<String, Object> toResponse(
            CardUnblockRequest request) {

        Map<String, Object> response =
                new LinkedHashMap<>();

        response.put(
                "requestId",
                request.getId()
        );

        response.put(
                "cardId",
                request.getCard().getId()
        );

        response.put(
                "lastFourDigits",
                request.getCard().getLastFourDigits()
        );

        response.put(
                "cardType",
                request.getCard().getCardType()
        );

        response.put(
                "expiryDate",
                request.getCard().getExpiryDate()
        );

        response.put(
                "cardStatus",
                request.getCard().getStatus()
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
                "status",
                request.getStatus()
        );

        response.put(
                "message",
                request.getMessage()
        );

        response.put(
                "adminResponse",
                request.getAdminResponse()
        );

        response.put(
                "createdAt",
                request.getCreatedAt()
        );

        response.put(
                "processedAt",
                request.getProcessedAt()
        );

        if (request.getProcessedBy() != null) {

            response.put(
                    "processedById",
                    request.getProcessedBy().getId()
            );

            response.put(
                    "processedByUsername",
                    request.getProcessedBy().getUsername()
            );

        } else {

            response.put(
                    "processedById",
                    null
            );

            response.put(
                    "processedByUsername",
                    null
            );
        }

        return response;
    }
}