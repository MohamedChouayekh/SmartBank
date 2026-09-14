package com.smartbank.backend.service;

import com.smartbank.backend.entity.Account;
import com.smartbank.backend.entity.Card;
import com.smartbank.backend.repository.AccountRepository;
import com.smartbank.backend.repository.CardRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.security.SecureRandom;
import java.time.LocalDate;
import java.util.List;

@Service
public class CardService {

    private final CardRepository cardRepository;
    private final AccountRepository accountRepository;
    private final TransactionService transactionService;

    private final SecureRandom secureRandom = new SecureRandom();

    public CardService(
            CardRepository cardRepository,
            AccountRepository accountRepository,
            TransactionService transactionService) {

        this.cardRepository = cardRepository;
        this.accountRepository = accountRepository;
        this.transactionService = transactionService;
    }

    // =========================================================
    // RÉCUPÉRER LES CARTES D'UN UTILISATEUR
    // =========================================================

    public List<Card> getCardsByUser(Long userId) {

        return cardRepository.findByAccount_User_Id(userId);
    }

    // =========================================================
    // AJOUTER UNE CARTE AVEC INFORMATIONS FOURNIES
    // =========================================================
    // Cette méthode est conservée pour ne pas casser
    // la fonctionnalité existante.
    // =========================================================

    @Transactional
    public Card addCard(
            Long userId,
            String cardType,
            String lastFourDigits,
            String expiryDate) {

        if (userId == null) {
            throw new RuntimeException(
                    "Utilisateur obligatoire."
            );
        }

        if (cardType == null ||
                cardType.trim().isEmpty()) {

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

        // =====================================================
        // VALIDATION DU FORMAT DE LA DATE
        // =====================================================

        if (expiryDate == null ||
                !expiryDate.matches("(0[1-9]|1[0-2])/\\d{2}")) {

            throw new RuntimeException(
                    "La date d'expiration est invalide. Format attendu : MM/AA."
            );
        }

        // =====================================================
        // VALIDATION DE L'EXPIRATION
        // =====================================================

        if (isExpired(expiryDate)) {

            throw new RuntimeException(
                    "Cette carte est expirée. Veuillez saisir une date d'expiration valide."
            );
        }

        // =====================================================
        // COMPTE COURANT
        // =====================================================

        Account currentAccount = getCurrentAccount(userId);

        // =====================================================
        // CARTE EXISTANTE
        // =====================================================

        if (cardRepository.existsByLastFourDigitsAndAccount_Id(
                lastFourDigits,
                currentAccount.getId())) {

            throw new RuntimeException(
                    "Une carte avec ces quatre derniers chiffres existe déjà."
            );
        }

        // =====================================================
        // CRÉATION DE LA CARTE
        // =====================================================

        Card card = new Card();

        card.setCardType(cardType.trim());
        card.setLastFourDigits(lastFourDigits);
        card.setExpiryDate(expiryDate);
        card.setStatus("ACTIVE");
        card.setAccount(currentAccount);

        return cardRepository.save(card);
    }

    // =========================================================
    // ATTRIBUER UNE NOUVELLE CARTE BANCAIRE
    // =========================================================
    //
    // La banque fournit uniquement :
    // - userId
    // - cardType
    //
    // Le backend génère :
    // - les 4 derniers chiffres
    // - la date d'expiration
    // - le statut ACTIVE
    //
    // L'ancienne carte n'est PAS modifiée.
    // =========================================================

    @Transactional
    public Card assignCard(
            Long userId,
            String cardType) {

        if (userId == null) {
            throw new RuntimeException(
                    "Utilisateur obligatoire."
            );
        }

        if (cardType == null ||
                cardType.trim().isEmpty()) {

            throw new RuntimeException(
                    "Le type de carte est obligatoire."
            );
        }

        // =====================================================
        // COMPTE COURANT DU CLIENT
        // =====================================================

        Account currentAccount = getCurrentAccount(userId);

        // =====================================================
        // GÉNÉRATION DES 4 DERNIERS CHIFFRES
        // =====================================================

        String lastFourDigits =
                generateUniqueLastFourDigits(
                        currentAccount.getId()
                );

        // =====================================================
        // DATE D'EXPIRATION
        // =====================================================
        //
        // Nouvelle carte valable 3 ans.
        // Exemple :
        // 09/2026 -> 09/2029
        //
        // =====================================================

        LocalDate expirationDate =
                LocalDate.now().plusYears(3);

        String expiryDate = String.format(
                "%02d/%02d",
                expirationDate.getMonthValue(),
                expirationDate.getYear() % 100
        );

        // =====================================================
        // CRÉATION DE LA NOUVELLE CARTE
        // =====================================================

        Card card = new Card();

        card.setCardType(cardType.trim());
        card.setLastFourDigits(lastFourDigits);
        card.setExpiryDate(expiryDate);
        card.setStatus("ACTIVE");
        card.setAccount(currentAccount);

        return cardRepository.save(card);
    }

    // =========================================================
    // TROUVER LE COMPTE COURANT
    // =========================================================

    private Account getCurrentAccount(Long userId) {

        return accountRepository
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
    }

    // =========================================================
    // GÉNÉRER 4 CHIFFRES UNIQUES POUR LE COMPTE
    // =========================================================

    private String generateUniqueLastFourDigits(
            Long accountId) {

        for (int attempt = 0; attempt < 100; attempt++) {

            int number =
                    secureRandom.nextInt(10000);

            String lastFourDigits =
                    String.format("%04d", number);

            boolean exists =
                    cardRepository
                            .existsByLastFourDigitsAndAccount_Id(
                                    lastFourDigits,
                                    accountId
                            );

            if (!exists) {
                return lastFourDigits;
            }
        }

        throw new RuntimeException(
                "Impossible de générer un numéro de carte disponible."
        );
    }

    // =========================================================
    // VÉRIFIER SI LA CARTE EST EXPIRÉE
    // =========================================================

    private boolean isExpired(String expiryDate) {

        String[] parts = expiryDate.split("/");

        int month = Integer.parseInt(parts[0]);
        int year = 2000 + Integer.parseInt(parts[1]);

        LocalDate now = LocalDate.now();

        int currentYear = now.getYear();
        int currentMonth = now.getMonthValue();

        if (year < currentYear) {
            return true;
        }

        if (year == currentYear &&
                month < currentMonth) {

            return true;
        }

        return false;
    }

    // =========================================================
    // RETRAIT AVEC CARTE
    // =========================================================

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
                .findByIdAndAccount_User_Id(
                        cardId,
                        userId
                )
                .orElseThrow(() ->
                        new RuntimeException(
                                "Carte introuvable ou non autorisée."
                        )
                );

        if (!"ACTIVE".equalsIgnoreCase(
                card.getStatus())) {

            throw new RuntimeException(
                    "Cette carte n'est pas active."
            );
        }

        // =====================================================
        // VÉRIFICATION DE L'EXPIRATION AVANT RETRAIT
        // =====================================================

        if (isExpired(card.getExpiryDate())) {

            throw new RuntimeException(
                    "Cette carte est expirée. Le retrait est impossible."
            );
        }

        Account account = card.getAccount();

        if (account == null) {
            throw new RuntimeException(
                    "Aucun compte n'est associé à cette carte."
            );
        }

        if (!"CURRENT".equalsIgnoreCase(
                account.getType())) {

            throw new RuntimeException(
                    "Les retraits par carte sont uniquement autorisés depuis le compte courant."
            );
        }

        return transactionService.makeWithdrawal(
                account.getAccountNumber(),
                amount
        );
    }

    // =========================================================
    // BLOQUER UNE CARTE
    // =========================================================

    @Transactional
    public Card blockCard(
            Long userId,
            Long cardId) {

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

        Card card = cardRepository
                .findByIdAndAccount_User_Id(
                        cardId,
                        userId
                )
                .orElseThrow(() ->
                        new RuntimeException(
                                "Carte introuvable ou non autorisée."
                        )
                );

        if ("EXPIRED".equalsIgnoreCase(
                card.getStatus())) {

            throw new RuntimeException(
                    "Cette carte est expirée et ne peut pas être bloquée."
            );
        }

        if ("BLOCKED".equalsIgnoreCase(
                card.getStatus())) {

            throw new RuntimeException(
                    "Cette carte est déjà bloquée."
            );
        }

        card.setStatus("BLOCKED");

        return cardRepository.save(card);
    }

    // =========================================================
    // DÉBLOQUER UNE CARTE
    // =========================================================

    @Transactional
    public Card unblockCard(
            Long userId,
            Long cardId) {

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

        Card card = cardRepository
                .findByIdAndAccount_User_Id(
                        cardId,
                        userId
                )
                .orElseThrow(() ->
                        new RuntimeException(
                                "Carte introuvable ou non autorisée."
                        )
                );

        if ("EXPIRED".equalsIgnoreCase(
                card.getStatus())) {

            throw new RuntimeException(
                    "Cette carte est expirée et ne peut pas être débloquée."
            );
        }

        if ("ACTIVE".equalsIgnoreCase(
                card.getStatus())) {

            throw new RuntimeException(
                    "Cette carte est déjà active."
            );
        }

        card.setStatus("ACTIVE");

        return cardRepository.save(card);
    }
}