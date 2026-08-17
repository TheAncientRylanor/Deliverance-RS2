using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Deliverance.Services.Database
{
    public partial class DeliveranceDbContext : DbContext
    {
        private void CreateSeed(ModelBuilder modelBuilder)
        {
            SeedRoles(modelBuilder);
            SeedUsers(modelBuilder);
        }
        private void SeedRoles(ModelBuilder modelBuilder) {
            modelBuilder.Entity<Role>().HasData(
                new
                {
                    Id = 1,
                    RoleName = "User",
                },
                new
                {
                    Id = 2,
                    RoleName = "Admin"
                },
                 new
                 {
                     Id = 3,
                     RoleName = "Scout"
                 }
                );
        }
         private void SeedUsers(ModelBuilder modelBuilder) {
            modelBuilder.Entity<User>().HasData(
                new
                {
                    UUID =  Guid.Parse("01a0052b-e3cb-705b-8a0c-ddabfee50ed7"),
                    RoleId = 1,
                    Username = "Abdi",
                    FirstName = "Abdulah",
                    LastName = "Gavran",
                    Email = "abdi@gmail.com",
                    PasswordHash = "RAIXbMb2/r260dX5FUyrdjWQD/Y=",
                    PasswordSalt = "MaguMBrUKFKhR2pJTHh6hQ==",
                    CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                },
                new
                {
                 
                    UUID =  Guid.Parse("01a0052b-e4b5-766a-b7c6-d601dbfaef87"),
                    RoleId = 2,
                    Username = "Admin",
                    FirstName = "Admin",
                    LastName = "Admin",
                    Email = "admin@gmail.com",
                    PasswordHash = "FtGuYztT2jlsiedsnAooX7e85Uk=",
                    PasswordSalt = "3+dabjBBHJqaMD7TU5/z9w==",
                    CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                }
                );
        }
    }
}
