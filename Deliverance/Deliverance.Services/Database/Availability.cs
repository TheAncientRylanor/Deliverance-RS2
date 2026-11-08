using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Deliverance.Services.Database;

public class Availability
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }
    [Required]
    public string Day { get; set; } = string.Empty;

    public TimeOnly? FromTime { get; set; }

    public TimeOnly? ToTime { get; set; }

    public TimeOnly? Pause { get; set; }

    [Required]
    public int ContactId { get; set; }

    [ForeignKey("ContactId")]
    public Contact? Contact { get; set; }
    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }
}