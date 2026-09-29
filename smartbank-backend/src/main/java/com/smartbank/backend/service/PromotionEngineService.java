package com.smartbank.backend.service;

import com.smartbank.backend.entity.*;
import com.smartbank.backend.repository.*;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;

@Service
public class PromotionEngineService {

    private static final BigDecimal POINTS_THRESHOLD = new BigDecimal("10.000");
    private static final int BILL_PAYMENT_POINTS = 20;
    private static final int BILL_CHALLENGE_TARGET = 5;
    private static final BigDecimal BILL_CHALLENGE_REWARD = new BigDecimal("5.000");

    private static final BigDecimal CASHBACK_THRESHOLD = new BigDecimal("200.000");
    private static final BigDecimal CASHBACK_RATE = new BigDecimal("0.02");
    private static final int CARD_CHALLENGE_TARGET = 3;
    private static final int CARD_CHALLENGE_POINTS = 100;

    private final RewardWalletRepository rewardWalletRepository;
    private final BillChallengeRepository billChallengeRepository;
    private final CardPaymentChallengeRepository cardPaymentChallengeRepository;
    private final AccountRepository accountRepository;
    private final NotificationService notificationService;
    private final RewardEventRepository rewardEventRepository;

    public PromotionEngineService(
            RewardWalletRepository rewardWalletRepository,
            BillChallengeRepository billChallengeRepository,
            CardPaymentChallengeRepository cardPaymentChallengeRepository,
            AccountRepository accountRepository,
            NotificationService notificationService,
            RewardEventRepository rewardEventRepository) {

        this.rewardWalletRepository = rewardWalletRepository;
        this.billChallengeRepository = billChallengeRepository;
        this.cardPaymentChallengeRepository = cardPaymentChallengeRepository;
        this.accountRepository = accountRepository;
        this.notificationService = notificationService;
        this.rewardEventRepository = rewardEventRepository;
    }

    // =========================================================
    // PAIEMENT ORDINAIRE (factures, services, recharges)
    // =========================================================

    @Transactional
    public void evaluatePayment(
            Account account,
            String category,
            String biller,
            BigDecimal amount) {

        validateAccountAndAmount(account, amount);

        Long userId = account.getUser().getId();
        User user = account.getUser();

        RewardWallet wallet = getOrCreateWallet(userId, user);

        String normalizedCategory = category == null ? "" : category.trim();
        String normalizedBiller = biller == null || biller.trim().isEmpty() ? "Service" : biller.trim();
        boolean isBill = "Factures".equalsIgnoreCase(normalizedCategory);

        int pointsFromAmount = applyCumulativePoints(wallet, amount);

        if (pointsFromAmount > 0) {
            saveEvent(user, "POINTS", pointsFromAmount, BigDecimal.ZERO,
                    "Points sur dépenses cumulées",
                    "Paiement de " + amount + " TND : +" + pointsFromAmount + " point(s).",
                    normalizedBiller);
        }

        if (isBill) {
            wallet.setPointsBalance(wallet.getPointsBalance() + BILL_PAYMENT_POINTS);

            saveEvent(user, "BILL_BONUS", BILL_PAYMENT_POINTS, BigDecimal.ZERO,
                    "Bonus facture",
                    "Facture " + normalizedBiller + " payée : +" + BILL_PAYMENT_POINTS + " points.",
                    normalizedBiller);
        }

        rewardWalletRepository.save(wallet);

        if (isBill) {
            evaluateBillChallenge(userId, account, normalizedBiller, pointsFromAmount);
        } else if (pointsFromAmount > 0) {
            notificationService.notifyPromotion(
                    userId,
                    "Points gagnés",
                    "Paiement de " + amount + " TND : vous avez gagné " + pointsFromAmount + " point(s)."
            );
        }
    }

    // =========================================================
    // PAIEMENT PAR CARTE (cashback + challenge 3 paiements)
    // =========================================================

    @Transactional
    public void evaluateCardPayment(
            Account account,
            BigDecimal amount,
            String merchant) {

        validateAccountAndAmount(account, amount);

        Long userId = account.getUser().getId();
        User user = account.getUser();

        RewardWallet wallet = getOrCreateWallet(userId, user);

        String normalizedMerchant = merchant == null || merchant.trim().isEmpty()
                ? "Marchand" : merchant.trim();

        // =====================================================
        // 1. POINTS CUMULÉS (même règle que les autres paiements)
        // =====================================================

        int pointsFromAmount = applyCumulativePoints(wallet, amount);

        if (pointsFromAmount > 0) {
            saveEvent(user, "POINTS", pointsFromAmount, BigDecimal.ZERO,
                    "Points sur dépenses cumulées",
                    "Paiement carte de " + amount + " TND : +" + pointsFromAmount + " point(s).",
                    normalizedMerchant);
        }

        // =====================================================
        // 2. CASHBACK (paiement unique >= 200 DT)
        // =====================================================

        if (amount.compareTo(CASHBACK_THRESHOLD) >= 0) {

            BigDecimal cashback = amount.multiply(CASHBACK_RATE)
                    .setScale(3, RoundingMode.HALF_UP);

            wallet.setTotalCashback(
                    wallet.getTotalCashback().add(cashback)
            );

            account.setBalance(
                    account.getBalance().add(cashback)
            );

            accountRepository.save(account);

            saveEvent(user, "CASHBACK", 0, cashback,
                    "Cashback obtenu",
                    "Paiement carte de " + amount + " TND chez " + normalizedMerchant
                            + " : +" + cashback + " DT de cashback crédités automatiquement.",
                    normalizedMerchant);

            notificationService.notifyPromotion(
                    userId,
                    "Cashback obtenu",
                    "Paiement de " + amount + " TND chez " + normalizedMerchant
                            + " : +" + cashback + " DT crédités sur votre compte."
            );
        }

        rewardWalletRepository.save(wallet);

        // =====================================================
        // 3. CHALLENGE 3 PAIEMENTS CARTE
        // =====================================================

        evaluateCardChallenge(userId, account, normalizedMerchant, pointsFromAmount);
    }

    // =========================================================
    // VALIDATION COMMUNE
    // =========================================================

    private void validateAccountAndAmount(Account account, BigDecimal amount) {

        if (account == null) {
            throw new IllegalArgumentException(
                    "Le compte est obligatoire pour appliquer les promotions."
            );
        }

        if (account.getUser() == null || account.getUser().getId() == null) {
            throw new IllegalArgumentException(
                    "Le compte doit être associé à un utilisateur."
            );
        }

        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException(
                    "Le montant du paiement doit être supérieur à zéro."
            );
        }
    }

    // =========================================================
    // CALCUL DES POINTS CUMULÉS
    // =========================================================

    private int applyCumulativePoints(RewardWallet wallet, BigDecimal amount) {

        BigDecimal pending = wallet.getPendingAmountForPoints();
        if (pending == null) {
            pending = BigDecimal.ZERO;
        }

        BigDecimal total = pending.add(amount);

        int pointsEarned = total.divide(POINTS_THRESHOLD, 0, RoundingMode.DOWN).intValue();

        BigDecimal remainder = total.subtract(
                POINTS_THRESHOLD.multiply(BigDecimal.valueOf(pointsEarned))
        );

        wallet.setPendingAmountForPoints(remainder);

        if (pointsEarned > 0) {
            wallet.setPointsBalance(wallet.getPointsBalance() + pointsEarned);
        }

        return pointsEarned;
    }

    // =========================================================
    // CHALLENGE 5 FACTURES
    // =========================================================

    private void evaluateBillChallenge(
            Long userId, Account account, String biller, int pointsFromAmount) {

        BillChallenge challenge = billChallengeRepository
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

            account.setBalance(account.getBalance().add(BILL_CHALLENGE_REWARD));
            accountRepository.save(account);

            challenge.setStatus("COMPLETED");
            billChallengeRepository.save(challenge);

            BillChallenge newCycle = new BillChallenge();
            newCycle.setUser(account.getUser());
            newCycle.setCountCurrentCycle(0);
            newCycle.setStatus("ACTIVE");
            billChallengeRepository.save(newCycle);

            saveEvent(account.getUser(), "BILL_CHALLENGE", 0, BILL_CHALLENGE_REWARD,
                    "Challenge 5 factures terminé",
                    "5 paiements de factures effectués : +" + BILL_CHALLENGE_REWARD
                            + " DT crédités sur le compte courant.",
                    biller);

            notificationService.notifyPromotion(
                    userId,
                    "Challenge terminé !",
                    "Facture " + biller + " payée : +" + totalPoints
                            + " points. Vous avez effectué 5 paiements de factures et gagné "
                            + BILL_CHALLENGE_REWARD + " DT sur votre compte courant."
            );

        } else {

            billChallengeRepository.save(challenge);

            notificationService.notifyPromotion(
                    userId,
                    "Points gagnés",
                    "Facture " + biller + " payée : +" + totalPoints
                            + " points. Challenge factures : " + newCount + " / " + BILL_CHALLENGE_TARGET + "."
            );
        }
    }

    // =========================================================
    // CHALLENGE 3 PAIEMENTS CARTE
    // =========================================================

    private void evaluateCardChallenge(
            Long userId, Account account, String merchant, int pointsFromAmount) {

        CardPaymentChallenge challenge = cardPaymentChallengeRepository
                .findByUserIdAndStatus(userId, "ACTIVE")
                .orElseGet(() -> {
                    CardPaymentChallenge newChallenge = new CardPaymentChallenge();
                    newChallenge.setUser(account.getUser());
                    newChallenge.setCountCurrentCycle(0);
                    newChallenge.setStatus("ACTIVE");
                    return newChallenge;
                });

        int newCount = challenge.getCountCurrentCycle() + 1;
        challenge.setCountCurrentCycle(newCount);

        if (newCount >= CARD_CHALLENGE_TARGET) {

            RewardWallet wallet = getOrCreateWallet(userId, account.getUser());
            wallet.setPointsBalance(wallet.getPointsBalance() + CARD_CHALLENGE_POINTS);
            rewardWalletRepository.save(wallet);

            challenge.setStatus("COMPLETED");
            cardPaymentChallengeRepository.save(challenge);

            CardPaymentChallenge newCycle = new CardPaymentChallenge();
            newCycle.setUser(account.getUser());
            newCycle.setCountCurrentCycle(0);
            newCycle.setStatus("ACTIVE");
            cardPaymentChallengeRepository.save(newCycle);

            saveEvent(account.getUser(), "CARD_CHALLENGE", CARD_CHALLENGE_POINTS, BigDecimal.ZERO,
                    "Challenge 3 paiements carte terminé",
                    "3 paiements par carte effectués : +" + CARD_CHALLENGE_POINTS + " points.",
                    merchant);

            notificationService.notifyPromotion(
                    userId,
                    "Challenge terminé !",
                    "Paiement chez " + merchant + " : vous avez effectué 3 paiements par carte et gagné "
                            + CARD_CHALLENGE_POINTS + " points."
            );

        } else {

            cardPaymentChallengeRepository.save(challenge);

            if (pointsFromAmount > 0 || newCount > 0) {
                notificationService.notifyPromotion(
                        userId,
                        "Progression du challenge",
                        "Challenge paiements carte : " + newCount + " / " + CARD_CHALLENGE_TARGET + "."
                );
            }
        }
    }

    // =========================================================
    // RÉCUPÉRER OU CRÉER LE PORTEFEUILLE
    // =========================================================

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

    // =========================================================
    // ENREGISTRER UN REWARD EVENT
    // =========================================================

    private void saveEvent(
            User user, String type, int pointsDelta, BigDecimal cashAmount,
            String title, String description, String operationReference) {

        RewardEvent event = new RewardEvent();
        event.setUser(user);
        event.setType(type);
        event.setPointsDelta(pointsDelta);
        event.setCashAmount(cashAmount);
        event.setTitle(title);
        event.setDescription(description);
        event.setOperationReference(operationReference);

        rewardEventRepository.save(event);
    }
}