package com.smartbank.backend.repository;

import com.smartbank.backend.entity.SupportRequest;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SupportRequestRepository
        extends JpaRepository<SupportRequest, Long> {

    // =========================================================
    // DEMANDES D'UN UTILISATEUR
    // =========================================================

    List<SupportRequest> findByUserIdOrderByCreatedAtDesc(
            Long userId
    );

    // =========================================================
    // TOUTES LES DEMANDES POUR L'ADMIN
    // =========================================================

    List<SupportRequest> findAllByOrderByCreatedAtDesc();

    // =========================================================
    // DEMANDES PAR STATUT
    // =========================================================

    List<SupportRequest> findByStatusOrderByCreatedAtDesc(
            String status
    );
}