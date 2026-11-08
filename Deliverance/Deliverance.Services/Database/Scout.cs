using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Deliverance.Services.Database;

public class Scout
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required]
    public DateTime? CreatedAt { get; set; }
    [Required]
    public int DeviceId { get; set; }

    public bool IsDisabled { get; set; }

    [ForeignKey("DeviceId")]
    public Device? Device { get; set; }

    public ICollection<DeviceLog> DeviceLogs { get; set; } = new List<DeviceLog>();
    public ICollection<ScoutCommand> Commands { get; set; } = new List<ScoutCommand>();
}