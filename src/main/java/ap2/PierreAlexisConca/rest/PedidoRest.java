package ap2.PierreAlexisConca.rest;

import ap2.PierreAlexisConca.dto.pedido.PedidoRequest;
import ap2.PierreAlexisConca.dto.pedido.PedidoResponse;
import ap2.PierreAlexisConca.service.PedidoService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/pedidos")
public class PedidoRest {
    private final PedidoService pedidoService;

    @Autowired
    public PedidoRest(PedidoService pedidoService) {
        this.pedidoService = pedidoService;
    }

    @GetMapping
    public List<PedidoResponse> getAllPedidos() {
        return pedidoService.findAll();
    }

    @GetMapping("/state/{state}")
    public List<PedidoResponse> findByState(@PathVariable String state) {
        return pedidoService.findByState(state);
    }

    @GetMapping("/{id}")
    public ResponseEntity<PedidoResponse> getPedidoById(@PathVariable Long id) {
        Optional<PedidoResponse> pedido = pedidoService.findById(id);
        return pedido.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping
    public PedidoResponse createPedido(@Valid @RequestBody PedidoRequest pedidoRequest) {
        return pedidoService.save(pedidoRequest);
    }

    @PutMapping("/{id}")
    public ResponseEntity<PedidoResponse> updatePedido(@PathVariable Long id, @Valid @RequestBody PedidoRequest pedidoRequest) {
        if (!pedidoService.findById(id).isPresent()) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(pedidoService.update(id, pedidoRequest));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePedido(@PathVariable Long id) {
        if (!pedidoService.findById(id).isPresent()) {
            return ResponseEntity.notFound().build();
        }
        pedidoService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/{id}/delete")
    public ResponseEntity<PedidoResponse> logicalDeletePedido(@PathVariable Long id) {
        if (pedidoService.findById(id).isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(pedidoService.delete(id));
    }

    @PatchMapping("/{id}/restore")
    public ResponseEntity<PedidoResponse> restorePedido(@PathVariable Long id) {
        if (pedidoService.findById(id).isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(pedidoService.restore(id));
    }
}
