package com.smartbank.backend.controller;

import com.smartbank.backend.dto.RewardEventResponse;
import com.smartbank.backend.dto.RewardWalletResponse;
import com.smartbank.backend.entity.BillChallenge;
import com.smartbank.backend.entity.RewardWallet;
import com.smartbank.backend.repository.BillChallengeRepository;
import com.smartbank.backend.repository.RewardEventRepository;
import com.smartbank.backend.repository.RewardWalletRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/rewards")
public class RewardController {

    private final RewardWalletRepository rewardWalletRepository;
    private final BillChallengeRepository billChallengeRepository;
    private final RewardEventRepository rewardEventRepository;

    public RewardController(
            RewardWalletRepository rewardWalletRepository,
            BillChallengeRepository billChallengeRepository,
            RewardEventRepository rewardEventRepository) {

        this.rewardWalletRepository = rewardWalletRepository;
        this.billChallengeRepository = billChallengeRepository;
        this.rewardEventRepository = rewardEventRepository;
    }

    @GetMapping("/wallet/{userId}")
    public ResponseEntity<?> getWallet(@PathVariable Long userId) {

        RewardWallet wallet = rewardWalletRepository
                .findByUserId(userId)
                .orElse(null);

        if (wallet == null) {
            return ResponseEntity.ok(
                    new RewardWalletResponse(emptyWallet(userId), null)
            );
        }

        BillChallenge challenge = billChallengeRepository
                .findByUserIdAndStatus(userId, "ACTIVE")
                .orElse(null);

        return ResponseEntity.ok(
                new RewardWalletResponse(wallet, challenge)
        );
    }

    @GetMapping("/history/{userId}")
    public ResponseEntity<List<RewardEventResponse>> getHistory(
            @PathVariable Long userId) {

        List<RewardEventResponse> events = rewardEventRepository
                .findTop20ByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(RewardEventResponse::new)
                .toList();

        return ResponseEntity.ok(events);
    }

    private RewardWallet emptyWallet(Long userId) {
        RewardWallet wallet = new RewardWallet();
        wallet.setPointsBalance(0);
        wallet.setPendingAmountForPoints(BigDecimal.ZERO);
        wallet.setTotalCashback(BigDecimal.ZERO);
        return wallet;
    }
}