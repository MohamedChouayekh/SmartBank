package com.smartbank.backend.service;

import com.smartbank.backend.dto.PartnerPromotionRequest;
import com.smartbank.backend.entity.PartnerEstablishment;
import com.smartbank.backend.entity.PartnerPromotion;
import com.smartbank.backend.repository.PartnerEstablishmentRepository;
import com.smartbank.backend.repository.PartnerPromotionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

@Service
public class PartnerPromotionService {

    private static final ZoneId BUSINESS_TIME_ZONE = ZoneId.of("Africa/Tunis");

    private final PartnerPromotionRepository promotionRepository;
    private final PartnerEstablishmentRepository establishmentRepository;

    public PartnerPromotionService(
            PartnerPromotionRepository promotionRepository,
            PartnerEstablishmentRepository establishmentRepository) {
        this.promotionRepository = promotionRepository;
        this.establishmentRepository = establishmentRepository;
    }

    @Transactional(readOnly = true)
    public List<PartnerPromotion> getAllPromotions() {
        return promotionRepository.findAllWithEstablishment();
    }

    @Transactional(readOnly = true)
    public Optional<PartnerPromotion> getPromotionById(Long id) {
        return promotionRepository.findWithEstablishmentById(id);
    }

    @Transactional(readOnly = true)
    public List<PartnerPromotion> getCurrentlyActivePromotions() {
        LocalDateTime now = currentBusinessTime();
        return promotionRepository.findCurrentlyActive(now);
    }

    @Transactional(readOnly = true)
    public Optional<PartnerPromotion> getCurrentlyActivePromotionById(Long id) {
        LocalDateTime now = currentBusinessTime();
        return promotionRepository.findCurrentlyActiveById(id, now);
    }

    @Transactional(readOnly = true)
    public List<PartnerPromotion> getCurrentlyActivePromotionsByEstablishment(
            Long establishmentId) {
        LocalDateTime now = currentBusinessTime();
        return promotionRepository.findCurrentlyActiveByEstablishmentId(
                establishmentId,
                now
        );
    }

    @Transactional
    public PartnerPromotion createPromotion(PartnerPromotionRequest request) {
        validateRequest(request);

        PartnerEstablishment establishment = getEstablishment(request);
        PartnerPromotion promotion = new PartnerPromotion();
        applyRequest(promotion, request, establishment);
        promotion.setActive(request.getActive() == null || request.getActive());

        return promotionRepository.save(promotion);
    }

    @Transactional
    public Optional<PartnerPromotion> updatePromotion(
            Long id,
            PartnerPromotionRequest request) {
        validateRequest(request);

        Optional<PartnerPromotion> promotionOptional =
                promotionRepository.findWithEstablishmentById(id);

        if (promotionOptional.isEmpty()) {
            return Optional.empty();
        }

        PartnerEstablishment establishment = getEstablishment(request);
        PartnerPromotion promotion = promotionOptional.get();
        applyRequest(promotion, request, establishment);

        if (request.getActive() != null) {
            promotion.setActive(request.getActive());
        }

        return Optional.of(promotionRepository.save(promotion));
    }

    @Transactional
    public boolean deactivatePromotion(Long id) {
        Optional<PartnerPromotion> promotionOptional =
                promotionRepository.findById(id);

        if (promotionOptional.isEmpty()) {
            return false;
        }

        PartnerPromotion promotion = promotionOptional.get();
        promotion.setActive(false);
        promotionRepository.save(promotion);
        return true;
    }

    private LocalDateTime currentBusinessTime() {
        return LocalDateTime.now(BUSINESS_TIME_ZONE);
    }

    private PartnerEstablishment getEstablishment(
            PartnerPromotionRequest request) {
        return establishmentRepository.findById(request.getPartnerEstablishmentId())
                .orElseThrow(() -> new IllegalArgumentException(
                        "Etablissement partenaire introuvable."
                ));
    }

    private void applyRequest(
            PartnerPromotion promotion,
            PartnerPromotionRequest request,
            PartnerEstablishment establishment) {
        promotion.setPartnerEstablishment(establishment);
        promotion.setDiscountPercent(request.getDiscountPercent());
        promotion.setStartDate(request.getStartDate());
        promotion.setEndDate(request.getEndDate());

        String description = request.getDescription();
        promotion.setDescription(
                description == null || description.trim().isEmpty()
                        ? null
                        : description.trim()
        );
    }

    private void validateRequest(PartnerPromotionRequest request) {
        if (request == null) {
            throw new IllegalArgumentException(
                    "Les informations de la promotion sont obligatoires."
            );
        }

        if (request.getPartnerEstablishmentId() == null) {
            throw new IllegalArgumentException(
                    "L'etablissement partenaire est obligatoire."
            );
        }

        BigDecimal discountPercent = request.getDiscountPercent();
        if (discountPercent == null
                || discountPercent.compareTo(BigDecimal.ZERO) <= 0
                || discountPercent.compareTo(BigDecimal.valueOf(100)) > 0) {
            throw new IllegalArgumentException(
                    "La remise doit etre superieure a 0 et inferieure ou egale a 100."
            );
        }

        if (request.getStartDate() == null || request.getEndDate() == null) {
            throw new IllegalArgumentException(
                    "Les dates de debut et de fin sont obligatoires."
            );
        }

        if (!request.getStartDate().isBefore(request.getEndDate())) {
            throw new IllegalArgumentException(
                    "La date de debut doit etre anterieure a la date de fin."
            );
        }

        String description = request.getDescription();
        if (description != null && description.length() > 2000) {
            throw new IllegalArgumentException(
                    "La description ne doit pas depasser 2000 caracteres."
            );
        }
    }
}