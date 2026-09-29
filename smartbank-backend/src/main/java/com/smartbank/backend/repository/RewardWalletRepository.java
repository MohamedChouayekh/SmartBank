package com.smartbank.backend.repository;

import com.smartbank.backend.entity.RewardWallet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface RewardWalletRepository extends JpaRepository<RewardWallet, Long> {
    Optional<RewardWallet> findByUserId(Long userId);
}