package com.smartbank.backend.service;

import com.smartbank.backend.entity.Card;
import com.smartbank.backend.entity.CardUnblockRequest;
import com.smartbank.backend.entity.User;
import com.smartbank.backend.repository.CardRepository;
import com.smartbank.backend.repository.CardUnblockRequestRepository;
import com.smartbank.backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class CardUnblockRequestService {

    private final CardUnblockRequestRepository requestRepository;
    private final CardRepository cardRepository;
    private final UserRepository userRepository;

    public CardUnblockRequestService(
            CardUnblockRequestRepository requestRepository,
            CardRepository cardRepository,
            UserRepository userRepository) {

        this.requestRepository = requestRepository;
        this.cardRepository = cardRepository;
        this.userRepository = userRepository;
    }

    // =========================================================
    // CLIENT : ENVOYER UNE DEMANDE DE DÉBLOCAGE
    // =========================================================

    @Transactional
    public CardUnblockRequest createRequest(
            Long userId,
            Long cardId,
            String message) {

        if (userId == null) {
            throw new RuntimeException(
                    "Utilisateur obligatoire."
            );
        }

        if (cardId == null) {
            throw new RuntimeException(
                    "Carte obligatoire."
            );
        }

        User user = userRepository
                .findById(userId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Utilisateur introuvable."
                        )
                );

        Card card = cardRepository
                .findByIdAndAccount_User_Id(
                        cardId,
                        userId
                )
                .orElseThrow(() ->
                        new RuntimeException(
                                "Carte introuvable ou non autorisée."
                        )
                );

        // -----------------------------------------------------
        // La carte doit être bloquée
        // -----------------------------------------------------

        if (!"BLOCKED".equalsIgnoreCase(
                card.getStatus())) {

            throw new RuntimeException(
                    "Une demande de déblocage est uniquement possible pour une carte bloquée."
            );
        }

        // -----------------------------------------------------
        // Vérifier qu'une demande n'est pas déjà en attente
        // -----------------------------------------------------

        if (requestRepository
                .findFirstByCard_IdAndStatus(
                        cardId,
                        "PENDING"
                )
                .isPresent()) {

            throw new RuntimeException(
                    "Une demande de déblocage est déjà en cours pour cette carte."
            );
        }

        // -----------------------------------------------------
        // Créer la demande
        // -----------------------------------------------------

        CardUnblockRequest request =
                new CardUnblockRequest();

        request.setCard(card);
        request.setUser(user);
        request.setStatus("PENDING");

        if (message != null &&
                !message.trim().isEmpty()) {

            request.setMessage(
                    message.trim()
            );
        }

        return requestRepository.save(request);
    }

    // =========================================================
    // CLIENT : VOIR SES DEMANDES
    // =========================================================

    public List<CardUnblockRequest> getRequestsByUser(
            Long userId) {

        if (userId == null) {
            throw new RuntimeException(
                    "Utilisateur obligatoire."
            );
        }

        if (!userRepository.existsById(userId)) {
            throw new RuntimeException(
                    "Utilisateur introuvable."
            );
        }

        return requestRepository
                .findByUser_IdOrderByCreatedAtDesc(
                        userId
                );
    }

    // =========================================================
    // CLIENT : VOIR UNE DEMANDE
    // =========================================================

    public CardUnblockRequest getRequestByUser(
            Long userId,
            Long requestId) {

        if (userId == null ||
                requestId == null) {

            throw new RuntimeException(
                    "Utilisateur et demande obligatoires."
            );
        }

        return requestRepository
                .findByIdAndUser_Id(
                        requestId,
                        userId
                )
                .orElseThrow(() ->
                        new RuntimeException(
                                "Demande introuvable ou non autorisée."
                        )
                );
    }

    // =========================================================
    // ADMIN : VOIR TOUTES LES DEMANDES
    // =========================================================

    public List<CardUnblockRequest> getAllRequests() {

        return requestRepository
                .findAllByOrderByCreatedAtDesc();
    }

    // =========================================================
    // ADMIN : ACCEPTER UNE DEMANDE
    // =========================================================

    @Transactional
    public CardUnblockRequest approveRequest(
            Long requestId,
            Long adminId,
            String adminResponse) {

        CardUnblockRequest request =
                getRequestForProcessing(requestId);

        User admin = getAdmin(adminId);

        if (!"PENDING".equalsIgnoreCase(
                request.getStatus())) {

            throw new RuntimeException(
                    "Cette demande a déjà été traitée."
            );
        }

        Card card = request.getCard();

        if (card == null) {
            throw new RuntimeException(
                    "La carte associée à la demande est introuvable."
            );
        }

        if ("EXPIRED".equalsIgnoreCase(
                card.getStatus())) {

            throw new RuntimeException(
                    "Cette carte est expirée et ne peut pas être débloquée."
            );
        }

        if (!"BLOCKED".equalsIgnoreCase(
                card.getStatus())) {

            throw new RuntimeException(
                    "La carte n'est plus bloquée."
            );
        }

        // -----------------------------------------------------
        // Déblocage après vérification de la banque
        // -----------------------------------------------------

        card.setStatus("ACTIVE");

        cardRepository.save(card);

        request.setStatus("APPROVED");
        request.setProcessedBy(admin);
        request.setProcessedAt(
                LocalDateTime.now()
        );

        if (adminResponse != null &&
                !adminResponse.trim().isEmpty()) {

            request.setAdminResponse(
                    adminResponse.trim()
            );
        }

        return requestRepository.save(request);
    }

    // =========================================================
    // ADMIN : REFUSER UNE DEMANDE
    // =========================================================

    @Transactional
    public CardUnblockRequest rejectRequest(
            Long requestId,
            Long adminId,
            String adminResponse) {

        CardUnblockRequest request =
                getRequestForProcessing(requestId);

        User admin = getAdmin(adminId);

        if (!"PENDING".equalsIgnoreCase(
                request.getStatus())) {

            throw new RuntimeException(
                    "Cette demande a déjà été traitée."
            );
        }

        Card card = request.getCard();

        if (card == null) {
            throw new RuntimeException(
                    "La carte associée à la demande est introuvable."
            );
        }

        // -----------------------------------------------------
        // La carte reste bloquée
        // -----------------------------------------------------

        if (!"BLOCKED".equalsIgnoreCase(
                card.getStatus())) {

            throw new RuntimeException(
                    "La carte n'est plus bloquée."
            );
        }

        request.setStatus("REJECTED");
        request.setProcessedBy(admin);
        request.setProcessedAt(
                LocalDateTime.now()
        );

        if (adminResponse != null &&
                !adminResponse.trim().isEmpty()) {

            request.setAdminResponse(
                    adminResponse.trim()
            );
        }

        return requestRepository.save(request);
    }

    // =========================================================
    // RECHERCHE INTERNE
    // =========================================================

    private CardUnblockRequest getRequestForProcessing(
            Long requestId) {

        if (requestId == null) {
            throw new RuntimeException(
                    "Demande obligatoire."
            );
        }

        return requestRepository
                .findById(requestId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Demande introuvable."
                        )
                );
    }

    // =========================================================
    // VÉRIFICATION ADMIN
    // =========================================================

    private User getAdmin(Long adminId) {

        if (adminId == null) {
            throw new RuntimeException(
                    "Administrateur obligatoire."
            );
        }

        User admin = userRepository
                .findById(adminId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Administrateur introuvable."
                        )
                );

        if (!admin.isEnabled()) {
            throw new RuntimeException(
                    "Administrateur désactivé."
            );
        }

        if (!"BANK_ADMIN".equalsIgnoreCase(
                admin.getRole())) {

            throw new RuntimeException(
                    "Accès réservé à un administrateur bancaire."
            );
        }

        return admin;
    }
}