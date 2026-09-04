package com.smartbank.backend.repository;

import com.smartbank.backend.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TransactionRepository
        extends JpaRepository<Transaction, Long> {

    // =========================================================
    // TRANSACTIONS D'UN COMPTE
    // =========================================================

    List<Transaction> findByAccountIdOrderByCreatedAtDesc(
            Long accountId
    );

    // =========================================================
    // TRANSACTIONS DE TOUS LES COMPTES D'UN UTILISATEUR
    // =========================================================
    //
    // Transaction
    //     -> Account
    //          -> User
    //
    // On récupère toutes les transactions liées
    // aux comptes appartenant à cet utilisateur.
    // =========================================================

    List<Transaction> findByAccount_User_IdOrderByCreatedAtDesc(
            Long userId
    );
}