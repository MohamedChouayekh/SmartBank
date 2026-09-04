package com.smartbank.backend.repository;

import com.smartbank.backend.entity.BiometricAssociation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface BiometricAssociationRepository
        extends JpaRepository<BiometricAssociation, Long> {

    Optional<BiometricAssociation> findByDeviceIdentifier(
            String deviceIdentifier
    );

    Optional<BiometricAssociation> findByUser_IdAndDeviceIdentifier(
            Long userId,
            String deviceIdentifier
    );

    List<BiometricAssociation> findByUser_IdAndEnabledTrueOrderByLastEnabledAtDesc(
            Long userId
    );

    List<BiometricAssociation> findByUser_IdOrderByAssociatedAtDesc(
            Long userId
    );

    // =========================================================
    // SUPPRIMER LES ASSOCIATIONS BIOMÉTRIQUES D'UN COMPTE
    // =========================================================

    void deleteByUser_Id(Long userId);
}