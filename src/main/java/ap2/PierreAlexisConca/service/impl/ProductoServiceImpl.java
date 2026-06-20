package ap2.PierreAlexisConca.service.impl;

import ap2.PierreAlexisConca.model.Producto;
import ap2.PierreAlexisConca.repository.ProductoRepository;
import ap2.PierreAlexisConca.service.ProductoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Objects;
import java.util.Optional;

@Service
public class ProductoServiceImpl implements ProductoService {
    private final ProductoRepository productoRepository;

    @Autowired
    public ProductoServiceImpl(ProductoRepository productoRepository) {
        this.productoRepository = productoRepository;
    }

    @Override
    public List<Producto> findAll() {
        return productoRepository.findAll();
    }

    @Override
    public List<Producto> findByState(String state) {
        return productoRepository.findByState(state);
    }

    @Override
    public Optional<Producto> findById(Long id) {
        return productoRepository.findById(Objects.requireNonNull(id, "id no puede ser null"));
    }

    @Override
    public Producto save(Producto producto) {
        if (producto.getCodigo() == null || producto.getCodigo().isBlank()) {
            producto.setCodigo("PROD-" + System.currentTimeMillis());
        }
        if (producto.getStock() == null) {
            producto.setStock(100);
        }
        if (producto.getStock() < 0) {
            throw new IllegalArgumentException("El stock no puede ser negativo");
        }
        if (producto.getState() == null || producto.getState().isBlank()) {
            producto.setState("A");
        }
        return productoRepository.save(producto);
    }

    @Override
    public Producto update(Producto producto) {
        Long productoId = Objects.requireNonNull(producto.getId(), "producto.id no puede ser null");
        Producto existing = productoRepository.findById(productoId)
                .orElseThrow(() -> new RuntimeException("Producto not found"));

        if (producto.getCodigo() == null || producto.getCodigo().isBlank()) {
            producto.setCodigo(existing.getCodigo());
        }
        if (producto.getStock() == null) {
            producto.setStock(existing.getStock() == null ? 100 : existing.getStock());
        }
        if (producto.getStock() < 0) {
            throw new IllegalArgumentException("El stock no puede ser negativo");
        }
        if (producto.getState() == null || producto.getState().isBlank()) {
            producto.setState(existing.getState());
        }
        return productoRepository.save(producto);
    }

    @Override
    public Producto delete(Long id) {
        Producto producto = productoRepository.findById(Objects.requireNonNull(id, "id no puede ser null"))
                .orElseThrow(() -> new RuntimeException("Producto not found"));

        producto.setState("I");
        return productoRepository.save(producto);
    }

    @Override
    public Producto restore(Long id) {
        Producto producto = productoRepository.findById(Objects.requireNonNull(id, "id no puede ser null"))
                .orElseThrow(() -> new RuntimeException("Producto not found"));

        producto.setState("A");
        return productoRepository.save(producto);
    }
}
