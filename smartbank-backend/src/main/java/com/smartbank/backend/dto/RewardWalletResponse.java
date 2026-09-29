package com.smartbank.backend.dto;

import com.smartbank.backend.entity.BillChallenge;
import com.smartbank.backend.entity.RewardWallet;

import java.math.BigDecimal;

public class RewardWalletResponse {

    private Integer pointsBalance;
    private BigDecimal pendingAmountForPoints;
    private BigDecimal totalCashback;
    private Integer billChallengeCount;
    private Integer billChallengeTarget;

    public RewardWalletResponse(RewardWallet wallet, BillChallenge challenge) {
        this.pointsBalance = wallet.getPointsBalance();
        this.pendingAmountForPoints = wallet.getPendingAmountForPoints();
        this.totalCashback = wallet.getTotalCashback();
        this.billChallengeCount = challenge != null ? challenge.getCountCurrentCycle() : 0;
        this.billChallengeTarget = 5;
    }

    public Integer getPointsBalance() { return pointsBalance; }
    public BigDecimal getPendingAmountForPoints() { return pendingAmountForPoints; }
    public BigDecimal getTotalCashback() { return totalCashback; }
    public Integer getBillChallengeCount() { return billChallengeCount; }
    public Integer getBillChallengeTarget() { return billChallengeTarget; }
}