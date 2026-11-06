using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class Scout
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required]
    public DateTime? CreatedAt { get; set; }
    [Required]
    public int DeviceId { get; set; }

    // Set by an admin. A disabled scout keeps its device, logs and secret,
    // but gets no access tokens until it is enabled again.
    public bool IsDisabled { get; set; }

    // Navigation Properties
    [ForeignKey("DeviceId")]
    public Device? Device { get; set; }

    public ICollection<DeviceLog> DeviceLogs { get; set; } = new List<DeviceLog>();
    public ICollection<ScoutCommand> Commands { get; set; } = new List<ScoutCommand>();
}