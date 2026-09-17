package com.smartbank.backend.service;

import com.smartbank.backend.entity.Card;
import com.smartbank.backend.entity.User;
import com.smartbank.backend.repository.CardRepository;
import com.smartbank.backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class AdminCardService {

    private final UserRepository userRepository;
    private final CardRepository cardRepository;
    private final CardService cardService;

    public AdminCardService(
            UserRepository userRepository,
            CardRepository cardRepository,
            CardService cardService) {

        this.userRepository = userRepository;
        this.cardRepository = cardRepository;
        this.cardService = cardService;
    }

    // =========================================================
    // UTILISATEURS
    // =========================================================

    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    // =========================================================
    // CARTES
    // =========================================================

    public List<Card> getAllCards() {
        return cardRepository.findAll();
    }

    // =========================================================
    // ATTRIBUER UNE CARTE
    // =========================================================

    @Transactional
    public Card assignCard(
            Long userId,
            String cardType) {

        if (userId == null) {
            throw new RuntimeException(
                    "Utilisateur obligatoire."
            );
        }

        User user = userRepository
                .findById(userId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Utilisateur introuvable."
                        )
                );

        if (!user.isEnabled()) {
            throw new RuntimeException(
                    "Cet utilisateur est désactivé."
            );
        }

        if (cardType == null ||
                cardType.trim().isEmpty()) {

            throw new RuntimeException(
                    "Le type de carte est obligatoire."
            );
        }

        String normalizedCardType =
                cardType.trim().toUpperCase();

        if (!normalizedCardType.equals("VISA") &&
                !normalizedCardType.equals("MASTERCARD")) {

            throw new RuntimeException(
                    "Type de carte invalide. Utilisez VISA ou MASTERCARD."
            );
        }

        return cardService.assignCard(
                userId,
                normalizedCardType
        );
    }

    // =========================================================
    // BLOQUER UNE CARTE DEPUIS L'ADMIN
    // =========================================================

    @Transactional
    public Card blockCard(
            Long cardId) {

        if (cardId == null) {
            throw new RuntimeException(
                    "Carte obligatoire."
            );
        }

        Card card = cardRepository
                .findById(cardId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Carte introuvable."
                        )
                );

        if ("EXPIRED".equalsIgnoreCase(
                card.getStatus())) {

            throw new RuntimeException(
                    "Cette carte est expirée."
            );
        }

        if ("BLOCKED".equalsIgnoreCase(
                card.getStatus())) {

            throw new RuntimeException(
                    "Cette carte est déjà bloquée."
            );
        }

        card.setStatus("BLOCKED");

        return cardRepository.save(card);
    }

    // =========================================================
    // DÉBLOQUER UNE CARTE DEPUIS L'ADMIN
    // =========================================================

    @Transactional
    public Card unblockCard(
            Long cardId) {

        if (cardId == null) {
            throw new RuntimeException(
                    "Carte obligatoire."
            );
        }

        Card card = cardRepository
                .findById(cardId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Carte introuvable."
                        )
                );

        if ("EXPIRED".equalsIgnoreCase(
                card.getStatus())) {

            throw new RuntimeException(
                    "Cette carte est expirée et ne peut pas être débloquée."
            );
        }

        if ("ACTIVE".equalsIgnoreCase(
                card.getStatus())) {

            throw new RuntimeException(
                    "Cette carte est déjà active."
            );
        }

        card.setStatus("ACTIVE");

        return cardRepository.save(card);
    }
}