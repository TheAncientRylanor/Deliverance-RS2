using Deliverance.Model.Enums;
using Microsoft.EntityFrameworkCore;
namespace Deliverance.Services.Database
{
    public partial class DeliveranceDbContext : DbContext
    {

        private void CreateSeed(ModelBuilder modelBuilder)
        {
            SeedRoles(modelBuilder);
            SeedUsers(modelBuilder);
            SeedOccurrences(modelBuilder);
            SeedExecutionCommands(modelBuilder);
        }
        private void SeedRoles(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Role>().HasData(
                new
                {
                    Id = RoleEnum.User,
                    RoleName = "User",
                },
                new
                {
                    Id = RoleEnum.Admin,
                    RoleName = "Admin"
                },
                 new
                 {
                     Id = RoleEnum.Scout,
                     RoleName = "Scout"
                 }
                );
        }
        private void SeedUsers(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>().HasData(
                new
                {
                    UUID = Guid.Parse("01a0052b-e3cb-705b-8a0c-ddabfee50ed7"),
                    RoleId = RoleEnum.User,
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

                    UUID = Guid.Parse("01a0052b-e4b5-766a-b7c6-d601dbfaef87"),
                    RoleId = RoleEnum.Admin,
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
        private void SeedOccurrences(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Occurrence>().HasData(
                new
                {
                    Id = 1,
                    Question = "Have you encountered this problem before?",
                },
                new
                {
                    Id = 2,
                    Question = "Have you restarted the device?",
                },
                new
                {
                    Id = 3,
                    Question = "Is the device properly connected to power?",
                },
                new
                {
                    Id = 4,
                    Question = "Is the device connected to the network?",
                },
                new
                {
                    Id = 5,
                    Question = "Has anything changed recently (updates, settings, cables)?",
                }
                );
        }
        private void SeedExecutionCommands(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<ExecutionCommand>().HasData(
                new
                {
                    Id = ExecutionCommandEnum.CMD,
                    Name = "CMD",
                },
                new
                {
                    Id = ExecutionCommandEnum.PowerShell,
                    Name = "PowerShell",
                }
                );
        }
    }
}
