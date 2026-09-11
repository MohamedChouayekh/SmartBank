package com.smartbank.backend.service;

import com.smartbank.backend.entity.Account;
import com.smartbank.backend.entity.Card;
import com.smartbank.backend.repository.AccountRepository;
import com.smartbank.backend.repository.CardRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
public class CardService {

    private final CardRepository cardRepository;
    private final AccountRepository accountRepository;
    private final TransactionService transactionService;

    public CardService(
            CardRepository cardRepository,
            AccountRepository accountRepository,
            TransactionService transactionService) {

        this.cardRepository = cardRepository;
        this.accountRepository = accountRepository;
        this.transactionService = transactionService;
    }

    public List<Card> getCardsByUser(Long userId) {
        return cardRepository.findByAccount_User_Id(userId);
    }

    @Transactional
    public Card addCard(
            Long userId,
            String cardType,
            String lastFourDigits,
            String expiryDate) {

        if (userId == null) {
            throw new RuntimeException("Utilisateur obligatoire.");
        }

        if (cardType == null || cardType.trim().isEmpty()) {
            throw new RuntimeException(
                    "Le type de carte est obligatoire."
            );
        }

        if (lastFourDigits == null ||
                !lastFourDigits.matches("\\d{4}")) {
            throw new RuntimeException(
                    "Les quatre derniers chiffres de la carte sont invalides."
            );
        }

        if (expiryDate == null ||
                !expiryDate.matches("(0[1-9]|1[0-2])/\\d{2}")) {
            throw new RuntimeException(
                    "La date d'expiration est invalide. Format attendu : MM/AA."
            );
        }

        Account currentAccount = accountRepository
                .findByUserId(userId)
                .stream()
                .filter(account ->
                        account.getType() != null &&
                                "CURRENT".equalsIgnoreCase(
                                        account.getType().trim()
                                )
                )
                .findFirst()
                .orElseThrow(() ->
                        new RuntimeException(
                                "Compte courant introuvable."
                        )
                );

        if (cardRepository.existsByLastFourDigitsAndAccount_Id(
                lastFourDigits,
                currentAccount.getId())) {

            throw new RuntimeException(
                    "Une carte avec ces quatre derniers chiffres existe déjà."
            );
        }

        Card card = new Card();

        card.setCardType(cardType.trim());
        card.setLastFourDigits(lastFourDigits);
        card.setExpiryDate(expiryDate);
        card.setStatus("ACTIVE");
        card.setAccount(currentAccount);

        return cardRepository.save(card);
    }

    @Transactional
    public BigDecimal withdrawWithCard(
            Long userId,
            Long cardId,
            BigDecimal amount) {

        if (userId == null) {
            throw new RuntimeException(
                    "Utilisateur obligatoire."
            );
        }

        if (cardId == null) {
            throw new RuntimeException(
                    "Carte obligatoire."
            );
        }

        if (amount == null ||
                amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new RuntimeException(
                    "Le montant du retrait doit être supérieur à 0."
            );
        }

        Card card = cardRepository
                .findByIdAndAccount_User_Id(cardId, userId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Carte introuvable ou non autorisée."
                        )
                );

        if (!"ACTIVE".equalsIgnoreCase(card.getStatus())) {
            throw new RuntimeException(
                    "Cette carte n'est pas active."
            );
        }

        Account account = card.getAccount();

        if (account == null) {
            throw new RuntimeException(
                    "Aucun compte n'est associé à cette carte."
            );
        }

        if (!"CURRENT".equalsIgnoreCase(account.getType())) {
            throw new RuntimeException(
                    "Les retraits par carte sont uniquement autorisés depuis le compte courant."
            );
        }

        return transactionService.makeWithdrawal(
                account.getAccountNumber(),
                amount
        );
    }
}