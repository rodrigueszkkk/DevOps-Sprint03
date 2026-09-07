using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using PetHealthEcosystem.Api.Application.Interfaces;
using PetHealthEcosystem.Api.Models;

namespace PetHealthEcosystem.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class MedicalRecordsController : ControllerBase
    {
        private readonly IMedicalRecordService _medicalRecordService;
        private readonly ILogger<MedicalRecordsController> _logger;

        public MedicalRecordsController(IMedicalRecordService medicalRecordService, ILogger<MedicalRecordsController> logger)
        {
            _medicalRecordService = medicalRecordService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var records = await _medicalRecordService.GetAllAsync();
            return Ok(records);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var record = await _medicalRecordService.GetByIdAsync(id);
            if (record == null) return NotFound("Registro médico não encontrado.");
            return Ok(record);
        }

        [HttpGet("pet/{petId}")]
        public async Task<IActionResult> GetByPetId(int petId)
        {
            var records = await _medicalRecordService.GetByPetIdAsync(petId);
            return Ok(records);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] MedicalRecord record)
        {
            if (record == null)
                return BadRequest("Dados inválidos.");

            var (success, error, created) = await _medicalRecordService.CreateAsync(record);
            if (!success)
                return BadRequest(error);

            return CreatedAtAction(nameof(GetById), new { id = created!.Id }, created);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] MedicalRecord record)
        {
            var (success, error) = await _medicalRecordService.UpdateAsync(id, record);
            if (!success)
            {
                if (error == "Registro médico não encontrado.") return NotFound(error);
                return BadRequest(error);
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var deleted = await _medicalRecordService.DeleteAsync(id);
            if (!deleted) return NotFound("Registro médico não encontrado.");
            return NoContent();
        }
    }
}
