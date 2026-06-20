package ap2.PierreAlexisConca.rest;

import ap2.PierreAlexisConca.model.Supplier;
import ap2.PierreAlexisConca.service.SupplierService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/proveedores")
@CrossOrigin(origins = "http://localhost:4200")
public class SupplierRest {

    private final SupplierService supplierService;

    @Autowired
    public SupplierRest(SupplierService supplierService) {
        this.supplierService = supplierService;
    }

    @GetMapping
    public List<Supplier> findAll() {
        return supplierService.findAll();
    }

    @GetMapping("/state/{state}")
    public List<Supplier> findByState(@PathVariable String state) {
        return supplierService.findByState(state);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Supplier> findById(@PathVariable Long id) {
        Optional<Supplier> supplier = supplierService.findById(id);
        return supplier.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
    }


    @PostMapping
    public Supplier save(@Valid @RequestBody Supplier supplier) {
        return supplierService.save(supplier);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Supplier> update(@PathVariable Long id, @Valid @RequestBody Supplier supplier) {
        if (supplierService.findById(id).isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        supplier.setId(id);
        return ResponseEntity.ok(supplierService.update(supplier));
    }

    @PatchMapping("/{id}/delete")
    public ResponseEntity<Supplier> delete(@PathVariable Long id) {
        if (supplierService.findById(id).isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(supplierService.delete(id));
    }

    @PatchMapping("/{id}/restore")
    public ResponseEntity<Supplier> restore(@PathVariable Long id) {
        if (supplierService.findById(id).isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(supplierService.restore(id));
    }
}
