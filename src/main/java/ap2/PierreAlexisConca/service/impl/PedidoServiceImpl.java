package ap2.PierreAlexisConca.service.impl;

import ap2.PierreAlexisConca.dto.pedido.DetallePedidoRequest;
import ap2.PierreAlexisConca.dto.pedido.PedidoRequest;
import ap2.PierreAlexisConca.dto.pedido.PedidoResponse;
import ap2.PierreAlexisConca.mapper.PedidoMapper;
import ap2.PierreAlexisConca.model.Cliente;
import ap2.PierreAlexisConca.model.DetallePedido;
import ap2.PierreAlexisConca.model.Pedido;
import ap2.PierreAlexisConca.model.Producto;
import ap2.PierreAlexisConca.repository.ClienteRepository;
import ap2.PierreAlexisConca.repository.PedidoRepository;
import ap2.PierreAlexisConca.repository.ProductoRepository;
import ap2.PierreAlexisConca.service.PedidoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class PedidoServiceImpl implements PedidoService {
    private final PedidoRepository pedidoRepository;
    private final ClienteRepository clienteRepository;
    private final ProductoRepository productoRepository;
    private final PedidoMapper pedidoMapper;

    @Autowired
    public PedidoServiceImpl(PedidoRepository pedidoRepository,
                            ClienteRepository clienteRepository,
                            ProductoRepository productoRepository,
                            PedidoMapper pedidoMapper) {
        this.pedidoRepository = pedidoRepository;
        this.clienteRepository = clienteRepository;
        this.productoRepository = productoRepository;
        this.pedidoMapper = pedidoMapper;
    }

    @Override
    @Transactional(readOnly = true)
    public List<PedidoResponse> findAll() {
        return pedidoRepository.findAll().stream()
                .map(pedidoMapper::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<PedidoResponse> findByState(String state) {
        return pedidoRepository.findByState(state).stream()
                .map(pedidoMapper::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<PedidoResponse> findById(Long id) {
        return pedidoRepository.findById(Objects.requireNonNull(id, "id no puede ser null")).map(pedidoMapper::toResponse);
    }

    @Override
    @Transactional
    public PedidoResponse save(PedidoRequest pedidoRequest) {
        Pedido pedido = new Pedido();
        applyRequestToPedido(pedido, pedidoRequest);

        if (pedido.getNumero() == null || pedido.getNumero().isBlank()) {
            pedido.setNumero("PED-" + System.currentTimeMillis());
        }
        if (pedido.getState() == null || pedido.getState().isBlank()) {
            pedido.setState("A");
        }

        Pedido saved = pedidoRepository.save(pedido);
        return pedidoMapper.toResponse(saved);
    }

    @Override
    @Transactional
    public PedidoResponse update(Long id, PedidoRequest pedidoRequest) {
        Pedido existing = pedidoRepository.findById(Objects.requireNonNull(id, "id no puede ser null"))
                .orElseThrow(() -> new RuntimeException("Pedido not found"));

        applyRequestToPedido(existing, pedidoRequest);

        if (existing.getNumero() == null || existing.getNumero().isBlank()) {
            existing.setNumero("PED-" + System.currentTimeMillis());
        }
        if (existing.getState() == null || existing.getState().isBlank()) {
            existing.setState("A");
        }

        Pedido updated = pedidoRepository.save(existing);
        return pedidoMapper.toResponse(updated);
    }

    @Override
    @Transactional
    public PedidoResponse delete(Long id) {
        Pedido pedido = pedidoRepository.findById(Objects.requireNonNull(id, "id no puede ser null"))
                .orElseThrow(() -> new RuntimeException("Pedido not found"));

        pedido.setState("I");
        Pedido updated = pedidoRepository.save(pedido);
        return pedidoMapper.toResponse(updated);
    }

    @Override
    @Transactional
    public PedidoResponse restore(Long id) {
        Pedido pedido = pedidoRepository.findById(Objects.requireNonNull(id, "id no puede ser null"))
                .orElseThrow(() -> new RuntimeException("Pedido not found"));

        pedido.setState("A");
        Pedido updated = pedidoRepository.save(pedido);
        return pedidoMapper.toResponse(updated);
    }

    private void applyRequestToPedido(Pedido pedido, PedidoRequest pedidoRequest) {
        Long clienteId = Objects.requireNonNull(pedidoRequest.getClienteId(), "clienteId no puede ser null");
        Cliente cliente = clienteRepository.findById(clienteId)
                .orElseThrow(() -> new RuntimeException("Cliente not found"));

        pedido.setFecha(pedidoRequest.getFecha());
        pedido.setCliente(cliente);
        pedido.setMetodoPago(normalizeMetodoPago(pedidoRequest.getMetodoPago()));

        List<DetallePedido> nuevosDetalles = new ArrayList<>();
        double totalCalculado = 0.0;

        for (DetallePedidoRequest item : pedidoRequest.getDetalle()) {
            Long productoId = Objects.requireNonNull(item.getProductoId(), "productoId no puede ser null");
            Producto producto = productoRepository.findById(productoId)
                    .orElseThrow(() -> new RuntimeException("Producto not found"));

            double subtotalCalculado = item.getCantidad() * item.getPrecioUnitario();
            if (item.getSubtotal() != null && Math.abs(item.getSubtotal() - subtotalCalculado) > 0.01) {
                throw new IllegalArgumentException("Subtotal invalido para productoId " + item.getProductoId());
            }

            DetallePedido detalle = new DetallePedido();
            detalle.setPedido(pedido);
            detalle.setProducto(producto);
            detalle.setCantidad(item.getCantidad());
            detalle.setPrecioUnitario(item.getPrecioUnitario());
            detalle.setSubtotal(round2(subtotalCalculado));

            nuevosDetalles.add(detalle);
            totalCalculado += subtotalCalculado;
        }

        double totalRedondeado = round2(totalCalculado);
        if (pedidoRequest.getTotal() != null && Math.abs(pedidoRequest.getTotal() - totalRedondeado) > 0.01) {
            throw new IllegalArgumentException("El total enviado no coincide con la suma del detalle");
        }

        pedido.setTotal(totalRedondeado);
        pedido.getDetalle().clear();
        pedido.getDetalle().addAll(nuevosDetalles);
    }

    private String normalizeMetodoPago(String metodoPago) {
        String normalizado = metodoPago == null ? "" : metodoPago.trim().toLowerCase();
        if (!normalizado.equals("efectivo") && !normalizado.equals("digital")) {
            throw new IllegalArgumentException("metodoPago solo admite: efectivo o digital");
        }
        return normalizado;
    }

    private double round2(double value) {
        return Math.round(value * 100.0) / 100.0;
    }
}
