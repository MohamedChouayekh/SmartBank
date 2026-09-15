package com.smartbank.backend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Map;

@Service
public class EmailService {

    @Value("${RESEND_API_KEY:}")
    private String resendApiKey;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    public void sendOtpEmail(String email, String otp) {

        String text =
                "Bonjour,\n\n"
                        + "Vous avez demandé la réinitialisation "
                        + "de votre mot de passe SmartBank.\n\n"
                        + "Votre code de vérification est : "
                        + otp
                        + "\n\n"
                        + "Ce code est valable pendant 5 minutes.\n\n"
                        + "Si vous n'êtes pas à l'origine de cette demande, "
                        + "ignorez simplement cet e-mail.\n\n"
                        + "Cordialement,\n"
                        + "L'équipe SmartBank";

        try {

            if (resendApiKey == null || resendApiKey.trim().isEmpty()) {
                throw new IllegalStateException(
                        "RESEND_API_KEY n'est pas configurée."
                );
            }

            Map<String, Object> requestBody = Map.of(
                    "from", "SmartBank <onboarding@resend.dev>",
                    "to", new String[]{email},
                    "subject", "SmartBank - Code de vérification",
                    "text", text
            );

            String jsonBody =
                    objectMapper.writeValueAsString(requestBody);

            HttpRequest request =
                    HttpRequest.newBuilder()
                            .uri(URI.create(
                                    "https://api.resend.com/emails"
                            ))
                            .header(
                                    "Authorization",
                                    "Bearer " + resendApiKey
                            )
                            .header(
                                    "Content-Type",
                                    "application/json"
                            )
                            .header(
                                    "User-Agent",
                                    "SmartBank/1.0"
                            )
                            .POST(
                                    HttpRequest.BodyPublishers.ofString(
                                            jsonBody
                                    )
                            )
                            .build();

            HttpResponse<String> response =
                    httpClient.send(
                            request,
                            HttpResponse.BodyHandlers.ofString()
                    );

            if (response.statusCode() < 200 ||
                    response.statusCode() >= 300) {

                throw new IllegalStateException(
                        "Erreur Resend (" +
                                response.statusCode() +
                                "): " +
                                response.body()
                );
            }

        } catch (InterruptedException e) {

            Thread.currentThread().interrupt();

            throw new IllegalStateException(
                    "L'envoi de l'email a été interrompu.",
                    e
            );

        } catch (Exception e) {

            throw new IllegalStateException(
                    "Impossible d'envoyer l'email OTP via Resend.",
                    e
            );
        }
    }
}
