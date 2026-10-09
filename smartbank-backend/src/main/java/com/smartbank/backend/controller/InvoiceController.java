
package com.smartbank.backend.controller;

import com.smartbank.backend.entity.Invoice;
import com.smartbank.backend.service.InvoiceService;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/invoices")
public class InvoiceController {

    private final InvoiceService invoiceService;

    public InvoiceController(InvoiceService invoiceService) {
        this.invoiceService = invoiceService;
    }

    @GetMapping
    public ResponseEntity<?> getInvoices(
            @RequestParam String biller,
            @RequestParam String reference) {

        try {
            List<Invoice> invoices =
                    invoiceService.findInvoices(biller, reference);

            return ResponseEntity.ok(invoices);

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(
                    Map.of("message", e.getMessage())
            );
        }
    }

    @PostMapping("/pay")
    public ResponseEntity<?> payInvoice(
            @RequestBody Map<String, Object> request) {

        try {
            Object accountValue = request.get("accountNumber");
            Object invoiceValue = request.get("invoiceNumber");

            if (accountValue == null || invoiceValue == null) {
                return ResponseEntity.badRequest().body(
                        Map.of(
                                "message",
                                "Le compte et le numéro de facture sont obligatoires."
                        )
                );
            }

            invoiceService.payInvoice(
                    accountValue.toString().trim(),
                    invoiceValue.toString().trim()
            );

            return ResponseEntity.ok(
                    Map.of("message", "Facture payée avec succès.")
            );

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(
                    Map.of("message", e.getMessage())
            );
        }
    }
}