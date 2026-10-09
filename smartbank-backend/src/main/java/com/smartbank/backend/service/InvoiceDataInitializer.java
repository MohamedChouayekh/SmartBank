
package com.smartbank.backend.service;

import com.smartbank.backend.entity.Invoice;
import com.smartbank.backend.repository.InvoiceRepository;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;

@Component
public class InvoiceDataInitializer implements CommandLineRunner {

    private final InvoiceRepository invoiceRepository;

    public InvoiceDataInitializer(InvoiceRepository invoiceRepository) {
        this.invoiceRepository = invoiceRepository;
    }

    @Override
    public void run(String... args) {

        // STEG : deux factures pour la même référence client
        createInvoice(
                "STEG-2026-001",
                "STEG",
                "12345678",
                "85.500",
                LocalDate.of(2026, 10, 15)
        );

        createInvoice(
                "STEG-2026-002",
                "STEG",
                "12345678",
                "112.300",
                LocalDate.of(2026, 11, 15)
        );

        // SONEDE
        createInvoice(
                "SONEDE-2026-001",
                "SONEDE",
                "87654321",
                "32.000",
                LocalDate.of(2026, 10, 20)
        );

        createInvoice(
                "SONEDE-2026-002",
                "SONEDE",
                "87654321",
                "41.750",
                LocalDate.of(2026, 11, 20)
        );

        // Tunisie Telecom : deux factures pour la même ligne
        createInvoice(
                "TT-2026-001",
                "Tunisie Telecom",
                "71111111",
                "45.000",
                LocalDate.of(2026, 10, 25)
        );

        createInvoice(
                "TT-2026-002",
                "Tunisie Telecom",
                "71111111",
                "29.900",
                LocalDate.of(2026, 11, 25)
        );
    }

    private void createInvoice(
            String invoiceNumber,
            String biller,
            String customerReference,
            String amount,
            LocalDate dueDate) {

        if (invoiceRepository.findByInvoiceNumber(invoiceNumber).isPresent()) {
            return;
        }

        Invoice invoice = new Invoice();
        invoice.setInvoiceNumber(invoiceNumber);
        invoice.setBiller(biller);
        invoice.setCustomerReference(customerReference);
        invoice.setAmount(new BigDecimal(amount));
        invoice.setDueDate(dueDate);
        invoice.setStatus("UNPAID");

        invoiceRepository.save(invoice);
    }
}