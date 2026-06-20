package ap2.PierreAlexisConca.service;

import ap2.PierreAlexisConca.model.Contacto;
import java.util.List;
import java.util.Optional;

public interface ContactoService {
    List<Contacto> findAll();
    Optional<Contacto> findById(Long id);
    Contacto save(Contacto contacto);
    Contacto update(Contacto contacto);
    void delete(Long id);
}
