package com.smartbank.backend.config;

import com.smartbank.backend.entity.User;
import com.smartbank.backend.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class AdminInitializer {

    @Bean
    CommandLineRunner initializeAdmin(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder) {

        return args -> {

            User admin = userRepository
                    .findByUsername("admin")
                    .orElse(null);

            if (admin == null) {

                admin = new User();

                admin.setUsername("admin");
                admin.setEmail("admin@smartbank.tn");
                admin.setFullName(
                        "SmartBank Administrateur"
                );
                admin.setPhoneNumber("00000000");
                admin.setAddress("SmartBank");
            }

            // =====================================================
            // CONFIGURATION DU COMPTE ADMIN
            // =====================================================

            admin.setPassword(
                    passwordEncoder.encode(
                            "AdminBank!2026"
                    )
            );

            admin.setRole("BANK_ADMIN");
            admin.setEnabled(true);

            userRepository.save(admin);

            System.out.println(
                    "[ADMIN] Compte administrateur configuré avec succès."
            );
        };
    }
}