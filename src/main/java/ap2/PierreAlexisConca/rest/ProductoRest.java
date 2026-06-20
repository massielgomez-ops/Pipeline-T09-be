package ap2.PierreAlexisConca.rest;

import ap2.PierreAlexisConca.dto.producto.ProductoRequest;
import ap2.PierreAlexisConca.model.Producto;
import ap2.PierreAlexisConca.service.ProductoService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/productos")
public class ProductoRest {
    private final ProductoService productoService;

    @Autowired
    public ProductoRest(ProductoService productoService) {
        this.productoService = productoService;
    }

    @GetMapping
    public List<Producto> getAllProductos() {
        return productoService.findAll();
    }

    @GetMapping("/state/{state}")
    public List<Producto> findByState(@PathVariable String state) {
        return productoService.findByState(state);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Producto> getProductoById(@PathVariable Long id) {
        Optional<Producto> producto = productoService.findById(id);
        return producto.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping
    public Producto createProducto(@Valid @RequestBody ProductoRequest productoRequest) {
        return productoService.save(toProducto(productoRequest));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Producto> updateProducto(@PathVariable Long id, @Valid @RequestBody ProductoRequest productoRequest) {
        if (!productoService.findById(id).isPresent()) {
            return ResponseEntity.notFound().build();
        }
        Producto producto = toProducto(productoRequest);
        producto.setId(id);
        return ResponseEntity.ok(productoService.update(producto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteProducto(@PathVariable Long id) {
        if (!productoService.findById(id).isPresent()) {
            return ResponseEntity.notFound().build();
        }
        productoService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/{id}/delete")
    public ResponseEntity<Producto> logicalDeleteProducto(@PathVariable Long id) {
        if (productoService.findById(id).isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(productoService.delete(id));
    }

    @PatchMapping("/{id}/restore")
    public ResponseEntity<Producto> restoreProducto(@PathVariable Long id) {
        if (productoService.findById(id).isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(productoService.restore(id));
    }

    private Producto toProducto(ProductoRequest request) {
        Producto producto = new Producto();
        producto.setNombre(request.getNombre());
        producto.setDescripcion(request.getDescripcion());
        producto.setPrecio(request.getPrecio());
        producto.setCodigo(request.getCodigo());
        producto.setStock(request.getStock());
        producto.setState(request.getState());
        return producto;
    }
}
