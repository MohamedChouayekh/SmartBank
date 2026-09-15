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
    // RÉCUPÉRER TOUS LES UTILISATEURS
    // =========================================================

    public List<User> getAllUsers() {

        return userRepository.findAll();
    }

    // =========================================================
    // RÉCUPÉRER TOUTES LES CARTES
    // =========================================================

    public List<Card> getAllCards() {

        return cardRepository.findAll();
    }

    // =========================================================
    // ATTRIBUER UNE NOUVELLE CARTE À UN UTILISATEUR
    // =========================================================

    @Transactional
    public Card assignCard(
            Long userId,
            String cardType) {

        // -----------------------------------------------------
        // VÉRIFIER L'UTILISATEUR
        // -----------------------------------------------------

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

        // -----------------------------------------------------
        // VÉRIFIER QUE L'UTILISATEUR EST ACTIF
        // -----------------------------------------------------

        if (!user.isEnabled()) {
            throw new RuntimeException(
                    "Cet utilisateur est désactivé."
            );
        }

        // -----------------------------------------------------
        // VÉRIFIER LE TYPE DE CARTE
        // -----------------------------------------------------

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

        // -----------------------------------------------------
        // UTILISER LA LOGIQUE EXISTANTE
        // -----------------------------------------------------

        return cardService.assignCard(
                userId,
                normalizedCardType
        );
    }
}