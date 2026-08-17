using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Deliverance.Services.Database
{
    public class RefreshTokens
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required]
        [MaxLength(500)]
        public string Token { get; set; } = string.Empty;

        public DateTime ExpiresAt { get; set; }

        public Guid UserUUID { get; set; }
        [ForeignKey("UserUUID")]
        public User User { get; set; } = null!;
    }
}
