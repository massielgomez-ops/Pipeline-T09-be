package ap2.PierreAlexisConca.dto.pedido;

import lombok.Data;

@Data
public class DetallePedidoResponse {
    private Long id;
    private Long productoId;
    private String productoNombre;
    private Integer cantidad;
    private Double precioUnitario;
    private Double subtotal;
}
