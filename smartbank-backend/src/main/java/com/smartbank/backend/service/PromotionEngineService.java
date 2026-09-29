package com.smartbank.backend.service;

import com.smartbank.backend.entity.Account;
import com.smartbank.backend.entity.BillChallenge;
import com.smartbank.backend.entity.RewardWallet;
import com.smartbank.backend.entity.User;
import com.smartbank.backend.repository.AccountRepository;
import com.smartbank.backend.repository.BillChallengeRepository;
import com.smartbank.backend.repository.RewardWalletRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;

@Service
public class PromotionEngineService {

    private static final BigDecimal POINTS_THRESHOLD =
            new BigDecimal("10");

    private static final int BILL_PAYMENT_POINTS = 20;

    private static final int BILL_CHALLENGE_TARGET = 5;

    private static final BigDecimal BILL_CHALLENGE_REWARD =
            new BigDecimal("5");

    private final RewardWalletRepository rewardWalletRepository;
    private final BillChallengeRepository billChallengeRepository;
    private final AccountRepository accountRepository;
    private final NotificationService notificationService;

    public PromotionEngineService(
            RewardWalletRepository rewardWalletRepository,
            BillChallengeRepository billChallengeRepository,
            AccountRepository accountRepository,
            NotificationService notificationService) {

        this.rewardWalletRepository =
                rewardWalletRepository;

        this.billChallengeRepository =
                billChallengeRepository;

        this.accountRepository =
                accountRepository;

        this.notificationService =
                notificationService;
    }

    // =========================================================
    // POINT D'ENTRÉE
    // APPELÉ APRÈS UN PAIEMENT RÉUSSI
    // =========================================================

    @Transactional
    public void evaluatePayment(
            Account account,
            String category,
            String biller,
            BigDecimal amount) {

        Long userId =
                account.getUser().getId();

        RewardWallet wallet =
                getOrCreateWallet(
                        userId,
                        account.getUser()
                );

        // =====================================================
        // 1. POINTS CUMULÉS
        // 10 DT = 1 POINT
        // =====================================================

        int pointsFromAmount =
                applyCumulativePoints(
                        wallet,
                        amount
                );

        boolean isBill =
                "Factures".equalsIgnoreCase(
                        category
                );

        // =====================================================
        // 2. BONUS FACTURE
        // +20 POINTS
        // =====================================================

        if (isBill) {

            wallet.setPointsBalance(
                    wallet.getPointsBalance()
                            + BILL_PAYMENT_POINTS
            );
        }

        rewardWalletRepository.save(wallet);

        // =====================================================
        // 3. CHALLENGE FACTURES
        // =====================================================

        if (isBill) {

            evaluateBillChallenge(
                    userId,
                    account,
                    biller,
                    pointsFromAmount
            );

        } else {

            // =================================================
            // NOTIFICATION POUR SERVICES / RECHARGES
            // =================================================

            if (pointsFromAmount > 0) {

                notificationService.notifyPromotion(
                        userId,
                        "Points gagnés",
                        "Paiement de "
                                + amount
                                + " TND : vous avez gagné "
                                + pointsFromAmount
                                + " point(s)."
                );
            }
        }
    }

    // =========================================================
    // CALCUL DES POINTS CUMULÉS
    //
    // Exemple :
    // 7 DT + 8 DT = 15 DT
    // → +1 point
    // → reste 5 DT
    // =========================================================

    private int applyCumulativePoints(
            RewardWallet wallet,
            BigDecimal amount) {

        BigDecimal pending =
                wallet.getPendingAmountForPoints();

        if (pending == null) {
            pending = BigDecimal.ZERO;
        }

        BigDecimal total =
                pending.add(amount);

        int pointsEarned =
                total.divide(
                        POINTS_THRESHOLD,
                        0,
                        RoundingMode.DOWN
                ).intValue();

        BigDecimal remainder =
                total.subtract(
                        POINTS_THRESHOLD.multiply(
                                BigDecimal.valueOf(
                                        pointsEarned
                                )
                        )
                );

        wallet.setPendingAmountForPoints(
                remainder
        );

        if (pointsEarned > 0) {

            wallet.setPointsBalance(
                    wallet.getPointsBalance()
                            + pointsEarned
            );
        }

        return pointsEarned;
    }

    // =========================================================
    // CHALLENGE 5 FACTURES
    // =========================================================

    private void evaluateBillChallenge(
            Long userId,
            Account account,
            String biller,
            int pointsFromAmount) {

        BillChallenge challenge =
                billChallengeRepository
                        .findByUserIdAndStatus(
                                userId,
                                "ACTIVE"
                        )
                        .orElseGet(() -> {

                            BillChallenge newChallenge =
                                    new BillChallenge();

                            newChallenge.setUser(
                                    account.getUser()
                            );

                            newChallenge.setCountCurrentCycle(
                                    0
                            );

                            newChallenge.setStatus(
                                    "ACTIVE"
                            );

                            return newChallenge;
                        });

        int newCount =
                challenge.getCountCurrentCycle() + 1;

        challenge.setCountCurrentCycle(
                newCount
        );

        // =====================================================
        // CHALLENGE TERMINÉ
        // =====================================================

        if (newCount >= BILL_CHALLENGE_TARGET) {

            // +5 DT sur le compte courant
            account.setBalance(
                    account.getBalance()
                            .add(BILL_CHALLENGE_REWARD)
            );

            accountRepository.save(
                    account
            );

            challenge.setStatus(
                    "COMPLETED"
            );

            billChallengeRepository.save(
                    challenge
            );

            // =================================================
            // NOUVEAU CYCLE
            // =================================================

            BillChallenge newCycle =
                    new BillChallenge();

            newCycle.setUser(
                    account.getUser()
            );

            newCycle.setCountCurrentCycle(
                    0
            );

            newCycle.setStatus(
                    "ACTIVE"
            );

            billChallengeRepository.save(
                    newCycle
            );

            // =================================================
            // UNE NOTIFICATION
            // =================================================

            int totalPoints =
                    pointsFromAmount
                            + BILL_PAYMENT_POINTS;

            notificationService.notifyPromotion(
                    userId,
                    "Challenge terminé !",
                    "Facture "
                            + biller
                            + " payée : +"
                            + totalPoints
                            + " points. "
                            + "Vous avez effectué 5 paiements de factures "
                            + "et gagné "
                            + BILL_CHALLENGE_REWARD
                            + " DT sur votre compte courant."
            );

        } else {

            billChallengeRepository.save(
                    challenge
            );

            // =================================================
            // UNE NOTIFICATION
            // =================================================

            int totalPoints =
                    pointsFromAmount
                            + BILL_PAYMENT_POINTS;

            notificationService.notifyPromotion(
                    userId,
                    "Points gagnés",
                    "Facture "
                            + biller
                            + " payée : +"
                            + totalPoints
                            + " points. "
                            + "Challenge factures : "
                            + newCount
                            + " / "
                            + BILL_CHALLENGE_TARGET
                            + "."
            );
        }
    }

    // =========================================================
    // RÉCUPÉRER OU CRÉER LE PORTEFEUILLE
    // =========================================================

    private RewardWallet getOrCreateWallet(
            Long userId,
            User user) {

        return rewardWalletRepository
                .findByUserId(userId)
                .orElseGet(() -> {

                    RewardWallet newWallet =
                            new RewardWallet();

                    newWallet.setUser(user);

                    newWallet.setPointsBalance(
                            0
                    );

                    newWallet.setPendingAmountForPoints(
                            BigDecimal.ZERO
                    );

                    // Conservé pour le futur cashback
                    newWallet.setTotalCashback(
                            BigDecimal.ZERO
                    );

                    return rewardWalletRepository.save(
                            newWallet
                    );
                });
    }
}