package ap2.PierreAlexisConca.dto.producto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.DecimalMin;
import lombok.Data;

@Data
public class ProductoRequest {
    @NotBlank(message = "El nombre es obligatorio")
    @Pattern(regexp = "^[A-Za-zÁÉÍÓÚáéíóúÑñ0-9 ]{1,20}$", message = "El nombre solo puede contener letras, números y espacios, máximo 20 caracteres")
    private String nombre;

    @Size(max = 50, message = "La descripción puede tener máximo 50 caracteres")
    private String descripcion;

    @DecimalMin(value = "0.0", inclusive = false, message = "El precio debe ser un número positivo")
    private Double precio;

    private String codigo;

    @Min(value = 0, message = "El stock no puede ser negativo")
    private Integer stock = 100;

    private String state;
}
