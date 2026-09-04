package com.smartbank.backend.repository;

import com.smartbank.backend.entity.Account;
import com.smartbank.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AccountRepository
        extends JpaRepository<Account, Long> {

    // =========================================================
    // RECHERCHE PAR NUMÉRO DE COMPTE
    // =========================================================

    Optional<Account> findByAccountNumber(
            String accountNumber
    );

    // =========================================================
    // RECHERCHE PAR UTILISATEUR
    // =========================================================

    List<Account> findByUser(User user);

    // =========================================================
    // RECHERCHE PAR ID UTILISATEUR
    // =========================================================

    List<Account> findByUserId(Long userId);

    // =========================================================
    // VÉRIFIER QU'UN COMPTE APPARTIENT À UN UTILISATEUR
    // =========================================================

    Optional<Account> findByAccountNumberAndUserId(
            String accountNumber,
            Long userId
    );
}