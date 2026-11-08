using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Deliverance.Services.Database;


public class Device
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required]
    public string Name { get; set; } = string.Empty;

    [Required]
    public string OfficeName { get; set; } = string.Empty;
    [Required]
    public int OfficeId { get; set; }

    public double PositionX { get; set; }
    public double PositionY { get; set; }
    public string IconName { get; set; } = string.Empty;

    public string? Type { get; set; }

    public string? IpAddress { get; set; }

    public string? MacAddress { get; set; }

    public string? SubnetMask { get; set; }
    public string? VlanID { get; set; }
    public string? OS { get; set; }
    public DateTime? LastOsUpdate { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public string? Manufacturer { get; set; }

    [ForeignKey("OfficeId")]
    public Office? Office { get; set; }


    public Scout? Scout { get; set; }
    public ICollection<DeviceReport> DeviceReports { get; set; } = new List<DeviceReport>();
}