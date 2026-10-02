package com.smartbank.backend.repository;

import com.smartbank.backend.entity.PartnerPromotion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface PartnerPromotionRepository
        extends JpaRepository<PartnerPromotion, Long> {

    @Query("""
            SELECT promotion
            FROM PartnerPromotion promotion
            JOIN FETCH promotion.partnerEstablishment establishment
            ORDER BY promotion.startDate DESC
            """)
    List<PartnerPromotion> findAllWithEstablishment();

    @Query("""
            SELECT promotion
            FROM PartnerPromotion promotion
            JOIN FETCH promotion.partnerEstablishment
            WHERE promotion.id = :id
            """)
    Optional<PartnerPromotion> findWithEstablishmentById(@Param("id") Long id);

    @Query("""
            SELECT promotion
            FROM PartnerPromotion promotion
            JOIN FETCH promotion.partnerEstablishment establishment
            WHERE promotion.active = true
              AND establishment.active = true
              AND promotion.startDate <= :now
              AND promotion.endDate >= :now
            ORDER BY promotion.startDate ASC
            """)
    List<PartnerPromotion> findCurrentlyActive(
            @Param("now") LocalDateTime now);

    @Query("""
            SELECT promotion
            FROM PartnerPromotion promotion
            JOIN FETCH promotion.partnerEstablishment establishment
            WHERE promotion.id = :id
              AND promotion.active = true
              AND establishment.active = true
              AND promotion.startDate <= :now
              AND promotion.endDate >= :now
            """)
    Optional<PartnerPromotion> findCurrentlyActiveById(
            @Param("id") Long id,
            @Param("now") LocalDateTime now);

    @Query("""
            SELECT promotion
            FROM PartnerPromotion promotion
            JOIN FETCH promotion.partnerEstablishment establishment
            WHERE establishment.id = :establishmentId
              AND promotion.active = true
              AND establishment.active = true
              AND promotion.startDate <= :now
              AND promotion.endDate >= :now
            ORDER BY promotion.startDate ASC
            """)
    List<PartnerPromotion> findCurrentlyActiveByEstablishmentId(
            @Param("establishmentId") Long establishmentId,
            @Param("now") LocalDateTime now);
}