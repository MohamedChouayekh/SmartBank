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

    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getCardsByUser(
            @PathVariable Long userId) {

        try {
            List<Card> cards = cardService.getCardsByUser(userId);

            List<Map<String, Object>> response = cards.stream()
                    .map(card -> Map.<String, Object>of(
                            "id", card.getId(),
                            "cardType", card.getCardType(),
                            "lastFourDigits", card.getLastFourDigits(),
                            "expiryDate", card.getExpiryDate(),
                            "status", card.getStatus(),
                            "accountNumber",
                            card.getAccount().getAccountNumber()
                    ))
                    .toList();

            return ResponseEntity.ok(response);

        } catch (RuntimeException e) {
            return ResponseEntity
                    .badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

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
                            "message", "Carte ajoutée avec succès.",
                            "id", card.getId(),
                            "cardType", card.getCardType(),
                            "lastFourDigits",
                            card.getLastFourDigits(),
                            "expiryDate",
                            card.getExpiryDate(),
                            "status",
                            card.getStatus(),
                            "accountNumber",
                            card.getAccount().getAccountNumber()
                    )
            );

        } catch (RuntimeException e) {
            return ResponseEntity
                    .badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

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
}