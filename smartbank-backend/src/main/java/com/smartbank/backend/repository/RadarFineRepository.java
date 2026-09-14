package com.smartbank.backend.repository;

import com.smartbank.backend.entity.RadarFine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface RadarFineRepository extends JpaRepository<RadarFine, Long> {

    @Query("""
        SELECT r
        FROM RadarFine r
        WHERE REPLACE(r.immatriculation, ' ', '') = :immatriculation
          AND r.paid = false
    """)
    List<RadarFine> findUnpaidByNormalizedImmatriculation(
            @Param("immatriculation") String immatriculation
    );

    Optional<RadarFine> findByReference(String reference);
}