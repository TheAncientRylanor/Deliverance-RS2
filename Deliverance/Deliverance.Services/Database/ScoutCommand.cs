using Deliverance.Model.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Deliverance.Services.Database;

public class ScoutCommand
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required]
    public int ScoutId { get; set; }

    [Required]
    public ExecutionCommandEnum ExecutionCommandId { get; set; }

    [Required]
    [MaxLength(4000)]
    public string CommandText { get; set; } = string.Empty;

    [Required]
    public ScoutCommandStatusEnum Status { get; set; } = ScoutCommandStatusEnum.Pending;

    public string? Output { get; set; }

    public int? ExitCode { get; set; }

    public Guid? CreatedByUserUUID { get; set; }

    [Required]
    public DateTime CreatedAt { get; set; }

    public DateTime? CompletedAt { get; set; }

    [ForeignKey("ScoutId")]
    public Scout? Scout { get; set; }

    [ForeignKey("ExecutionCommandId")]
    public ExecutionCommand? ExecutionCommand { get; set; }

    [ForeignKey("CreatedByUserUUID")]
    public User? CreatedByUser { get; set; }
}
