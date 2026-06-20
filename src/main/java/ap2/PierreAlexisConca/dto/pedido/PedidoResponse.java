package ap2.PierreAlexisConca.dto.pedido;

import lombok.Data;

import java.time.LocalDate;
import java.util.List;

@Data
public class PedidoResponse {
    private Long id;
    private String numero;
    private LocalDate fecha;
    private Long clienteId;
    private String clienteNombre;
    private String metodoPago;
    private List<DetallePedidoResponse> detalle;
    private Integer cantidadItems;
    private String resumenProductos;
    private Double total;
    private String state;
}
