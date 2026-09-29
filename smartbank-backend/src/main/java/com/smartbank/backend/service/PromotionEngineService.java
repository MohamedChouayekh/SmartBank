package com.smartbank.backend.service;

import com.smartbank.backend.entity.Account;
import com.smartbank.backend.entity.BillChallenge;
import com.smartbank.backend.entity.RewardEvent;
import com.smartbank.backend.entity.RewardWallet;
import com.smartbank.backend.entity.User;
import com.smartbank.backend.repository.AccountRepository;
import com.smartbank.backend.repository.BillChallengeRepository;
import com.smartbank.backend.repository.RewardEventRepository;
import com.smartbank.backend.repository.RewardWalletRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;

@Service
public class PromotionEngineService {

    private static final BigDecimal POINTS_THRESHOLD =
            new BigDecimal("10.000");

    private static final int BILL_PAYMENT_POINTS = 20;

    private static final int BILL_CHALLENGE_TARGET = 5;

    private static final BigDecimal BILL_CHALLENGE_REWARD =
            new BigDecimal("5.000");

    private final RewardWalletRepository rewardWalletRepository;
    private final BillChallengeRepository billChallengeRepository;
    private final AccountRepository accountRepository;
    private final NotificationService notificationService;
    private final RewardEventRepository rewardEventRepository;

    public PromotionEngineService(
            RewardWalletRepository rewardWalletRepository,
            BillChallengeRepository billChallengeRepository,
            AccountRepository accountRepository,
            NotificationService notificationService,
            RewardEventRepository rewardEventRepository) {

        this.rewardWalletRepository = rewardWalletRepository;
        this.billChallengeRepository = billChallengeRepository;
        this.accountRepository = accountRepository;
        this.notificationService = notificationService;
        this.rewardEventRepository = rewardEventRepository;
    }

    @Transactional
    public void evaluatePayment(
            Account account,
            String category,
            String biller,
            BigDecimal amount) {

        if (account == null) {
            throw new IllegalArgumentException(
                    "Le compte est obligatoire pour appliquer les promotions."
            );
        }

        if (account.getUser() == null ||
                account.getUser().getId() == null) {

            throw new IllegalArgumentException(
                    "Le compte doit être associé à un utilisateur."
            );
        }

        if (amount == null ||
                amount.compareTo(BigDecimal.ZERO) <= 0) {

            throw new IllegalArgumentException(
                    "Le montant du paiement doit être supérieur à zéro."
            );
        }

        Long userId = account.getUser().getId();
        User user = account.getUser();

        RewardWallet wallet = getOrCreateWallet(userId, user);

        String normalizedCategory =
                category == null ? "" : category.trim();

        String normalizedBiller =
                biller == null || biller.trim().isEmpty()
                        ? "Service"
                        : biller.trim();

        boolean isBill =
                "Factures".equalsIgnoreCase(normalizedCategory);

        // =====================================================
        // 1. POINTS CUMULÉS
        // =====================================================

        int pointsFromAmount = applyCumulativePoints(wallet, amount);

        if (pointsFromAmount > 0) {

            RewardEvent pointsEvent = new RewardEvent();
            pointsEvent.setUser(user);
            pointsEvent.setType("POINTS");
            pointsEvent.setPointsDelta(pointsFromAmount);
            pointsEvent.setCashAmount(BigDecimal.ZERO);
            pointsEvent.setTitle("Points sur dépenses cumulées");
            pointsEvent.setDescription(
                    "Paiement de " + amount + " TND : +"
                            + pointsFromAmount + " point(s)."
            );
            pointsEvent.setOperationReference(normalizedBiller);

            rewardEventRepository.save(pointsEvent);
        }

        // =====================================================
        // 2. BONUS FACTURE
        // =====================================================

        if (isBill) {

            wallet.setPointsBalance(
                    wallet.getPointsBalance() + BILL_PAYMENT_POINTS
            );

            RewardEvent billEvent = new RewardEvent();
            billEvent.setUser(user);
            billEvent.setType("BILL_BONUS");
            billEvent.setPointsDelta(BILL_PAYMENT_POINTS);
            billEvent.setCashAmount(BigDecimal.ZERO);
            billEvent.setTitle("Bonus facture");
            billEvent.setDescription(
                    "Facture " + normalizedBiller + " payée : +"
                            + BILL_PAYMENT_POINTS + " points."
            );
            billEvent.setOperationReference(normalizedBiller);

            rewardEventRepository.save(billEvent);
        }

        rewardWalletRepository.save(wallet);

        // =====================================================
        // 3. CHALLENGE FACTURES
        // =====================================================

        if (isBill) {

            evaluateBillChallenge(
                    userId,
                    account,
                    normalizedBiller,
                    pointsFromAmount
            );

        } else {

            if (pointsFromAmount > 0) {

                notificationService.notifyPromotion(
                        userId,
                        "Points gagnés",
                        "Paiement de " + amount
                                + " TND : vous avez gagné "
                                + pointsFromAmount + " point(s)."
                );
            }
        }
    }

    private int applyCumulativePoints(
            RewardWallet wallet,
            BigDecimal amount) {

        BigDecimal pending = wallet.getPendingAmountForPoints();

        if (pending == null) {
            pending = BigDecimal.ZERO;
        }

        BigDecimal total = pending.add(amount);

        int pointsEarned = total.divide(
                POINTS_THRESHOLD,
                0,
                RoundingMode.DOWN
        ).intValue();

        BigDecimal remainder = total.subtract(
                POINTS_THRESHOLD.multiply(
                        BigDecimal.valueOf(pointsEarned)
                )
        );

        wallet.setPendingAmountForPoints(remainder);

        if (pointsEarned > 0) {
            wallet.setPointsBalance(
                    wallet.getPointsBalance() + pointsEarned
            );
        }

        return pointsEarned;
    }

    private void evaluateBillChallenge(
            Long userId,
            Account account,
            String biller,
            int pointsFromAmount) {

        BillChallenge challenge =
                billChallengeRepository
                        .findByUserIdAndStatus(userId, "ACTIVE")
                        .orElseGet(() -> {

                            BillChallenge newChallenge = new BillChallenge();
                            newChallenge.setUser(account.getUser());
                            newChallenge.setCountCurrentCycle(0);
                            newChallenge.setStatus("ACTIVE");
                            return newChallenge;
                        });

        int newCount = challenge.getCountCurrentCycle() + 1;
        challenge.setCountCurrentCycle(newCount);

        int totalPoints = pointsFromAmount + BILL_PAYMENT_POINTS;

        if (newCount >= BILL_CHALLENGE_TARGET) {

            account.setBalance(
                    account.getBalance().add(BILL_CHALLENGE_REWARD)
            );

            accountRepository.save(account);

            challenge.setStatus("COMPLETED");
            billChallengeRepository.save(challenge);

            BillChallenge newCycle = new BillChallenge();
            newCycle.setUser(account.getUser());
            newCycle.setCountCurrentCycle(0);
            newCycle.setStatus("ACTIVE");
            billChallengeRepository.save(newCycle);

            RewardEvent challengeEvent = new RewardEvent();
            challengeEvent.setUser(account.getUser());
            challengeEvent.setType("BILL_CHALLENGE");
            challengeEvent.setPointsDelta(0);
            challengeEvent.setCashAmount(BILL_CHALLENGE_REWARD);
            challengeEvent.setTitle("Challenge 5 factures terminé");
            challengeEvent.setDescription(
                    "5 paiements de factures effectués : +"
                            + BILL_CHALLENGE_REWARD
                            + " DT crédités sur le compte courant."
            );
            challengeEvent.setOperationReference(biller);

            rewardEventRepository.save(challengeEvent);

            notificationService.notifyPromotion(
                    userId,
                    "Challenge terminé !",
                    "Facture " + biller + " payée : +" + totalPoints
                            + " points. Vous avez effectué 5 paiements de "
                            + "factures et gagné " + BILL_CHALLENGE_REWARD
                            + " DT sur votre compte courant."
            );

        } else {

            billChallengeRepository.save(challenge);

            notificationService.notifyPromotion(
                    userId,
                    "Points gagnés",
                    "Facture " + biller + " payée : +" + totalPoints
                            + " points. Challenge factures : " + newCount
                            + " / " + BILL_CHALLENGE_TARGET + "."
            );
        }
    }

    private RewardWallet getOrCreateWallet(Long userId, User user) {

        return rewardWalletRepository
                .findByUserId(userId)
                .orElseGet(() -> {

                    RewardWallet newWallet = new RewardWallet();
                    newWallet.setUser(user);
                    newWallet.setPointsBalance(0);
                    newWallet.setPendingAmountForPoints(BigDecimal.ZERO);
                    newWallet.setTotalCashback(BigDecimal.ZERO);
                    return rewardWalletRepository.save(newWallet);
                });
    }
}