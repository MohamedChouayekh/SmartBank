package com.smartbank.backend.service;

import com.smartbank.backend.entity.SupportRequest;
import com.smartbank.backend.entity.User;
import com.smartbank.backend.repository.SupportRequestRepository;
import com.smartbank.backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class SupportService {

    private final SupportRequestRepository supportRequestRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public SupportService(
            SupportRequestRepository supportRequestRepository,
            UserRepository userRepository,
            NotificationService notificationService
    ) {
        this.supportRequestRepository = supportRequestRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
    }

    // =========================================================
    // CRÉER UNE DEMANDE DE SUPPORT
    // =========================================================

    @Transactional
    public SupportRequest createRequest(
            Long userId,
            String category,
            String subject,
            String message
    ) {

        if (userId == null) {
            throw new RuntimeException(
                    "Utilisateur obligatoire."
            );
        }

        if (category == null || category.trim().isEmpty()) {
            throw new RuntimeException(
                    "La catégorie est obligatoire."
            );
        }

        if (subject == null || subject.trim().isEmpty()) {
            throw new RuntimeException(
                    "Le sujet est obligatoire."
            );
        }

        if (message == null || message.trim().isEmpty()) {
            throw new RuntimeException(
                    "Le message est obligatoire."
            );
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Utilisateur introuvable."
                        )
                );

        SupportRequest request = new SupportRequest();

        request.setUser(user);
        request.setCategory(category.trim());
        request.setSubject(subject.trim());
        request.setMessage(message.trim());
        request.setStatus("OPEN");

        return supportRequestRepository.save(request);
    }

    // =========================================================
    // DEMANDES D'UN UTILISATEUR
    // =========================================================

    public List<SupportRequest> getUserRequests(
            Long userId
    ) {

        if (userId == null) {
            throw new RuntimeException(
                    "Utilisateur obligatoire."
            );
        }

        return supportRequestRepository
                .findByUserIdOrderByCreatedAtDesc(userId);
    }

    // =========================================================
    // TOUTES LES DEMANDES POUR L'ADMIN
    // =========================================================

    public List<SupportRequest> getAllRequests() {

        return supportRequestRepository
                .findAllByOrderByCreatedAtDesc();
    }

    // =========================================================
    // RÉCUPÉRER UNE DEMANDE
    // =========================================================

    public SupportRequest getRequest(Long requestId) {

        if (requestId == null) {
            throw new RuntimeException(
                    "Demande obligatoire."
            );
        }

        return supportRequestRepository.findById(requestId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Demande de support introuvable."
                        )
                );
    }

    // =========================================================
    // RÉPONDRE À UNE DEMANDE
    // =========================================================

    @Transactional
    public SupportRequest replyToRequest(
            Long requestId,
            String response
    ) {

        if (requestId == null) {
            throw new RuntimeException(
                    "Demande obligatoire."
            );
        }

        if (response == null || response.trim().isEmpty()) {
            throw new RuntimeException(
                    "La réponse est obligatoire."
            );
        }

        SupportRequest request = getRequest(requestId);

        request.setAdminResponse(response.trim());
        request.setStatus("IN_PROGRESS");

        SupportRequest savedRequest =
                supportRequestRepository.save(request);

        notificationService.notifySupport(
                request.getUser().getId(),
                "Réponse du support",
                "Le support SmartBank a répondu à votre demande : "
                        + request.getSubject()
        );

        return savedRequest;
    }

    // =========================================================
    // MODIFIER LE STATUT
    // =========================================================

    @Transactional
    public SupportRequest updateStatus(
            Long requestId,
            String status
    ) {

        if (requestId == null) {
            throw new RuntimeException(
                    "Demande obligatoire."
            );
        }

        if (status == null || status.trim().isEmpty()) {
            throw new RuntimeException(
                    "Le statut est obligatoire."
            );
        }

        String normalizedStatus =
                status.trim().toUpperCase();

        if (!normalizedStatus.equals("OPEN")
                && !normalizedStatus.equals("IN_PROGRESS")
                && !normalizedStatus.equals("RESOLVED")
                && !normalizedStatus.equals("CLOSED")) {

            throw new RuntimeException(
                    "Statut invalide. "
                            + "Valeurs autorisées : OPEN, IN_PROGRESS, "
                            + "RESOLVED, CLOSED."
            );
        }

        SupportRequest request =
                getRequest(requestId);

        request.setStatus(normalizedStatus);

        return supportRequestRepository.save(request);
    }
}