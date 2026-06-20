package ap2.PierreAlexisConca.mapper;

import ap2.PierreAlexisConca.dto.pedido.DetallePedidoResponse;
import ap2.PierreAlexisConca.dto.pedido.PedidoResponse;
import ap2.PierreAlexisConca.model.DetallePedido;
import ap2.PierreAlexisConca.model.Pedido;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

@Component
public class PedidoMapper {

    public PedidoResponse toResponse(Pedido pedido) {
        PedidoResponse response = new PedidoResponse();
        response.setId(pedido.getId());
        response.setNumero(pedido.getNumero());
        response.setFecha(pedido.getFecha());
        response.setClienteId(pedido.getCliente().getId());
        response.setClienteNombre(pedido.getCliente().getNombre() + " " + pedido.getCliente().getApellido());
        response.setMetodoPago(pedido.getMetodoPago());

        List<DetallePedidoResponse> detalle = pedido.getDetalle().stream()
                .map(this::toDetalleResponse)
                .collect(Collectors.toList());

        response.setDetalle(detalle);
        response.setCantidadItems(detalle.stream().mapToInt(DetallePedidoResponse::getCantidad).sum());
        response.setResumenProductos(detalle.stream()
                .map(d -> d.getProductoNombre() + " x" + d.getCantidad())
                .collect(Collectors.joining(", ")));
        response.setTotal(pedido.getTotal());
        response.setState(pedido.getState());
        return response;
    }

    private DetallePedidoResponse toDetalleResponse(DetallePedido detalle) {
        DetallePedidoResponse response = new DetallePedidoResponse();
        response.setId(detalle.getId());
        response.setProductoId(detalle.getProducto().getId());
        response.setProductoNombre(detalle.getProducto().getNombre());
        response.setCantidad(detalle.getCantidad());
        response.setPrecioUnitario(detalle.getPrecioUnitario());
        response.setSubtotal(detalle.getSubtotal());
        return response;
    }
}
