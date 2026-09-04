package com.smartbank.backend.service;

import com.smartbank.backend.entity.RadarFine;
import com.smartbank.backend.repository.RadarFineRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class RadarFineService {

    private final RadarFineRepository radarFineRepository;

    public RadarFineService(RadarFineRepository radarFineRepository) {
        this.radarFineRepository = radarFineRepository;
    }

    public List<RadarFine> findUnpaidByImmatriculation(String immatriculation) {
        return radarFineRepository.findByImmatriculationAndPaidFalse(immatriculation);
    }

    public boolean payFine(String reference) {
        Optional<RadarFine> fineOptional = radarFineRepository.findByReference(reference);

        if (fineOptional.isEmpty()) {
            return false;
        }

        RadarFine fine = fineOptional.get();

        if (fine.isPaid()) {
            return false;
        }

        fine.setPaid(true);
        radarFineRepository.save(fine);

        return true;
    }
}