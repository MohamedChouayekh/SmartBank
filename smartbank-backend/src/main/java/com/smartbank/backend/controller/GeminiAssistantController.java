
package com.smartbank.backend.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.Map;
import java.util.List;

@RestController
@RequestMapping("/api/assistant")
public class GeminiAssistantController {

    @Value("${gemini.api.key:}")
    private String apiKey;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper mapper = new ObjectMapper();

    private static final String API_URL =
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

    private static final String CONTEXT = """
        Tu es SmartBank Assistant, l'assistant pédagogique d'une
        application bancaire tunisienne appelée SmartBank.
        Réponds en français, simplement et poliment.
        Tu peux expliquer les cartes, les paiements, les factures,
        l'épargne, le cashback et le programme de fidélité.
        Ne prétends jamais avoir accès au solde, aux cartes ou aux
        opérations réelles d'un client.
        N'invente pas de fonctionnalités ou de conditions inconnues.
        Ne demande jamais de mot de passe, de code OTP ou de numéro
        complet de carte bancaire.
        Pour les problèmes de compte personnels, oriente l'utilisateur
        vers la rubrique Aide et Support.
        """;

    public record ChatRequest(String message) {}
    public record ChatResponse(String reply) {}

    @PostMapping("/chat")
    public ResponseEntity<ChatResponse> chat(
            @RequestBody ChatRequest request) {

        if (request.message() == null ||
                request.message().isBlank() ||
                request.message().length() > 2000) {
            return ResponseEntity.badRequest()
                    .body(new ChatResponse(
                            "Écris une question de 1 à 2000 caractères."));
        }

        if (apiKey == null || apiKey.isBlank()) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(new ChatResponse(
                            "L'assistant IA n'est pas encore configuré."));
        }

        try {
            String prompt = CONTEXT + "\n\nQuestion : "
                    + request.message();

            Map<String, Object> body = Map.of(
                    "contents", List.of(
                            Map.of("parts", List.of(
                                    Map.of("text", prompt)
                            ))
                    ),
                    "generationConfig", Map.of(
                            "temperature", 0.4,
                            "maxOutputTokens", 500
                    )
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("x-goog-api-key", apiKey);

            ResponseEntity<String> response = restTemplate.exchange(
                    API_URL,
                    HttpMethod.POST,
                    new HttpEntity<>(body, headers),
                    String.class
            );

            JsonNode json = mapper.readTree(response.getBody());
            JsonNode text = json.path("candidates")
                    .path(0).path("content").path("parts").path(0).path("text");

            if (text.isMissingNode() || text.asText().isBlank()) {
                return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                        .body(new ChatResponse(
                                "Je n'ai pas pu générer de réponse. Réessaie."));
            }

            return ResponseEntity.ok(new ChatResponse(text.asText()));

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body(new ChatResponse(
                            "Le service IA est momentanément indisponible."));
        }
    }
}
