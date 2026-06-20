package ap2.PierreAlexisConca.service;

import ap2.PierreAlexisConca.model.Supplier;

import java.util.List;
import java.util.Optional;

public interface SupplierService {

    List<Supplier> findAll();

    List<Supplier> findByState(String state);

    Optional<Supplier> findById(Long id);

    Supplier save(Supplier supplier);

    Supplier update(Supplier supplier);

    Supplier delete(Long id);

    Supplier restore(Long id);
}