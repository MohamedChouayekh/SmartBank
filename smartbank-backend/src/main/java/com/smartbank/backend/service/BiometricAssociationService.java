package com.smartbank.backend.service;

import com.smartbank.backend.entity.BiometricAssociation;
import com.smartbank.backend.entity.User;
import com.smartbank.backend.repository.BiometricAssociationRepository;
import com.smartbank.backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@Transactional
public class BiometricAssociationService {

    private final BiometricAssociationRepository biometricRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public BiometricAssociationService(
            BiometricAssociationRepository biometricRepository,
            UserRepository userRepository,
            NotificationService notificationService
    ) {
        this.biometricRepository =
                biometricRepository;

        this.userRepository =
                userRepository;

        this.notificationService =
                notificationService;
    }

    // =========================================================
    // ACTIVER LA BIOMÉTRIE
    // =========================================================

    public BiometricAssociation enable(
            Long userId,
            String deviceIdentifier
    ) {

        if (deviceIdentifier == null ||
                deviceIdentifier.trim().isEmpty()) {

            throw new IllegalArgumentException(
                    "L'identifiant de l'appareil est obligatoire."
            );
        }

        User user =
                userRepository.findById(userId)
                        .orElseThrow(() ->
                                new IllegalArgumentException(
                                        "Utilisateur introuvable."
                                )
                        );

        Optional<BiometricAssociation> existing =
                biometricRepository.findByDeviceIdentifier(
                        deviceIdentifier
                );

        // =====================================================
        // AUCUNE ASSOCIATION
        // =====================================================

        if (existing.isEmpty()) {

            LocalDateTime now =
                    LocalDateTime.now();

            BiometricAssociation association =
                    new BiometricAssociation();

            association.setUser(user);
            association.setDeviceIdentifier(
                    deviceIdentifier
            );
            association.setEnabled(true);
            association.setAssociatedAt(now);
            association.setLastEnabledAt(now);
            association.setDisabledAt(null);

            BiometricAssociation saved =
                    biometricRepository.save(
                            association
                    );

            notificationService.notifySecurity(
                    userId,
                    "Biométrie activée",
                    "L'authentification biométrique a été activée "
                            + "sur votre appareil."
            );

            return saved;
        }

        BiometricAssociation association =
                existing.get();

        Long currentOwnerId =
                association.getUser().getId();

        // =====================================================
        // MÊME COMPTE
        // =====================================================

        if (currentOwnerId.equals(userId)) {

            LocalDateTime now =
                    LocalDateTime.now();

            boolean wasEnabled =
                    association.isEnabled();

            association.setEnabled(true);
            association.setLastEnabledAt(now);
            association.setDisabledAt(null);

            BiometricAssociation saved =
                    biometricRepository.save(
                            association
                    );

            // Notification uniquement lorsqu'elle
            // était réellement désactivée avant.
            if (!wasEnabled) {

                notificationService.notifySecurity(
                        userId,
                        "Biométrie activée",
                        "L'authentification biométrique a été "
                                + "réactivée sur votre appareil."
                );
            }

            return saved;
        }

        // =====================================================
        // AUTRE COMPTE + ASSOCIATION ACTIVE
        // =====================================================

        if (association.isEnabled()) {

            throw new IllegalStateException(
                    "La biométrie de cet appareil est actuellement "
                            + "utilisée par un autre compte."
            );
        }

        // =====================================================
        // AUTRE COMPTE MAIS ASSOCIATION DÉSACTIVÉE
        // =====================================================

        LocalDateTime now =
                LocalDateTime.now();

        association.setUser(user);
        association.setEnabled(true);
        association.setLastEnabledAt(now);
        association.setDisabledAt(null);

        BiometricAssociation saved =
                biometricRepository.save(
                        association
                );

        notificationService.notifySecurity(
                userId,
                "Biométrie activée",
                "L'authentification biométrique a été activée "
                        + "sur votre appareil."
        );

        return saved;
    }

    // =========================================================
    // DÉSACTIVER LA BIOMÉTRIE
    // =========================================================

    public BiometricAssociation disable(
            Long userId,
            String deviceIdentifier
    ) {

        if (deviceIdentifier == null ||
                deviceIdentifier.trim().isEmpty()) {

            throw new IllegalArgumentException(
                    "L'identifiant de l'appareil est obligatoire."
            );
        }

        BiometricAssociation association =
                biometricRepository
                        .findByDeviceIdentifier(
                                deviceIdentifier
                        )
                        .orElseThrow(() ->
                                new IllegalArgumentException(
                                        "Aucune association biométrique "
                                                + "pour cet appareil."
                                )
                        );

        // =====================================================
        // VÉRIFIER LE PROPRIÉTAIRE
        // =====================================================

        if (!association.getUser().getId().equals(userId)) {

            throw new IllegalStateException(
                    "Seul le compte actuellement propriétaire "
                            + "de la biométrie peut la désactiver."
            );
        }

        // =====================================================
        // DÉJÀ DÉSACTIVÉE
        // =====================================================

        if (!association.isEnabled()) {
            return association;
        }

        // =====================================================
        // LIBÉRER LE TÉLÉPHONE
        // =====================================================

        association.setEnabled(false);
        association.setDisabledAt(
                LocalDateTime.now()
        );

        BiometricAssociation saved =
                biometricRepository.save(
                        association
                );

        notificationService.notifySecurity(
                userId,
                "Biométrie désactivée",
                "L'authentification biométrique a été désactivée "
                        + "sur votre appareil."
        );

        return saved;
    }

    // =========================================================
    // ÉTAT PAR APPAREIL
    // =========================================================

    @Transactional(readOnly = true)
    public Map<String, Object> getByDevice(
            String deviceIdentifier
    ) {

        Map<String, Object> response =
                new HashMap<>();

        Optional<BiometricAssociation> optional =
                biometricRepository
                        .findByDeviceIdentifier(
                                deviceIdentifier
                        );

        if (optional.isEmpty()) {

            response.put(
                    "associated",
                    false
            );

            response.put(
                    "enabled",
                    false
            );

            response.put(
                    "ownerUserId",
                    null
            );

            response.put(
                    "deviceIdentifier",
                    deviceIdentifier
            );

            return response;
        }

        BiometricAssociation association =
                optional.get();

        response.put(
                "associated",
                true
        );

        response.put(
                "enabled",
                association.isEnabled()
        );

        response.put(
                "ownerUserId",
                association.getUser().getId()
        );

        response.put(
                "deviceIdentifier",
                association.getDeviceIdentifier()
        );

        response.put(
                "associatedAt",
                association.getAssociatedAt()
        );

        response.put(
                "lastEnabledAt",
                association.getLastEnabledAt()
        );

        response.put(
                "disabledAt",
                association.getDisabledAt()
        );

        return response;
    }

    // =========================================================
    // ÉTAT PAR COMPTE
    // =========================================================

    @Transactional(readOnly = true)
    public Map<String, Object> getByUser(
            Long userId
    ) {

        Map<String, Object> response =
                new HashMap<>();

        List<BiometricAssociation> associations =
                biometricRepository
                        .findByUser_IdOrderByAssociatedAtDesc(
                                userId
                        );

        List<BiometricAssociation> enabledAssociations =
                biometricRepository
                        .findByUser_IdAndEnabledTrueOrderByLastEnabledAtDesc(
                                userId
                        );

        response.put(
                "userId",
                userId
        );

        response.put(
                "associated",
                !associations.isEmpty()
        );

        response.put(
                "enabled",
                !enabledAssociations.isEmpty()
        );

        response.put(
                "associationCount",
                associations.size()
        );

        if (!enabledAssociations.isEmpty()) {

            BiometricAssociation active =
                    enabledAssociations.get(0);

            response.put(
                    "deviceIdentifier",
                    active.getDeviceIdentifier()
            );

            response.put(
                    "lastEnabledAt",
                    active.getLastEnabledAt()
            );

        } else {

            response.put(
                    "deviceIdentifier",
                    null
            );

            response.put(
                    "lastEnabledAt",
                    null
            );
        }

        return response;
    }
}