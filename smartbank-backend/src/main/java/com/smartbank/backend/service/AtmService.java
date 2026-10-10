        package com.smartbank.backend.service;

import com.smartbank.backend.entity.Atm;
import com.smartbank.backend.repository.AtmRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

@Service
public class AtmService {

    private final AtmRepository atmRepository;

    public AtmService(AtmRepository atmRepository) {
        this.atmRepository = atmRepository;
    }

    /**
     * Lecture seule : retourne les DAB et leurs états actuels.
     * Cette méthode ne déclenche aucune rotation.
     */
    @Transactional(readOnly = true)
    public List<Atm> getAllAtms() {
        List<Atm> atms =
                new ArrayList<>(atmRepository.findAll());

        atms.sort(Comparator.comparing(Atm::getId));

        return atms;
    }

    /**
     * Mise à jour aléatoire des disponibilités.
     *
     * À chaque cycle :
     * - chaque DAB a individuellement 25 % de probabilité
     *   de changer son état de disponibilité ;
     * - un DAB indisponible peut le rester plusieurs cycles ;
     * - un DAB disponible peut le rester plusieurs cycles ;
     * - aucun changement n'est garanti à chaque cycle ;
     * - les capacités de retrait et de dépôt ne sont pas modifiées.
     *
     * La planification est activée dans SchedulingConfig
     * ou par @EnableScheduling dans l'application Spring Boot.
     */
    @org.springframework.scheduling.annotation.Scheduled(
            fixedRate = 60_000,
            initialDelay = 60_000
    )
    @Transactional
    public void updateAtmAvailability() {

        List<Atm> atms =
                new ArrayList<>(atmRepository.findAll());

        atms.sort(Comparator.comparing(Atm::getId));

        if (atms.isEmpty()) {
            System.out.println(
                    "[SMARTBANK DAB] Aucun DAB à mettre à jour."
            );
            return;
        }

        int changedCount = 0;
        int unavailableCount = 0;

        /*
         * Chaque DAB est traité indépendamment.
         * Il conserve son état actuel avec une probabilité
         * de 75 % et change d'état avec une probabilité de 25 %.
         *
         * On ne modifie pas withdrawalAvailable ni
         * depositAvailable : seule la disponibilité générale
         * du DAB est simulée ici.
         */
        for (Atm atm : atms) {

            boolean shouldChange =
                    ThreadLocalRandom.current().nextInt(100) < 25;

            if (shouldChange) {
                atm.setAvailable(!atm.isAvailable());
                changedCount++;
            }

            if (!atm.isAvailable()) {
                unavailableCount++;
            }
        }

        /*
         * Sauvegarde des nouveaux états.
         */
        atmRepository.saveAll(atms);

        System.out.println(
                "[SMARTBANK DAB] Mise à jour automatique : "
                        + changedCount
                        + " changement(s), "
                        + unavailableCount
                        + " DAB indisponible(s) sur "
                        + atms.size()
                        + "."
        );
    }

    /**
     * Retourne un DAB précis sans déclencher de rotation.
     */
    @Transactional(readOnly = true)
    public Atm getAtmById(Long atmId) {

        if (atmId == null) {
            throw new RuntimeException("DAB obligatoire.");
        }

        return atmRepository.findById(atmId)
                .orElseThrow(
                        () -> new RuntimeException("DAB introuvable.")
                );
    }

    /**
     * Vérifie qu'un DAB est disponible pour un retrait.
     */
    @Transactional(readOnly = true)
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

    /**
     * Création manuelle d'un DAB.
     * Méthode conservée.
     */
    @Transactional
    public Atm createAtm(
            String name,
            String city,
            String address,
            boolean available24h,
            boolean withdrawalAvailable,
            boolean depositAvailable,
            boolean available
    ) {

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
