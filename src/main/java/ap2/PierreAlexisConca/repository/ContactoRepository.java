package ap2.PierreAlexisConca.repository;

import ap2.PierreAlexisConca.model.Contacto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ContactoRepository extends JpaRepository<Contacto, Long> {
    // Métodos personalizados si los necesitas
}
