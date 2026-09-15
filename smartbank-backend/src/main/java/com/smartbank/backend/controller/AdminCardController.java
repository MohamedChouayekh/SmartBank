package com.smartbank.backend.controller;

import com.smartbank.backend.entity.Card;
import com.smartbank.backend.entity.User;
import com.smartbank.backend.service.AdminCardService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/cards")
public class AdminCardController {

    private final AdminCardService adminCardService;

    public AdminCardController(
            AdminCardService adminCardService) {

        this.adminCardService = adminCardService;
    }

    // =========================================================
    // RÉCUPÉRER TOUS LES UTILISATEURS
    // =========================================================

    @GetMapping("/users")
    public ResponseEntity<?> getAllUsers() {

        try {

            List<User> users =
                    adminCardService.getAllUsers();

            List<Map<String, Object>> response =
                    users.stream()
                            .map(user -> Map.<String, Object>of(
                                    "id",
                                    user.getId(),

                                    "username",
                                    user.getUsername(),

                                    "email",
                                    user.getEmail(),

                                    "fullName",
                                    user.getFullName(),

                                    "phoneNumber",
                                    user.getPhoneNumber(),

                                    "address",
                                    user.getAddress(),

                                    "enabled",
                                    user.isEnabled(),

                                    "createdAt",
                                    user.getCreatedAt()
                            ))
                            .toList();

            return ResponseEntity.ok(response);

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(Map.of(
                            "message",
                            e.getMessage()
                    ));
        }
    }

    // =========================================================
    // RÉCUPÉRER TOUTES LES CARTES
    // =========================================================

    @GetMapping
    public ResponseEntity<?> getAllCards() {

        try {

            List<Card> cards =
                    adminCardService.getAllCards();

            List<Map<String, Object>> response =
                    cards.stream()
                            .map(card -> Map.<String, Object>of(
                                    "id",
                                    card.getId(),

                                    "cardType",
                                    card.getCardType(),

                                    "lastFourDigits",
                                    card.getLastFourDigits(),

                                    "expiryDate",
                                    card.getExpiryDate(),

                                    "status",
                                    card.getStatus(),

                                    "accountNumber",
                                    card.getAccount()
                                            .getAccountNumber(),

                                    "userId",
                                    card.getAccount()
                                            .getUser()
                                            .getId(),

                                    "username",
                                    card.getAccount()
                                            .getUser()
                                            .getUsername(),

                                    "fullName",
                                    card.getAccount()
                                            .getUser()
                                            .getFullName()
                            ))
                            .toList();

            return ResponseEntity.ok(response);

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(Map.of(
                            "message",
                            e.getMessage()
                    ));
        }
    }

    // =========================================================
    // ATTRIBUER UNE CARTE À UN UTILISATEUR
    // =========================================================

    @PostMapping("/assign")
    public ResponseEntity<?> assignCard(
            @RequestBody Map<String, Object> request) {

        try {

            // -------------------------------------------------
            // USER ID
            // -------------------------------------------------

            if (request.get("userId") == null) {

                throw new RuntimeException(
                        "Utilisateur obligatoire."
                );
            }

            Long userId = Long.valueOf(
                    request.get("userId").toString()
            );

            // -------------------------------------------------
            // TYPE DE CARTE
            // -------------------------------------------------

            if (request.get("cardType") == null) {

                throw new RuntimeException(
                        "Le type de carte est obligatoire."
                );
            }

            String cardType =
                    request.get("cardType")
                            .toString();

            // -------------------------------------------------
            // ATTRIBUTION
            // -------------------------------------------------

            Card card =
                    adminCardService.assignCard(
                            userId,
                            cardType
                    );

            // -------------------------------------------------
            // RÉPONSE
            // -------------------------------------------------

            return ResponseEntity.ok(
                    Map.of(
                            "message",
                            "Carte attribuée avec succès.",

                            "id",
                            card.getId(),

                            "cardType",
                            card.getCardType(),

                            "lastFourDigits",
                            card.getLastFourDigits(),

                            "expiryDate",
                            card.getExpiryDate(),

                            "status",
                            card.getStatus(),

                            "accountNumber",
                            card.getAccount()
                                    .getAccountNumber(),

                            "userId",
                            card.getAccount()
                                    .getUser()
                                    .getId(),

                            "username",
                            card.getAccount()
                                    .getUser()
                                    .getUsername(),

                            "fullName",
                            card.getAccount()
                                    .getUser()
                                    .getFullName()
                    )
            );

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(Map.of(
                            "message",
                            e.getMessage()
                    ));
        }
    }
}