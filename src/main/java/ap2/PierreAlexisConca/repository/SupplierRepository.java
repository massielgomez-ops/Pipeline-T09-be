package ap2.PierreAlexisConca.repository;

import ap2.PierreAlexisConca.model.Supplier;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SupplierRepository extends JpaRepository<Supplier, Long> {

    List<Supplier> findByState(String state);
}