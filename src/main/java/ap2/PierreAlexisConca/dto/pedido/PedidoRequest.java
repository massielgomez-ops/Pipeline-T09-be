package ap2.PierreAlexisConca.dto.pedido;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;
import java.util.List;

@Data
public class PedidoRequest {
    @NotNull(message = "fecha es obligatoria")
    private LocalDate fecha;

    @NotNull(message = "clienteId es obligatorio")
    private Long clienteId;

    @NotBlank(message = "metodoPago es obligatorio")
    private String metodoPago;

    @NotEmpty(message = "detalle debe incluir al menos un item")
    @Valid
    private List<DetallePedidoRequest> detalle;

    @DecimalMin(value = "0.0", inclusive = true, message = "total no puede ser negativo")
    private Double total;
}
