package com.smartbank.backend.repository;

import com.smartbank.backend.entity.BillChallenge;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface BillChallengeRepository extends JpaRepository<BillChallenge, Long> {
    Optional<BillChallenge> findByUserIdAndStatus(Long userId, String status);
}