package com.smartbank.backend.repository;

import com.smartbank.backend.entity.CardPaymentChallenge;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CardPaymentChallengeRepository extends JpaRepository<CardPaymentChallenge, Long> {
    Optional<CardPaymentChallenge> findByUserIdAndStatus(Long userId, String status);
}