package com.smartbank.backend.controller;

import com.smartbank.backend.entity.Card;
import com.smartbank.backend.service.CardService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/cards")
public class CardController {

    private final CardService cardService;

    public CardController(CardService cardService) {
        this.cardService = cardService;
    }

    // =========================================================
    // RÉCUPÉRER LES CARTES D'UN UTILISATEUR
    // =========================================================

    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getCardsByUser(
            @PathVariable Long userId) {

        try {

            List<Card> cards =
                    cardService.getCardsByUser(userId);

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
                                            .getAccountNumber()
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
    // AJOUTER UNE CARTE AVEC INFORMATIONS FOURNIES
    // =========================================================
    //
    // Conservé pour ne pas casser l'existant.
    // =========================================================

    @PostMapping
    public ResponseEntity<?> addCard(
            @RequestBody Map<String, Object> request) {

        try {

            Long userId = Long.valueOf(
                    request.get("userId").toString()
            );

            String cardType =
                    request.get("cardType").toString();

            String lastFourDigits =
                    request.get("lastFourDigits").toString();

            String expiryDate =
                    request.get("expiryDate").toString();

            Card card = cardService.addCard(
                    userId,
                    cardType,
                    lastFourDigits,
                    expiryDate
            );

            return ResponseEntity.ok(
                    Map.of(
                            "message",
                            "Carte ajoutée avec succès.",

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
                                    .getAccountNumber()
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

    // =========================================================
    // ATTRIBUER UNE NOUVELLE CARTE
    // =========================================================
    //
    // La banque fournit :
    // - userId
    // - cardType
    //
    // Le backend génère automatiquement :
    // - les 4 derniers chiffres
    // - la date d'expiration
    // - ACTIVE
    //
    // L'ancienne carte reste inchangée.
    // =========================================================

    @PostMapping("/assign")
    public ResponseEntity<?> assignCard(
            @RequestBody Map<String, Object> request) {

        try {

            if (request.get("userId") == null) {
                throw new RuntimeException(
                        "Utilisateur obligatoire."
                );
            }

            if (request.get("cardType") == null) {
                throw new RuntimeException(
                        "Le type de carte est obligatoire."
                );
            }

            Long userId = Long.valueOf(
                    request.get("userId").toString()
            );

            String cardType =
                    request.get("cardType").toString();

            Card card = cardService.assignCard(
                    userId,
                    cardType
            );

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
                                    .getAccountNumber()
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

    // =========================================================
    // RETRAIT AVEC CARTE
    // =========================================================

    @PostMapping("/{cardId}/withdraw")
    public ResponseEntity<?> withdrawWithCard(
            @PathVariable Long cardId,
            @RequestBody Map<String, Object> request) {

        try {

            Long userId = Long.valueOf(
                    request.get("userId").toString()
            );

            BigDecimal amount = new BigDecimal(
                    request.get("amount").toString()
            );

            BigDecimal newBalance =
                    cardService.withdrawWithCard(
                            userId,
                            cardId,
                            amount
                    );

            return ResponseEntity.ok(
                    Map.of(
                            "message",
                            "Retrait effectué avec succès.",

                            "amount",
                            amount,

                            "newBalance",
                            newBalance
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

    // =========================================================
    // BLOQUER UNE CARTE
    // =========================================================

    @PostMapping("/{cardId}/block")
    public ResponseEntity<?> blockCard(
            @PathVariable Long cardId,
            @RequestBody Map<String, Object> request) {

        try {

            Long userId = Long.valueOf(
                    request.get("userId").toString()
            );

            Card card = cardService.blockCard(
                    userId,
                    cardId
            );

            return ResponseEntity.ok(
                    Map.of(
                            "message",
                            "Carte bloquée avec succès.",

                            "id",
                            card.getId(),

                            "status",
                            card.getStatus()
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

    // =========================================================
    // DÉBLOQUER UNE CARTE
    // =========================================================

    @PostMapping("/{cardId}/unblock")
    public ResponseEntity<?> unblockCard(
            @PathVariable Long cardId,
            @RequestBody Map<String, Object> request) {

        try {

            Long userId = Long.valueOf(
                    request.get("userId").toString()
            );

            Card card = cardService.unblockCard(
                    userId,
                    cardId
            );

            return ResponseEntity.ok(
                    Map.of(
                            "message",
                            "Carte débloquée avec succès.",

                            "id",
                            card.getId(),

                            "status",
                            card.getStatus()
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