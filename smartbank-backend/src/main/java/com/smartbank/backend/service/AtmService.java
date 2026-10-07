package com.smartbank.backend.service;

import com.smartbank.backend.entity.Atm;
import com.smartbank.backend.repository.AtmRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class AtmService {

    private final AtmRepository atmRepository;

    public AtmService(AtmRepository atmRepository) {
        this.atmRepository = atmRepository;
    }

    // =========================================================
    // TOUS LES DAB
    // =========================================================

    public List<Atm> getAllAtms() {
        return atmRepository.findAll();
    }

    // =========================================================
    // DAB PAR ID
    // =========================================================

    public Atm getAtmById(Long atmId) {

        if (atmId == null) {
            throw new RuntimeException("DAB obligatoire.");
        }

        return atmRepository.findById(atmId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "DAB introuvable."
                        )
                );
    }

    // =========================================================
    // VÉRIFIER SI LE DAB AUTORISE UN RETRAIT
    // =========================================================

    public Atm validateWithdrawalAtm(Long atmId) {

        Atm atm = getAtmById(atmId);

        if (!atm.isAvailable()) {
            throw new RuntimeException(
                    "Ce DAB est actuellement indisponible."
            );
        }

        if (!atm.isWithdrawalAvailable()) {
            throw new RuntimeException(
                    "Les retraits sont actuellement indisponibles sur ce DAB."
            );
        }

        return atm;
    }

    // =========================================================
    // CRÉATION
    // =========================================================

    @Transactional
    public Atm createAtm(
            String name,
            String city,
            String address,
            boolean available24h,
            boolean withdrawalAvailable,
            boolean depositAvailable,
            boolean available) {

        if (name == null || name.trim().isEmpty()) {
            throw new RuntimeException("Nom du DAB obligatoire.");
        }

        if (city == null || city.trim().isEmpty()) {
            throw new RuntimeException("Ville obligatoire.");
        }

        if (address == null || address.trim().isEmpty()) {
            throw new RuntimeException("Adresse obligatoire.");
        }

        Atm atm = new Atm();

        atm.setName(name.trim());
        atm.setCity(city.trim());
        atm.setAddress(address.trim());
        atm.setAvailable24h(available24h);
        atm.setWithdrawalAvailable(withdrawalAvailable);
        atm.setDepositAvailable(depositAvailable);
        atm.setAvailable(available);

        return atmRepository.save(atm);
    }
}