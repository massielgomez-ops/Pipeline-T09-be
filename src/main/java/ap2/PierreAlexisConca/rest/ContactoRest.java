package ap2.PierreAlexisConca.rest;

import ap2.PierreAlexisConca.model.Contacto;
import ap2.PierreAlexisConca.service.ContactoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/contactos")
public class ContactoRest {
    private final ContactoService contactoService;

    @Autowired
    public ContactoRest(ContactoService contactoService) {
        this.contactoService = contactoService;
    }

    @GetMapping
    public List<Contacto> getAllContactos() {
        return contactoService.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Contacto> getContactoById(@PathVariable Long id) {
        Optional<Contacto> contacto = contactoService.findById(id);
        return contacto.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping
    public Contacto createContacto(@RequestBody Contacto contacto) {
        return contactoService.save(contacto);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Contacto> updateContacto(@PathVariable Long id, @RequestBody Contacto contacto) {
        if (!contactoService.findById(id).isPresent()) {
            return ResponseEntity.notFound().build();
        }
        contacto.setId(id);
        return ResponseEntity.ok(contactoService.update(contacto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteContacto(@PathVariable Long id) {
        if (!contactoService.findById(id).isPresent()) {
            return ResponseEntity.notFound().build();
        }
        contactoService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
