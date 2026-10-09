
package com.smartbank.backend.repository;

import com.smartbank.backend.entity.Invoice;

import jakarta.persistence.LockModeType;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface InvoiceRepository
        extends JpaRepository<Invoice, Long> {

    List<Invoice>
    findByBillerIgnoreCaseAndCustomerReferenceOrderByDueDateDesc(
            String biller,
            String customerReference
    );

    List<Invoice>
    findByBillerIgnoreCaseAndCustomerReferenceAndStatusOrderByDueDateDesc(
            String biller,
            String customerReference,
            String status
    );

    Optional<Invoice> findByInvoiceNumber(String invoiceNumber);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT i FROM Invoice i WHERE i.invoiceNumber = :invoiceNumber")
    Optional<Invoice> findByInvoiceNumberForUpdate(
            @Param("invoiceNumber") String invoiceNumber
    );
}