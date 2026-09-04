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

    public BiometricAssociationService(
            BiometricAssociationRepository biometricRepository,
            UserRepository userRepository
    ) {
        this.biometricRepository = biometricRepository;
        this.userRepository = userRepository;
    }

    // =========================================================
    // ACTIVER LA BIOMÉTRIE
    // =========================================================
    //
    // RÈGLE :
    //
    // 1. Si aucun appareil n'est associé :
    //      → on crée l'association.
    //
    // 2. Si l'appareil est associé au MÊME compte :
    //      → on réactive.
    //
    // 3. Si l'appareil est associé à un AUTRE compte
    //    ET que cette association est encore ACTIVE :
    //      → REFUS.
    //
    // 4. Si l'appareil était associé à un autre compte
    //    mais que ce compte a désactivé la biométrie :
    //      → l'appareil est LIBRE.
    //      → le nouveau compte peut prendre l'association.
    //
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

            return biometricRepository.save(
                    association
            );
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

            association.setEnabled(true);
            association.setLastEnabledAt(now);
            association.setDisabledAt(null);

            return biometricRepository.save(
                    association
            );
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
        //
        // L'ancien compte a désactivé sa biométrie.
        // Le téléphone est donc maintenant libre.
        //
        // On réattribue l'association au nouveau compte.
        //
        // =====================================================

        LocalDateTime now =
                LocalDateTime.now();

        association.setUser(user);
        association.setEnabled(true);
        association.setLastEnabledAt(now);
        association.setDisabledAt(null);

        return biometricRepository.save(
                association
        );
    }

    // =========================================================
    // DÉSACTIVER LA BIOMÉTRIE
    // =========================================================
    //
    // La désactivation LIBÈRE le téléphone.
    //
    // Nous conservons la ligne en base pour l'historique,
    // mais enabled passe à false.
    //
    // Ainsi un autre compte peut ensuite utiliser
    // ce même téléphone.
    //
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
        // LIBÉRER LE TÉLÉPHONE
        // =====================================================

        association.setEnabled(false);
        association.setDisabledAt(
                LocalDateTime.now()
        );

        return biometricRepository.save(
                association
        );
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

        // =====================================================
        // AUCUNE ASSOCIATION
        // =====================================================

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

        // =====================================================
        // ASSOCIATION TROUVÉE
        // =====================================================

        response.put(
                "associated",
                true
        );

        response.put(
                "enabled",
                association.isEnabled()
        );

        // IMPORTANT :
        // si enabled = false, le téléphone est LIBRE.
        //
        // On renvoie quand même l'ancien userId pour
        // l'information / historique.
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

        // =====================================================
        // LE COMPTE A-T-IL UNE ASSOCIATION ?
        // =====================================================

        response.put(
                "userId",
                userId
        );

        response.put(
                "associated",
                !associations.isEmpty()
        );

        // =====================================================
        // LE COMPTE A-T-IL UNE BIOMÉTRIE ACTIVE ?
        // =====================================================

        response.put(
                "enabled",
                !enabledAssociations.isEmpty()
        );

        response.put(
                "associationCount",
                associations.size()
        );

        // =====================================================
        // APPAREIL ACTUELLEMENT ACTIF
        // =====================================================

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