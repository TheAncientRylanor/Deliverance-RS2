using Deliverance.Model.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Deliverance.Services.Database;

public class Role
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public RoleEnum Id { get; set; }

    public string? RoleName { get; set; }

    public ICollection<User> Users { get; set; } = new List<User>();
}