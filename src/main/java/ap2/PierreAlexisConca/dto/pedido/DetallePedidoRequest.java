package ap2.PierreAlexisConca.dto.pedido;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Max;
import lombok.Data;

@Data
public class DetallePedidoRequest {
    @NotNull(message = "productoId es obligatorio")
    private Long productoId;

    @NotNull(message = "cantidad es obligatoria")
    @Min(value = 1, message = "cantidad debe ser mayor o igual a 1")
    @Max(value = 9999999, message = "cantidad debe tener máximo 7 dígitos")
    private Integer cantidad;

    @NotNull(message = "precioUnitario es obligatorio")
    @DecimalMin(value = "0.0", inclusive = false, message = "precioUnitario debe ser mayor a 0")
    private Double precioUnitario;

    @DecimalMin(value = "0.0", inclusive = true, message = "subtotal no puede ser negativo")
    private Double subtotal;
}
