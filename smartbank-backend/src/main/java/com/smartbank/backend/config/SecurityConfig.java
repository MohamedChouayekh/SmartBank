package com.smartbank.backend.config;

import com.smartbank.backend.entity.User;
import com.smartbank.backend.repository.UserRepository;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
public class SecurityConfig {

    // =========================================================
    // SECURITY FILTER CHAIN
    // =========================================================

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http
    ) throws Exception {

        http
                // -------------------------------------------------
                // CSRF
                // -------------------------------------------------
                .csrf(csrf -> csrf.disable())

                // -------------------------------------------------
                // CORS
                // -------------------------------------------------
                .cors(cors -> cors.configurationSource(
                        corsConfigurationSource()
                ))

                // -------------------------------------------------
                // AUTORISATION
                // -------------------------------------------------
                .authorizeHttpRequests(auth -> auth

                        // OPTIONS autorisé pour CORS
                        .requestMatchers(
                                HttpMethod.OPTIONS,
                                "/**"
                        ).permitAll()

                        // =================================================
                        // ADMIN UNIQUEMENT
                        // =================================================

                        .requestMatchers(
                                "/api/admin/**",
                                "/api/cards/admin/**"
                        ).hasRole("BANK_ADMIN")

                        // =================================================
                        // API PUBLIQUES / CLIENT
                        // =================================================

                        .requestMatchers(
                                "/api/**"
                        ).permitAll()

                        // -------------------------------------------------
                        // Tout le reste
                        // -------------------------------------------------

                        .anyRequest().permitAll()
                )

                // =========================================================
                // HTTP BASIC
                // =========================================================
                //
                // Utilisé uniquement lorsqu'une route ADMIN est appelée.
                //
                .httpBasic(Customizer.withDefaults());

        return http.build();
    }

    // =========================================================
    // USER DETAILS SERVICE
    // =========================================================
    //
    // Spring Security récupère l'utilisateur directement depuis
    // la table users.
    //
    // Le rôle BANK_ADMIN présent dans User.role devient :
    //
    // ROLE_BANK_ADMIN
    //
    // ce qui permet à hasRole("BANK_ADMIN") de fonctionner.
    // =========================================================

    @Bean
    public UserDetailsService userDetailsService(
            UserRepository userRepository
    ) {

        return username -> {

            User user = userRepository
                    .findByUsername(username)
                    .orElseThrow(() ->
                            new UsernameNotFoundException(
                                    "Utilisateur introuvable."
                            )
                    );

            if (!user.isEnabled()) {
                throw new UsernameNotFoundException(
                        "Utilisateur désactivé."
                );
            }

            String role = user.getRole();

            if (role == null ||
                    role.trim().isEmpty()) {

                role = "CLIENT";
            }

            return org.springframework.security.core.userdetails.User
                    .withUsername(user.getUsername())
                    .password(user.getPassword())
                    .roles(role.trim())
                    .disabled(!user.isEnabled())
                    .build();
        };
    }

    // =========================================================
    // CORS
    // =========================================================

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {

        CorsConfiguration configuration =
                new CorsConfiguration();

        configuration.setAllowedOriginPatterns(
                List.of(
                        "http://localhost:*",
                        "http://127.0.0.1:*",
                        "https://localhost:*",
                        "https://127.0.0.1:*"
                )
        );

        configuration.setAllowedMethods(
                List.of(
                        HttpMethod.GET.name(),
                        HttpMethod.POST.name(),
                        HttpMethod.PUT.name(),
                        HttpMethod.DELETE.name(),
                        HttpMethod.PATCH.name(),
                        HttpMethod.OPTIONS.name()
                )
        );

        configuration.setAllowedHeaders(
                List.of("*")
        );

        configuration.setExposedHeaders(
                List.of("*")
        );

        configuration.setAllowCredentials(false);

        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source =
                new UrlBasedCorsConfigurationSource();

        source.registerCorsConfiguration(
                "/**",
                configuration
        );

        return source;
    }

    // =========================================================
    // PASSWORD ENCODER
    // =========================================================

    @Bean
    public PasswordEncoder passwordEncoder() {

        return new BCryptPasswordEncoder();
    }
}