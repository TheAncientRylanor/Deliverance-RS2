using Deliverance.Model.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class ExecutionCommand
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.None)]
    public ExecutionCommandEnum Id { get; set; }

    [Required]
    [MaxLength(50)]
    public string Name { get; set; } = string.Empty;
}
