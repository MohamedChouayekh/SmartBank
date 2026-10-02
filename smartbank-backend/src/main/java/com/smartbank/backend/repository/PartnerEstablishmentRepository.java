package com.smartbank.backend.repository;

import com.smartbank.backend.entity.PartnerEstablishment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PartnerEstablishmentRepository
        extends JpaRepository<PartnerEstablishment, Long> {

    List<PartnerEstablishment> findAllByOrderByNameAsc();

    List<PartnerEstablishment> findAllByActiveTrueOrderByNameAsc();

    Optional<PartnerEstablishment> findByIdAndActiveTrue(Long id);
}