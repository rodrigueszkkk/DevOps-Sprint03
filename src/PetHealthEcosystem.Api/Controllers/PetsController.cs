using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using PetHealthEcosystem.Api.Application.Interfaces;
using PetHealthEcosystem.Api.Models;

namespace PetHealthEcosystem.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PetsController : ControllerBase
    {
        private readonly IPetService _petService;
        private readonly ILogger<PetsController> _logger;

        public PetsController(IPetService petService, ILogger<PetsController> logger)
        {
            _petService = petService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var pets = await _petService.GetAllAsync();
            return Ok(pets);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var pet = await _petService.GetByIdAsync(id);
            if (pet == null) return NotFound();
            return Ok(pet);
        }

        [HttpGet("breed/{breed}")]
        public async Task<IActionResult> GetByBreed(string breed)
        {
            var pets = await _petService.GetByBreedAsync(breed);
            if (!pets.Any()) return NotFound("Nenhum pet dessa raça encontrado.");
            return Ok(pets);
        }

        [HttpGet("post-op/{needsCare}")]
        public async Task<IActionResult> GetByPostOpCare(bool needsCare)
        {
            var pets = await _petService.GetByPostOpCareAsync(needsCare);
            return Ok(pets);
        }

        [HttpGet("tutor/{tutorName}")]
        public async Task<IActionResult> GetByTutor(string tutorName)
        {
            var pets = await _petService.GetByTutorAsync(tutorName);
            if (!pets.Any()) return NotFound("Tutor não encontrado.");
            return Ok(pets);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Pet pet)
        {
            if (pet == null)
                return BadRequest("Dados inválidos.");

            var (success, error, created) = await _petService.CreateAsync(pet);
            if (!success) return BadRequest(error);

            return CreatedAtAction(nameof(GetById), new { id = created!.Id }, created);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] Pet petAtualizado)
        {
            var (success, error) = await _petService.UpdateAsync(id, petAtualizado);
            if (!success)
            {
                if (error == "Pet não encontrado.") return NotFound(error);
                return BadRequest(error);
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var deleted = await _petService.DeleteAsync(id);
            if (!deleted) return NotFound();
            return NoContent();
        }
    }
}
