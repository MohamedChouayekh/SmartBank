package com.smartbank.backend.service;

import com.smartbank.backend.entity.User;
import com.smartbank.backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class PromotionService {

    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public PromotionService(
            UserRepository userRepository,
            NotificationService notificationService) {

        this.userRepository = userRepository;
        this.notificationService = notificationService;
    }

    // =========================================================
    // ENVOYER UNE PROMOTION À UN UTILISATEUR
    // =========================================================

    @Transactional
    public void sendToUser(
            Long userId,
            String title,
            String message) {

        validatePromotion(title, message);

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

        if (!"CLIENT".equalsIgnoreCase(
                user.getRole())) {

            throw new RuntimeException(
                    "Une promotion peut uniquement être envoyée à un client."
            );
        }

        notificationService.notifyPromotion(
                user.getId(),
                title.trim(),
                message.trim()
        );
    }

    // =========================================================
    // ENVOYER UNE PROMOTION À TOUS LES CLIENTS
    // =========================================================

    @Transactional
    public int sendToAllClients(
            String title,
            String message) {

        validatePromotion(title, message);

        List<User> users =
                userRepository.findAll();

        int sentCount = 0;

        for (User user : users) {

            if (!user.isEnabled()) {
                continue;
            }

            if (!"CLIENT".equalsIgnoreCase(
                    user.getRole())) {
                continue;
            }

            notificationService.notifyPromotion(
                    user.getId(),
                    title.trim(),
                    message.trim()
            );

            sentCount++;
        }

        return sentCount;
    }

    // =========================================================
    // VALIDATION
    // =========================================================

    private void validatePromotion(
            String title,
            String message) {

        if (title == null ||
                title.trim().isEmpty()) {

            throw new RuntimeException(
                    "Le titre de la promotion est obligatoire."
            );
        }

        if (message == null ||
                message.trim().isEmpty()) {

            throw new RuntimeException(
                    "Le message de la promotion est obligatoire."
            );
        }

        if (title.trim().length() > 150) {

            throw new RuntimeException(
                    "Le titre de la promotion ne doit pas dépasser 150 caractères."
            );
        }

        if (message.trim().length() > 2000) {

            throw new RuntimeException(
                    "Le message de la promotion ne doit pas dépasser 2000 caractères."
            );
        }
    }
}