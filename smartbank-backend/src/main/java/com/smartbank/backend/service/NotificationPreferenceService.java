package com.smartbank.backend.service;

import com.smartbank.backend.dto.NotificationPreferenceRequest;
import com.smartbank.backend.dto.NotificationPreferenceResponse;
import com.smartbank.backend.entity.NotificationPreference;
import com.smartbank.backend.entity.User;
import com.smartbank.backend.repository.NotificationPreferenceRepository;
import com.smartbank.backend.repository.UserRepository;
import org.springframework.stereotype.Service;

@Service
public class NotificationPreferenceService {

    private final NotificationPreferenceRepository preferenceRepository;
    private final UserRepository userRepository;

    // =========================================================
    // CONSTRUCTEUR
    // =========================================================

    public NotificationPreferenceService(
            NotificationPreferenceRepository preferenceRepository,
            UserRepository userRepository) {

        this.preferenceRepository = preferenceRepository;
        this.userRepository = userRepository;
    }

    // =========================================================
    // RÉCUPÉRER LES PRÉFÉRENCES
    // =========================================================

    public NotificationPreferenceResponse getPreferences(
            Long userId) {

        NotificationPreference preference =
                preferenceRepository
                        .findByUserId(userId)
                        .orElseGet(() ->
                                createDefaultPreferences(userId)
                        );

        return toResponse(preference);
    }

    // =========================================================
    // CRÉER LES PRÉFÉRENCES PAR DÉFAUT
    // =========================================================

    private NotificationPreference createDefaultPreferences(
            Long userId) {

        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Utilisateur introuvable avec id : "
                                        + userId
                        )
                );

        NotificationPreference preference =
                new NotificationPreference();

        preference.setUser(user);

        // ---------------------------------------------------------
        // VALEURS PAR DÉFAUT
        // ---------------------------------------------------------

        preference.setGeneralNotifications(true);
        preference.setTransfers(true);
        preference.setCardPayments(true);
        preference.setWithdrawals(true);
        preference.setSecurityAlerts(true);
        preference.setPromotions(false);

        return preferenceRepository.save(preference);
    }

    // =========================================================
    // MODIFIER LES PRÉFÉRENCES
    // =========================================================

    public NotificationPreferenceResponse updatePreferences(
            Long userId,
            NotificationPreferenceRequest request) {

        NotificationPreference existing =
                preferenceRepository
                        .findByUserId(userId)
                        .orElseGet(() ->
                                createDefaultPreferences(userId)
                        );

        existing.setGeneralNotifications(
                request.isGeneralNotifications()
        );

        existing.setTransfers(
                request.isTransfers()
        );

        existing.setCardPayments(
                request.isCardPayments()
        );

        existing.setWithdrawals(
                request.isWithdrawals()
        );

        existing.setSecurityAlerts(
                request.isSecurityAlerts()
        );

        existing.setPromotions(
                request.isPromotions()
        );

        NotificationPreference saved =
                preferenceRepository.save(existing);

        return toResponse(saved);
    }

    // =========================================================
    // CONVERSION ENTITY → DTO
    // =========================================================

    private NotificationPreferenceResponse toResponse(
            NotificationPreference preference) {

        return new NotificationPreferenceResponse(
                preference.isGeneralNotifications(),
                preference.isTransfers(),
                preference.isCardPayments(),
                preference.isWithdrawals(),
                preference.isSecurityAlerts(),
                preference.isPromotions()
        );
    }

    // =========================================================
    // VÉRIFIER SI LES VIREMENTS SONT ACTIVÉS
    // =========================================================

    public boolean areTransferNotificationsEnabled(
            Long userId) {

        NotificationPreference preference =
                preferenceRepository
                        .findByUserId(userId)
                        .orElseGet(() ->
                                createDefaultPreferences(userId)
                        );

        return preference.isGeneralNotifications()
                && preference.isTransfers();
    }

    // =========================================================
    // VÉRIFIER LES NOTIFICATIONS GÉNÉRALES
    // =========================================================

    public boolean areGeneralNotificationsEnabled(
            Long userId) {

        NotificationPreference preference =
                preferenceRepository
                        .findByUserId(userId)
                        .orElseGet(() ->
                                createDefaultPreferences(userId)
                        );

        return preference.isGeneralNotifications();
    }
}