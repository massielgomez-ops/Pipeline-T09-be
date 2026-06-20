package ap2.PierreAlexisConca.service.impl;

import ap2.PierreAlexisConca.model.Cliente;
import ap2.PierreAlexisConca.repository.ClienteRepository;
import ap2.PierreAlexisConca.service.ClienteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Objects;
import java.util.Optional;

@Service
public class ClienteServiceImpl implements ClienteService {
    private final ClienteRepository clienteRepository;

    @Autowired
    public ClienteServiceImpl(ClienteRepository clienteRepository) {
        this.clienteRepository = clienteRepository;
    }

    @Override
    public List<Cliente> findAll() {
        return clienteRepository.findAll();
    }

    @Override
    public List<Cliente> findByState(String state) {
        return clienteRepository.findByState(state);
    }

    @Override
    public Optional<Cliente> findById(Long id) {
        return clienteRepository.findById(Objects.requireNonNull(id, "id no puede ser null"));
    }

    @Override
    public Cliente save(Cliente cliente) {
        if (cliente.getApellido() == null || cliente.getApellido().isBlank()) {
            cliente.setApellido(cliente.getNombre());
        }
        if (cliente.getState() == null || cliente.getState().isBlank()) {
            cliente.setState("A");
        }
        return clienteRepository.save(cliente);
    }

    @Override
    public Cliente update(Cliente cliente) {
        Long clienteId = Objects.requireNonNull(cliente.getId(), "cliente.id no puede ser null");
        Cliente existing = clienteRepository.findById(clienteId)
                .orElseThrow(() -> new RuntimeException("Cliente not found"));

        if (cliente.getApellido() == null || cliente.getApellido().isBlank()) {
            cliente.setApellido(existing.getApellido());
        }
        if (cliente.getState() == null || cliente.getState().isBlank()) {
            cliente.setState(existing.getState());
        }
        return clienteRepository.save(cliente);
    }

    @Override
    public Cliente delete(Long id) {
        Cliente cliente = clienteRepository.findById(Objects.requireNonNull(id, "id no puede ser null"))
                .orElseThrow(() -> new RuntimeException("Cliente not found"));

        cliente.setState("I");
        return clienteRepository.save(cliente);
    }

    @Override
    public Cliente restore(Long id) {
        Cliente cliente = clienteRepository.findById(Objects.requireNonNull(id, "id no puede ser null"))
                .orElseThrow(() -> new RuntimeException("Cliente not found"));

        cliente.setState("A");
        return clienteRepository.save(cliente);
    }
}
