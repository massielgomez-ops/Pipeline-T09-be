package ap2.PierreAlexisConca.dto.producto;

import lombok.Data;

@Data
public class ProductoResponse {
    private Long id;
    private String nombre;
    private String descripcion;
    private Double precio;
    private String codigo;
    private Integer stock;
    private String state;
}
