package ap2.PierreAlexisConca.service.impl;

import ap2.PierreAlexisConca.model.Supplier;
import ap2.PierreAlexisConca.repository.SupplierRepository;
import ap2.PierreAlexisConca.service.SupplierService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

@Slf4j
@Service
public class SupplierServiceImpl implements SupplierService {

    private final SupplierRepository supplierRepository;

    @Autowired
    public SupplierServiceImpl(SupplierRepository supplierRepository) {
        this.supplierRepository = supplierRepository;
    }

    @Override
    public List<Supplier> findAll() {
        return supplierRepository.findAll();
    }

    @Override
    public List<Supplier> findByState(String state) {
        return supplierRepository.findByState(state);
    }

    @Override
    public Optional<Supplier> findById(Long id) {
        return supplierRepository.findById(Objects.requireNonNull(id, "id no puede ser null"));
    }

    @Override
    public Supplier save(Supplier supplier) {
        supplier.setState("A");
        supplier.setCreatedAt(LocalDateTime.now());
        return supplierRepository.save(supplier);
    }

    @Override
    public Supplier update(Supplier supplier) {
        Long supplierId = Objects.requireNonNull(supplier.getId(), "supplier.id no puede ser null");
        Supplier existing = supplierRepository.findById(supplierId)
                .orElseThrow(() -> new RuntimeException("Supplier not found"));

        supplier.setCreatedAt(existing.getCreatedAt());
        supplier.setUpdatedAt(LocalDateTime.now());
        supplier.setState("A");

        return supplierRepository.save(supplier);
    }

    @Override
    public Supplier delete(Long id) {
        Supplier supplier = supplierRepository.findById(Objects.requireNonNull(id, "id no puede ser null"))
                .orElseThrow(() -> new RuntimeException("Supplier not found"));

        supplier.setState("I");
        supplier.setDeletedAt(LocalDateTime.now());

        return supplierRepository.save(supplier);
    }

    @Override
    public Supplier restore(Long id) {
        Supplier supplier = supplierRepository.findById(Objects.requireNonNull(id, "id no puede ser null"))
                .orElseThrow(() -> new RuntimeException("Supplier not found"));

        supplier.setState("A");
        supplier.setRestoredAt(LocalDateTime.now());

        return supplierRepository.save(supplier);
    }
}