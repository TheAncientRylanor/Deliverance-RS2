using Deliverance.Model.Enums;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

// A CMD or PowerShell command an admin sent to a scout, and its result.
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

    // stdout and stderr together; nvarchar(max), since command output has no natural limit.
    public string? Output { get; set; }

    // Null when the process never ran to the end (Failed or TimedOut).
    public int? ExitCode { get; set; }

    // Kept nullable so the command history stays when the admin's account is deleted.
    public Guid? CreatedByUserUUID { get; set; }

    [Required]
    public DateTime CreatedAt { get; set; }

    public DateTime? CompletedAt { get; set; }

    // Navigation
    [ForeignKey("ScoutId")]
    public Scout? Scout { get; set; }

    [ForeignKey("ExecutionCommandId")]
    public ExecutionCommand? ExecutionCommand { get; set; }

    [ForeignKey("CreatedByUserUUID")]
    public User? CreatedByUser { get; set; }
}
