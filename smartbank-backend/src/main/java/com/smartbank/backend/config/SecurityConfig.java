package com.smartbank.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http
    ) throws Exception {

        http
                // =====================================================
                // CSRF
                // =====================================================
                .csrf(csrf -> csrf.disable())

                // =====================================================
                // CORS
                // =====================================================
                .cors(cors -> cors.configurationSource(
                        corsConfigurationSource()
                ))

                // =====================================================
                // AUTORISATION
                // =====================================================
                .authorizeHttpRequests(auth -> auth

                        // Requêtes preflight envoyées par les navigateurs
                        .requestMatchers(
                                HttpMethod.OPTIONS,
                                "/**"
                        ).permitAll()

                        // Toutes les API SmartBank
                        .requestMatchers(
                                "/api/**"
                        ).permitAll()

                        // Autres endpoints
                        .anyRequest().permitAll()
                );

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {

        CorsConfiguration configuration =
                new CorsConfiguration();

        // =====================================================
        // ORIGINES AUTORISÉES
        // =====================================================
        //
        // Flutter Web s'exécute actuellement depuis une adresse
        // du type :
        //
        // http://localhost:65101
        //
        // Le port peut changer, donc on autorise les origines
        // localhost quel que soit leur port.
        //
        // On autorise également les autres origines nécessaires
        // au fonctionnement de l'application.
        //
        configuration.setAllowedOriginPatterns(
                List.of(
                        "http://localhost:*",
                        "http://127.0.0.1:*",
                        "https://localhost:*",
                        "https://127.0.0.1:*"
                )
        );

        // =====================================================
        // MÉTHODES HTTP AUTORISÉES
        // =====================================================
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

        // =====================================================
        // HEADERS AUTORISÉS
        // =====================================================
        configuration.setAllowedHeaders(
                List.of("*")
        );

        // =====================================================
        // HEADERS EXPOSÉS AU CLIENT
        // =====================================================
        configuration.setExposedHeaders(
                List.of("*")
        );

        // =====================================================
        // CREDENTIALS
        // =====================================================
        //
        // SmartBank n'utilise pas de cookies HTTP pour
        // l'authentification.
        //
        configuration.setAllowCredentials(false);

        // =====================================================
        // CACHE DES REQUÊTES PREFLIGHT
        // =====================================================
        configuration.setMaxAge(3600L);

        // =====================================================
        // APPLICATION DE LA CONFIGURATION À TOUS LES ENDPOINTS
        // =====================================================
        UrlBasedCorsConfigurationSource source =
                new UrlBasedCorsConfigurationSource();

        source.registerCorsConfiguration(
                "/**",
                configuration
        );

        return source;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}