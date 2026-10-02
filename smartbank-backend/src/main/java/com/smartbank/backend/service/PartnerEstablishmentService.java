package com.smartbank.backend.service;

import com.smartbank.backend.dto.PartnerEstablishmentRequest;
import com.smartbank.backend.entity.PartnerEstablishment;
import com.smartbank.backend.repository.PartnerEstablishmentRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Service
public class PartnerEstablishmentService {

    private final PartnerEstablishmentRepository establishmentRepository;

    public PartnerEstablishmentService(
            PartnerEstablishmentRepository establishmentRepository) {
        this.establishmentRepository = establishmentRepository;
    }

    @Transactional(readOnly = true)
    public List<PartnerEstablishment> getAllEstablishments() {
        return establishmentRepository.findAllByOrderByNameAsc();
    }

    @Transactional(readOnly = true)
    public List<PartnerEstablishment> getActiveEstablishments() {
        return establishmentRepository.findAllByActiveTrueOrderByNameAsc();
    }

    @Transactional(readOnly = true)
    public Optional<PartnerEstablishment> getEstablishmentById(Long id) {
        return establishmentRepository.findById(id);
    }

    @Transactional(readOnly = true)
    public Optional<PartnerEstablishment> getActiveEstablishmentById(Long id) {
        return establishmentRepository.findByIdAndActiveTrue(id);
    }

    @Transactional
    public PartnerEstablishment createEstablishment(
            PartnerEstablishmentRequest request) {
        validateRequest(request);

        PartnerEstablishment establishment = new PartnerEstablishment();
        applyRequest(establishment, request);
        establishment.setActive(request.getActive() == null || request.getActive());

        return establishmentRepository.save(establishment);
    }

    @Transactional
    public Optional<PartnerEstablishment> updateEstablishment(
            Long id,
            PartnerEstablishmentRequest request) {
        validateRequest(request);

        Optional<PartnerEstablishment> establishmentOptional =
                establishmentRepository.findById(id);

        if (establishmentOptional.isEmpty()) {
            return Optional.empty();
        }

        PartnerEstablishment establishment = establishmentOptional.get();
        applyRequest(establishment, request);

        if (request.getActive() != null) {
            establishment.setActive(request.getActive());
        }

        return Optional.of(establishmentRepository.save(establishment));
    }

    @Transactional
    public boolean deactivateEstablishment(Long id) {
        Optional<PartnerEstablishment> establishmentOptional =
                establishmentRepository.findById(id);

        if (establishmentOptional.isEmpty()) {
            return false;
        }

        PartnerEstablishment establishment = establishmentOptional.get();
        establishment.setActive(false);
        establishmentRepository.save(establishment);
        return true;
    }

    private void applyRequest(
            PartnerEstablishment establishment,
            PartnerEstablishmentRequest request) {
        establishment.setName(request.getName().trim());
        establishment.setCategory(request.getCategory().trim());
        establishment.setCity(request.getCity().trim());
        establishment.setAddress(request.getAddress().trim());
        establishment.setLatitude(request.getLatitude());
        establishment.setLongitude(request.getLongitude());
    }

    private void validateRequest(PartnerEstablishmentRequest request) {
        if (request == null) {
            throw new IllegalArgumentException(
                    "Les informations de l'etablissement sont obligatoires.");
        }

        validateText(request.getName(), "Le nom", 150);
        validateText(request.getCategory(), "La categorie", 100);
        validateText(request.getCity(), "La ville", 100);
        validateText(request.getAddress(), "L'adresse", 255);

        if (request.getLatitude() == null
                || request.getLatitude().compareTo(BigDecimal.valueOf(-90)) < 0
                || request.getLatitude().compareTo(BigDecimal.valueOf(90)) > 0) {
            throw new IllegalArgumentException(
                    "La latitude doit etre comprise entre -90 et 90.");
        }

        if (request.getLongitude() == null
                || request.getLongitude().compareTo(BigDecimal.valueOf(-180)) < 0
                || request.getLongitude().compareTo(BigDecimal.valueOf(180)) > 0) {
            throw new IllegalArgumentException(
                    "La longitude doit etre comprise entre -180 et 180.");
        }
    }

    private void validateText(String value, String fieldName, int maxLength) {
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException(fieldName + " est obligatoire.");
        }

        if (value.trim().length() > maxLength) {
            throw new IllegalArgumentException(
                    fieldName + " ne doit pas depasser " + maxLength + " caracteres.");
        }
    }
}