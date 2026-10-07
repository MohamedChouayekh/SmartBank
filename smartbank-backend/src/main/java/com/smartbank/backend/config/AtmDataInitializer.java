package com.smartbank.backend.config;

import com.smartbank.backend.entity.Atm;
import com.smartbank.backend.repository.AtmRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AtmDataInitializer {

    @Bean
    CommandLineRunner initializeAtms(AtmRepository atmRepository) {

        return args -> {

            if (atmRepository.count() > 0) {
                return;
            }

            // =================================================
            // TUNIS - DAB 1
            // =================================================

            Atm tunisCentre = new Atm();

            tunisCentre.setName("DAB SmartBank Tunis Centre");
            tunisCentre.setCity("Tunis");
            tunisCentre.setAddress("Avenue Habib Bourguiba");
            tunisCentre.setAvailable24h(true);
            tunisCentre.setWithdrawalAvailable(true);
            tunisCentre.setDepositAvailable(true);
            tunisCentre.setAvailable(true);

            atmRepository.save(tunisCentre);

            // =================================================
            // TUNIS - DAB 2
            // =================================================

            Atm tunisLafayette = new Atm();

            tunisLafayette.setName("DAB SmartBank Lafayette");
            tunisLafayette.setCity("Tunis");
            tunisLafayette.setAddress("Rue de Palestine");
            tunisLafayette.setAvailable24h(true);
            tunisLafayette.setWithdrawalAvailable(true);
            tunisLafayette.setDepositAvailable(false);
            tunisLafayette.setAvailable(true);

            atmRepository.save(tunisLafayette);

            // =================================================
            // SFAX - DAB 1
            // =================================================

            Atm sfaxCentre = new Atm();

            sfaxCentre.setName("DAB SmartBank Sfax Centre");
            sfaxCentre.setCity("Sfax");
            sfaxCentre.setAddress("Avenue Hédi Chaker");
            sfaxCentre.setAvailable24h(true);
            sfaxCentre.setWithdrawalAvailable(true);
            sfaxCentre.setDepositAvailable(true);
            sfaxCentre.setAvailable(true);

            atmRepository.save(sfaxCentre);

            // =================================================
            // SFAX - DAB 2
            // =================================================

            Atm sfaxRouteTunis = new Atm();

            sfaxRouteTunis.setName("DAB SmartBank Route de Tunis");
            sfaxRouteTunis.setCity("Sfax");
            sfaxRouteTunis.setAddress("Route de Tunis");
            sfaxRouteTunis.setAvailable24h(false);
            sfaxRouteTunis.setWithdrawalAvailable(true);
            sfaxRouteTunis.setDepositAvailable(false);
            sfaxRouteTunis.setAvailable(false);

            atmRepository.save(sfaxRouteTunis);
        };
    }
}