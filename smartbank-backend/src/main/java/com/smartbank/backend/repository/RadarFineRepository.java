package com.smartbank.backend.repository;

import com.smartbank.backend.entity.RadarFine;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface RadarFineRepository extends JpaRepository<RadarFine, Long> {
    List<RadarFine> findByImmatriculationAndPaidFalse(String immatriculation);
    Optional<RadarFine> findByReference(String reference);
}