package com.smartbank.backend.service;

import com.smartbank.backend.entity.RadarFine;
import com.smartbank.backend.repository.RadarFineRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Service
public class RadarFineService {

    private final RadarFineRepository radarFineRepository;
    private final TransactionService transactionService;

    public RadarFineService(
            RadarFineRepository radarFineRepository,
            TransactionService transactionService) {

        this.radarFineRepository = radarFineRepository;
        this.transactionService = transactionService;
    }

    public List<RadarFine> findUnpaidByImmatriculation(String immatriculation) {

        String normalizedImmatriculation =
                immatriculation
                        .trim()
                        .toUpperCase()
                        .replaceAll("\\s+", "");

        return radarFineRepository.findUnpaidByNormalizedImmatriculation(
                normalizedImmatriculation
        );
    }

    // =========================================================
    // PAIEMENT D'UNE AMENDE (débite réellement le compte)
    // =========================================================
    @Transactional
    public boolean payFine(String reference, String accountNumber) {

        if (accountNumber == null ||
                accountNumber.trim().isEmpty()) {

            throw new RuntimeException(
                    "Le compte est obligatoire pour payer une amende."
            );
        }

        Optional<RadarFine> fineOptional =
                radarFineRepository.findByReference(reference);

        if (fineOptional.isEmpty()) {
            return false;
        }

        RadarFine fine = fineOptional.get();

        if (fine.isPaid()) {
            return false;
        }

        // =====================================================
        // PAIEMENT RÉEL VIA LE FLUX BANCAIRE STANDARD
        // (débit, transaction, notification, promotions)
        // =====================================================

        transactionService.makePayment(
                accountNumber,
                "Services",
                "Amendes Radar",
                reference,
                BigDecimal.valueOf(fine.getAmount())
        );

        // =====================================================
        // MARQUER L'AMENDE COMME PAYÉE
        // =====================================================

        fine.setPaid(true);
        radarFineRepository.save(fine);

        return true;
    }
}