package ap2.PierreAlexisConca.service.impl;

import ap2.PierreAlexisConca.model.Contacto;
import ap2.PierreAlexisConca.repository.ContactoRepository;
import ap2.PierreAlexisConca.service.ContactoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Objects;
import java.util.Optional;

@Service
public class ContactoServiceImpl implements ContactoService {
    private final ContactoRepository contactoRepository;

    @Autowired
    public ContactoServiceImpl(ContactoRepository contactoRepository) {
        this.contactoRepository = contactoRepository;
    }

    @Override
    public List<Contacto> findAll() {
        return contactoRepository.findAll();
    }

    @Override
    public Optional<Contacto> findById(Long id) {
        return contactoRepository.findById(Objects.requireNonNull(id, "id no puede ser null"));
    }

    @Override
    public Contacto save(Contacto contacto) {
        return contactoRepository.save(contacto);
    }

    @Override
    public Contacto update(Contacto contacto) {
        return contactoRepository.save(contacto);
    }

    @Override
    public void delete(Long id) {
        contactoRepository.deleteById(Objects.requireNonNull(id, "id no puede ser null"));
    }
}
