package com.smartbank.backend.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartbank.backend.entity.CardUnblockRequest;
import com.smartbank.backend.service.CardUnblockRequestService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
public class CardUnblockRequestController {

    private final CardUnblockRequestService requestService;
    private final ObjectMapper objectMapper;

    public CardUnblockRequestController(
            CardUnblockRequestService requestService,
            ObjectMapper objectMapper) {

        this.requestService = requestService;
        this.objectMapper = objectMapper;
    }

    // =========================================================
    // CLIENT : CRÉER UNE DEMANDE DE DÉBLOCAGE
    // =========================================================

    @PostMapping("/api/cards/{cardId}/unblock-request")
    public ResponseEntity<?> createRequest(
            @PathVariable Long cardId,
            HttpServletRequest httpRequest) {

        try {

            String rawBody =
                    httpRequest.getReader()
                            .lines()
                            .reduce(
                                    "",
                                    (current, line) ->
                                            current + line
                            );

            System.out.println(
                    "[UNBLOCK REQUEST] cardId="
                            + cardId
                            + " body="
                            + rawBody
            );

            if (rawBody == null ||
                    rawBody.trim().isEmpty()) {

                throw new RuntimeException(
                        "Corps de la requête obligatoire."
                );
            }

            JsonNode json =
                    objectMapper.readTree(rawBody);

            if (json == null ||
                    !json.hasNonNull("userId")) {

                throw new RuntimeException(
                        "Utilisateur obligatoire."
                );
            }

            Long userId =
                    json.get("userId").asLong();

            String message = null;

            if (json.hasNonNull("message")) {
                message =
                        json.get("message").asText();
            }

            CardUnblockRequest created =
                    requestService.createRequest(
                            userId,
                            cardId,
                            message
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
            HttpServletRequest httpRequest) {

        try {

            String rawBody =
                    httpRequest.getReader()
                            .lines()
                            .reduce(
                                    "",
                                    (current, line) ->
                                            current + line
                            );

            JsonNode json =
                    objectMapper.readTree(rawBody);

            if (json == null ||
                    !json.hasNonNull("adminId")) {

                throw new RuntimeException(
                        "Administrateur obligatoire."
                );
            }

            Long adminId =
                    json.get("adminId").asLong();

            String adminResponse = null;

            if (json.hasNonNull("adminResponse")) {
                adminResponse =
                        json.get("adminResponse").asText();
            }

            CardUnblockRequest approved =
                    requestService.approveRequest(
                            requestId,
                            adminId,
                            adminResponse
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
    // ADMIN : REJETER
    // =========================================================

    @PostMapping(
            "/api/admin/card-unblock-requests/{requestId}/reject"
    )
    public ResponseEntity<?> rejectRequest(
            @PathVariable Long requestId,
            HttpServletRequest httpRequest) {

        try {

            String rawBody =
                    httpRequest.getReader()
                            .lines()
                            .reduce(
                                    "",
                                    (current, line) ->
                                            current + line
                            );

            JsonNode json =
                    objectMapper.readTree(rawBody);

            if (json == null ||
                    !json.hasNonNull("adminId")) {

                throw new RuntimeException(
                        "Administrateur obligatoire."
                );
            }

            Long adminId =
                    json.get("adminId").asLong();

            String adminResponse = null;

            if (json.hasNonNull("adminResponse")) {
                adminResponse =
                        json.get("adminResponse").asText();
            }

            CardUnblockRequest rejected =
                    requestService.rejectRequest(
                            requestId,
                            adminId,
                            adminResponse
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
    // RESPONSE DTO
    // =========================================================

    private Map<String, Object> toResponse(
            CardUnblockRequest request) {

        Map<String, Object> response =
                new LinkedHashMap<>();

        response.put("requestId", request.getId());

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

            response.put("processedById", null);
            response.put("processedByUsername", null);
        }

        return response;
    }
}