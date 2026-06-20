package ap2.PierreAlexisConca.service;

import ap2.PierreAlexisConca.dto.pedido.PedidoRequest;
import ap2.PierreAlexisConca.dto.pedido.PedidoResponse;

import java.util.List;
import java.util.Optional;

public interface PedidoService {
    List<PedidoResponse> findAll();
    List<PedidoResponse> findByState(String state);
    Optional<PedidoResponse> findById(Long id);
    PedidoResponse save(PedidoRequest pedidoRequest);
    PedidoResponse update(Long id, PedidoRequest pedidoRequest);
    PedidoResponse delete(Long id);
    PedidoResponse restore(Long id);
}
